# Auto-generated client for AWSKendraFrontendService v2019-02-03
# Source: https://api.apis.guru/v2/specs/amazonaws.com/kendra/2019-02-03/openapi.json
# Auth: --token flag or $env.AWSKENDRAFRONTENDSERVICE_TOKEN

const CLIENT = {
  base_url: "http://kendra.us-east-1.amazonaws.com"
  token_env_var: "AWSKENDRAFRONTENDSERVICE_TOKEN"
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

def base-url-completer [] { ["http://kendra.us-east-1.amazonaws.com" "http://kendra.us-east-2.amazonaws.com" "http://kendra.us-west-1.amazonaws.com" "http://kendra.us-west-2.amazonaws.com" "http://kendra.us-gov-west-1.amazonaws.com" "http://kendra.us-gov-east-1.amazonaws.com" "http://kendra.ca-central-1.amazonaws.com" "http://kendra.eu-north-1.amazonaws.com" "http://kendra.eu-west-1.amazonaws.com" "http://kendra.eu-west-2.amazonaws.com" "http://kendra.eu-west-3.amazonaws.com" "http://kendra.eu-central-1.amazonaws.com" "http://kendra.eu-south-1.amazonaws.com" "http://kendra.af-south-1.amazonaws.com" "http://kendra.ap-northeast-1.amazonaws.com" "http://kendra.ap-northeast-2.amazonaws.com" "http://kendra.ap-northeast-3.amazonaws.com" "http://kendra.ap-southeast-1.amazonaws.com" "http://kendra.ap-southeast-2.amazonaws.com" "http://kendra.ap-east-1.amazonaws.com" "http://kendra.ap-south-1.amazonaws.com" "http://kendra.sa-east-1.amazonaws.com" "http://kendra.me-south-1.amazonaws.com" "https://kendra.us-east-1.amazonaws.com" "https://kendra.us-east-2.amazonaws.com" "https://kendra.us-west-1.amazonaws.com" "https://kendra.us-west-2.amazonaws.com" "https://kendra.us-gov-west-1.amazonaws.com" "https://kendra.us-gov-east-1.amazonaws.com" "https://kendra.ca-central-1.amazonaws.com" "https://kendra.eu-north-1.amazonaws.com" "https://kendra.eu-west-1.amazonaws.com" "https://kendra.eu-west-2.amazonaws.com" "https://kendra.eu-west-3.amazonaws.com" "https://kendra.eu-central-1.amazonaws.com" "https://kendra.eu-south-1.amazonaws.com" "https://kendra.af-south-1.amazonaws.com" "https://kendra.ap-northeast-1.amazonaws.com" "https://kendra.ap-northeast-2.amazonaws.com" "https://kendra.ap-northeast-3.amazonaws.com" "https://kendra.ap-southeast-1.amazonaws.com" "https://kendra.ap-southeast-2.amazonaws.com" "https://kendra.ap-east-1.amazonaws.com" "https://kendra.ap-south-1.amazonaws.com" "https://kendra.sa-east-1.amazonaws.com" "https://kendra.me-south-1.amazonaws.com" "http://kendra.cn-north-1.amazonaws.com.cn" "http://kendra.cn-northwest-1.amazonaws.com.cn" "https://kendra.cn-north-1.amazonaws.com.cn" "https://kendra.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWSKendraFrontendService.AssociateEntitiesToExperience"] }
def x-amz-target-completer-1 [] { ["AWSKendraFrontendService.AssociatePersonasToEntities"] }
def x-amz-target-completer-2 [] { ["AWSKendraFrontendService.BatchDeleteDocument"] }
def x-amz-target-completer-3 [] { ["AWSKendraFrontendService.BatchDeleteFeaturedResultsSet"] }
def x-amz-target-completer-4 [] { ["AWSKendraFrontendService.BatchGetDocumentStatus"] }
def x-amz-target-completer-5 [] { ["AWSKendraFrontendService.BatchPutDocument"] }
def x-amz-target-completer-6 [] { ["AWSKendraFrontendService.ClearQuerySuggestions"] }
def x-amz-target-completer-7 [] { ["AWSKendraFrontendService.CreateAccessControlConfiguration"] }
def type-completer [] { ["ALFRESCO" "BOX" "CONFLUENCE" "CUSTOM" "DATABASE" "FSX" "GITHUB" "GOOGLEDRIVE" "JIRA" "ONEDRIVE" "QUIP" "S3" "SALESFORCE" "SERVICENOW" "SHAREPOINT" "SLACK" "TEMPLATE" "WEBCRAWLER" "WORKDOCS"] }
def x-amz-target-completer-8 [] { ["AWSKendraFrontendService.CreateDataSource"] }
def x-amz-target-completer-9 [] { ["AWSKendraFrontendService.CreateExperience"] }
def file-format-completer [] { ["CSV" "CSV_WITH_HEADER" "JSON"] }
def x-amz-target-completer-10 [] { ["AWSKendraFrontendService.CreateFaq"] }
def status-completer [] { ["ACTIVE" "INACTIVE"] }
def x-amz-target-completer-11 [] { ["AWSKendraFrontendService.CreateFeaturedResultsSet"] }
def edition-completer [] { ["DEVELOPER_EDITION" "ENTERPRISE_EDITION"] }
def user-context-policy-completer [] { ["ATTRIBUTE_FILTER" "USER_TOKEN"] }
def x-amz-target-completer-12 [] { ["AWSKendraFrontendService.CreateIndex"] }
def x-amz-target-completer-13 [] { ["AWSKendraFrontendService.CreateQuerySuggestionsBlockList"] }
def x-amz-target-completer-14 [] { ["AWSKendraFrontendService.CreateThesaurus"] }
def x-amz-target-completer-15 [] { ["AWSKendraFrontendService.DeleteAccessControlConfiguration"] }
def x-amz-target-completer-16 [] { ["AWSKendraFrontendService.DeleteDataSource"] }
def x-amz-target-completer-17 [] { ["AWSKendraFrontendService.DeleteExperience"] }
def x-amz-target-completer-18 [] { ["AWSKendraFrontendService.DeleteFaq"] }
def x-amz-target-completer-19 [] { ["AWSKendraFrontendService.DeleteIndex"] }
def x-amz-target-completer-20 [] { ["AWSKendraFrontendService.DeletePrincipalMapping"] }
def x-amz-target-completer-21 [] { ["AWSKendraFrontendService.DeleteQuerySuggestionsBlockList"] }
def x-amz-target-completer-22 [] { ["AWSKendraFrontendService.DeleteThesaurus"] }
def x-amz-target-completer-23 [] { ["AWSKendraFrontendService.DescribeAccessControlConfiguration"] }
def x-amz-target-completer-24 [] { ["AWSKendraFrontendService.DescribeDataSource"] }
def x-amz-target-completer-25 [] { ["AWSKendraFrontendService.DescribeExperience"] }
def x-amz-target-completer-26 [] { ["AWSKendraFrontendService.DescribeFaq"] }
def x-amz-target-completer-27 [] { ["AWSKendraFrontendService.DescribeFeaturedResultsSet"] }
def x-amz-target-completer-28 [] { ["AWSKendraFrontendService.DescribeIndex"] }
def x-amz-target-completer-29 [] { ["AWSKendraFrontendService.DescribePrincipalMapping"] }
def x-amz-target-completer-30 [] { ["AWSKendraFrontendService.DescribeQuerySuggestionsBlockList"] }
def x-amz-target-completer-31 [] { ["AWSKendraFrontendService.DescribeQuerySuggestionsConfig"] }
def x-amz-target-completer-32 [] { ["AWSKendraFrontendService.DescribeThesaurus"] }
def x-amz-target-completer-33 [] { ["AWSKendraFrontendService.DisassociateEntitiesFromExperience"] }
def x-amz-target-completer-34 [] { ["AWSKendraFrontendService.DisassociatePersonasFromEntities"] }
def x-amz-target-completer-35 [] { ["AWSKendraFrontendService.GetQuerySuggestions"] }
def interval-completer [] { ["ONE_MONTH_AGO" "ONE_WEEK_AGO" "THIS_MONTH" "THIS_WEEK" "TWO_MONTHS_AGO" "TWO_WEEKS_AGO"] }
def metric-type-completer [] { ["AGG_QUERY_DOC_METRICS" "DOCS_BY_CLICK_COUNT" "QUERIES_BY_COUNT" "QUERIES_BY_ZERO_CLICK_RATE" "QUERIES_BY_ZERO_RESULT_RATE" "TREND_QUERY_DOC_METRICS"] }
def x-amz-target-completer-36 [] { ["AWSKendraFrontendService.GetSnapshots"] }
def x-amz-target-completer-37 [] { ["AWSKendraFrontendService.ListAccessControlConfigurations"] }
def status-filter-completer [] { ["ABORTED" "FAILED" "INCOMPLETE" "STOPPING" "SUCCEEDED" "SYNCING" "SYNCING_INDEXING"] }
def x-amz-target-completer-38 [] { ["AWSKendraFrontendService.ListDataSourceSyncJobs"] }
def x-amz-target-completer-39 [] { ["AWSKendraFrontendService.ListDataSources"] }
def x-amz-target-completer-40 [] { ["AWSKendraFrontendService.ListEntityPersonas"] }
def x-amz-target-completer-41 [] { ["AWSKendraFrontendService.ListExperienceEntities"] }
def x-amz-target-completer-42 [] { ["AWSKendraFrontendService.ListExperiences"] }
def x-amz-target-completer-43 [] { ["AWSKendraFrontendService.ListFaqs"] }
def x-amz-target-completer-44 [] { ["AWSKendraFrontendService.ListFeaturedResultsSets"] }
def x-amz-target-completer-45 [] { ["AWSKendraFrontendService.ListGroupsOlderThanOrderingId"] }
def x-amz-target-completer-46 [] { ["AWSKendraFrontendService.ListIndices"] }
def x-amz-target-completer-47 [] { ["AWSKendraFrontendService.ListQuerySuggestionsBlockLists"] }
def x-amz-target-completer-48 [] { ["AWSKendraFrontendService.ListTagsForResource"] }
def x-amz-target-completer-49 [] { ["AWSKendraFrontendService.ListThesauri"] }
def x-amz-target-completer-50 [] { ["AWSKendraFrontendService.PutPrincipalMapping"] }
def query-result-type-filter-completer [] { ["ANSWER" "DOCUMENT" "QUESTION_ANSWER"] }
def x-amz-target-completer-51 [] { ["AWSKendraFrontendService.Query"] }
def x-amz-target-completer-52 [] { ["AWSKendraFrontendService.StartDataSourceSyncJob"] }
def x-amz-target-completer-53 [] { ["AWSKendraFrontendService.StopDataSourceSyncJob"] }
def x-amz-target-completer-54 [] { ["AWSKendraFrontendService.SubmitFeedback"] }
def x-amz-target-completer-55 [] { ["AWSKendraFrontendService.TagResource"] }
def x-amz-target-completer-56 [] { ["AWSKendraFrontendService.UntagResource"] }
def x-amz-target-completer-57 [] { ["AWSKendraFrontendService.UpdateAccessControlConfiguration"] }
def x-amz-target-completer-58 [] { ["AWSKendraFrontendService.UpdateDataSource"] }
def x-amz-target-completer-59 [] { ["AWSKendraFrontendService.UpdateExperience"] }
def x-amz-target-completer-60 [] { ["AWSKendraFrontendService.UpdateFeaturedResultsSet"] }
def x-amz-target-completer-61 [] { ["AWSKendraFrontendService.UpdateIndex"] }
def x-amz-target-completer-62 [] { ["AWSKendraFrontendService.UpdateQuerySuggestionsBlockList"] }
def mode-completer [] { ["ENABLED" "LEARN_ONLY"] }
def x-amz-target-completer-63 [] { ["AWSKendraFrontendService.UpdateQuerySuggestionsConfig"] }
def x-amz-target-completer-64 [] { ["AWSKendraFrontendService.UpdateThesaurus"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    associate-entities-to-experience: "record<FailedEntityList: table<EntityId: string, ErrorMessage: string>>"
    associate-personas-to-entities: "record<FailedEntityList: table<EntityId: string, ErrorMessage: string>>"
    batch-delete-document: "record<FailedDocuments: table<Id: string, ErrorCode: string, ErrorMessage: string>>"
    batch-delete-featured-results-set: "record<Errors: table<Id: string, ErrorCode: string, ErrorMessage: string>>"
    batch-get-document-status: "record<Errors: table<DocumentId: string, ErrorCode: string, ErrorMessage: string>, DocumentStatusList: table<DocumentId: string, DocumentStatus: string, FailureCode: string, FailureReason: string>>"
    batch-put-document: "record<FailedDocuments: table<Id: string, ErrorCode: string, ErrorMessage: string>>"
    create-access-control-configuration: "record<Id: string>"
    create-data-source: "record<Id: string>"
    create-experience: "record<Id: string>"
    create-faq: "record<Id: string>"
    create-featured-results-set: "record<FeaturedResultsSet: record<FeaturedResultsSetId: string, FeaturedResultsSetName: string, Description: string, Status: string, QueryTexts: list<string>, FeaturedDocuments: list<record>, LastUpdatedTimestamp: int, CreationTimestamp: int>>"
    create-index: "record<Id: string>"
    create-query-suggestions-block-list: "record<Id: string>"
    create-thesaurus: "record<Id: string>"
    delete-access-control-configuration: "record"
    delete-experience: "record"
    describe-access-control-configuration: "record<Name: string, Description: string, ErrorMessage: string, AccessControlList: table<Name: string, Type: string, Access: string, DataSourceId: string>, HierarchicalAccessControlList: table<PrincipalList: list>>"
    describe-data-source: "record<Id: string, IndexId: string, Name: string, Type: string, Configuration: record<S3Configuration: record<BucketName: string, InclusionPrefixes: list, InclusionPatterns: list, ExclusionPatterns: list, DocumentsMetadataConfiguration: record, AccessControlListConfiguration: record>, SharePointConfiguration: record<SharePointVersion: string, Urls: list, SecretArn: string, CrawlAttachments: bool, UseChangeLog: bool, InclusionPatterns: list, ExclusionPatterns: list, VpcConfiguration: record, FieldMappings: list, DocumentTitleFieldName: string, DisableLocalGroups: bool, SslCertificateS3Path: record, AuthenticationType: string, ProxyConfiguration: record>, DatabaseConfiguration: record<DatabaseEngineType: string, ConnectionConfiguration: record, VpcConfiguration: record, ColumnConfiguration: record, AclConfiguration: record, SqlConfiguration: record>, SalesforceConfiguration: record<ServerUrl: string, SecretArn: string, StandardObjectConfigurations: list, KnowledgeArticleConfiguration: record, ChatterFeedConfiguration: record, CrawlAttachments: bool, StandardObjectAttachmentConfiguration: record, IncludeAttachmentFilePatterns: list, ExcludeAttachmentFilePatterns: list>, OneDriveConfiguration: record<TenantDomain: string, SecretArn: string, OneDriveUsers: record, InclusionPatterns: list, ExclusionPatterns: list, FieldMappings: list, DisableLocalGroups: bool>, ServiceNowConfiguration: record<HostUrl: string, SecretArn: string, ServiceNowBuildVersion: string, KnowledgeArticleConfiguration: record, ServiceCatalogConfiguration: record, AuthenticationType: string>, ConfluenceConfiguration: record<ServerUrl: string, SecretArn: string, Version: string, SpaceConfiguration: record, PageConfiguration: record, BlogConfiguration: record, AttachmentConfiguration: record, VpcConfiguration: record, InclusionPatterns: list, ExclusionPatterns: list, ProxyConfiguration: record, AuthenticationType: string>, GoogleDriveConfiguration: record<SecretArn: string, InclusionPatterns: list, ExclusionPatterns: list, FieldMappings: list, ExcludeMimeTypes: list, ExcludeUserAccounts: list, ExcludeSharedDrives: list>, WebCrawlerConfiguration: record<Urls: record, CrawlDepth: int, MaxLinksPerPage: int, MaxContentSizePerPageInMegaBytes: float, MaxUrlsPerMinuteCrawlRate: int, UrlInclusionPatterns: list, UrlExclusionPatterns: list, ProxyConfiguration: record, AuthenticationConfiguration: record>, WorkDocsConfiguration: record<OrganizationId: string, CrawlComments: bool, UseChangeLog: bool, InclusionPatterns: list, ExclusionPatterns: list, FieldMappings: list>, FsxConfiguration: record<FileSystemId: string, FileSystemType: string, VpcConfiguration: record, SecretArn: string, InclusionPatterns: list, ExclusionPatterns: list, FieldMappings: list>, SlackConfiguration: record<TeamId: string, SecretArn: string, VpcConfiguration: record, SlackEntityList: list, UseChangeLog: bool, CrawlBotMessage: bool, ExcludeArchived: bool, SinceCrawlDate: string, LookBackPeriod: int, PrivateChannelFilter: list, PublicChannelFilter: list, InclusionPatterns: list, ExclusionPatterns: list, FieldMappings: list>, BoxConfiguration: record<EnterpriseId: string, SecretArn: string, UseChangeLog: bool, CrawlComments: bool, CrawlTasks: bool, CrawlWebLinks: bool, FileFieldMappings: list, TaskFieldMappings: list, CommentFieldMappings: list, WebLinkFieldMappings: list, InclusionPatterns: list, ExclusionPatterns: list, VpcConfiguration: record>, QuipConfiguration: record<Domain: string, SecretArn: string, CrawlFileComments: bool, CrawlChatRooms: bool, CrawlAttachments: bool, FolderIds: list, ThreadFieldMappings: list, MessageFieldMappings: list, AttachmentFieldMappings: list, InclusionPatterns: list, ExclusionPatterns: list, VpcConfiguration: record>, JiraConfiguration: record<JiraAccountUrl: string, SecretArn: string, UseChangeLog: bool, Project: list, IssueType: list, Status: list, IssueSubEntityFilter: list, AttachmentFieldMappings: list, CommentFieldMappings: list, IssueFieldMappings: list, ProjectFieldMappings: list, WorkLogFieldMappings: list, InclusionPatterns: list, ExclusionPatterns: list, VpcConfiguration: record>, GitHubConfiguration: record<SaaSConfiguration: record, OnPremiseConfiguration: record, Type: string, SecretArn: string, UseChangeLog: bool, GitHubDocumentCrawlProperties: record, RepositoryFilter: list, InclusionFolderNamePatterns: list, InclusionFileTypePatterns: list, InclusionFileNamePatterns: list, ExclusionFolderNamePatterns: list, ExclusionFileTypePatterns: list, ExclusionFileNamePatterns: list, VpcConfiguration: record, GitHubRepositoryConfigurationFieldMappings: list, GitHubCommitConfigurationFieldMappings: list, GitHubIssueDocumentConfigurationFieldMappings: list, GitHubIssueCommentConfigurationFieldMappings: list, GitHubIssueAttachmentConfigurationFieldMappings: list, GitHubPullRequestCommentConfigurationFieldMappings: list, GitHubPullRequestDocumentConfigurationFieldMappings: list, GitHubPullRequestDocumentAttachmentConfigurationFieldMappings: list>, AlfrescoConfiguration: record<SiteUrl: string, SiteId: string, SecretArn: string, SslCertificateS3Path: record, CrawlSystemFolders: bool, CrawlComments: bool, EntityFilter: list, DocumentLibraryFieldMappings: list, BlogFieldMappings: list, WikiFieldMappings: list, InclusionPatterns: list, ExclusionPatterns: list, VpcConfiguration: record>, TemplateConfiguration: record<Template: record>>, VpcConfiguration: record<SubnetIds: list<string>, SecurityGroupIds: list<string>>, CreatedAt: string, UpdatedAt: string, Description: string, Status: string, Schedule: string, RoleArn: string, ErrorMessage: string, LanguageCode: string, CustomDocumentEnrichmentConfiguration: record<InlineConfigurations: list<record>, PreExtractionHookConfiguration: record<InvocationCondition: record, LambdaArn: string, S3Bucket: string>, PostExtractionHookConfiguration: record<InvocationCondition: record, LambdaArn: string, S3Bucket: string>, RoleArn: string>>"
    describe-experience: "record<Id: string, IndexId: string, Name: string, Endpoints: table<EndpointType: string, Endpoint: string>, Configuration: record<ContentSourceConfiguration: record<DataSourceIds: list, FaqIds: list, DirectPutContent: bool>, UserIdentityConfiguration: record<IdentityAttributeName: string>>, CreatedAt: string, UpdatedAt: string, Description: string, Status: string, RoleArn: string, ErrorMessage: string>"
    describe-faq: "record<Id: string, IndexId: string, Name: string, Description: string, CreatedAt: string, UpdatedAt: string, S3Path: record<Bucket: string, Key: string>, Status: string, RoleArn: string, ErrorMessage: string, FileFormat: string, LanguageCode: string>"
    describe-featured-results-set: "record<FeaturedResultsSetId: string, FeaturedResultsSetName: string, Description: string, Status: string, QueryTexts: list<string>, FeaturedDocumentsWithMetadata: table<Id: string, Title: string, URI: string>, FeaturedDocumentsMissing: table<Id: string>, LastUpdatedTimestamp: int, CreationTimestamp: int>"
    describe-index: "record<Name: string, Id: string, Edition: string, RoleArn: string, ServerSideEncryptionConfiguration: record<KmsKeyId: string>, Status: string, Description: string, CreatedAt: string, UpdatedAt: string, DocumentMetadataConfigurations: table<Name: string, Type: string, Relevance: record, Search: record>, IndexStatistics: record<FaqStatistics: record<IndexedQuestionAnswersCount: int>, TextDocumentStatistics: record<IndexedTextDocumentsCount: int, IndexedTextBytes: int>>, ErrorMessage: string, CapacityUnits: record<StorageCapacityUnits: int, QueryCapacityUnits: int>, UserTokenConfigurations: table<JwtTokenTypeConfiguration: record, JsonTokenTypeConfiguration: record>, UserContextPolicy: string, UserGroupResolutionConfiguration: record<UserGroupResolutionMode: string>>"
    describe-principal-mapping: "record<IndexId: string, DataSourceId: string, GroupId: string, GroupOrderingIdSummaries: table<Status: string, LastUpdatedAt: string, ReceivedAt: string, OrderingId: int, FailureReason: string>>"
    describe-query-suggestions-block-list: "record<IndexId: string, Id: string, Name: string, Description: string, Status: string, ErrorMessage: string, CreatedAt: string, UpdatedAt: string, SourceS3Path: record<Bucket: string, Key: string>, ItemCount: int, FileSizeBytes: int, RoleArn: string>"
    describe-query-suggestions-config: "record<Mode: string, Status: string, QueryLogLookBackWindowInDays: int, IncludeQueriesWithoutUserInformation: bool, MinimumNumberOfQueryingUsers: int, MinimumQueryCount: int, LastSuggestionsBuildTime: string, LastClearTime: string, TotalSuggestionsCount: int>"
    describe-thesaurus: "record<Id: string, IndexId: string, Name: string, Description: string, Status: string, ErrorMessage: string, CreatedAt: string, UpdatedAt: string, RoleArn: string, SourceS3Path: record<Bucket: string, Key: string>, FileSizeBytes: int, TermCount: int, SynonymRuleCount: int>"
    disassociate-entities-from-experience: "record<FailedEntityList: table<EntityId: string, ErrorMessage: string>>"
    disassociate-personas-from-entities: "record<FailedEntityList: table<EntityId: string, ErrorMessage: string>>"
    get-query-suggestions: "record<QuerySuggestionsId: string, Suggestions: table<Id: string, Value: record>>"
    get-snapshots: "record<SnapShotTimeFilter: record<StartTime: string, EndTime: string>, SnapshotsDataHeader: list<string>, SnapshotsData: list<list<string>>, NextToken: string>"
    list-access-control-configurations: "record<NextToken: string, AccessControlConfigurations: table<Id: string>>"
    list-data-source-sync-jobs: "record<History: table<ExecutionId: string, StartTime: string, EndTime: string, Status: string, ErrorMessage: string, ErrorCode: string, DataSourceErrorCode: string, Metrics: record>, NextToken: string>"
    list-data-sources: "record<SummaryItems: table<Name: string, Id: string, Type: string, CreatedAt: string, UpdatedAt: string, Status: string, LanguageCode: string>, NextToken: string>"
    list-entity-personas: "record<SummaryItems: table<EntityId: string, Persona: string, CreatedAt: string, UpdatedAt: string>, NextToken: string>"
    list-experience-entities: "record<SummaryItems: table<EntityId: string, EntityType: string, DisplayData: record>, NextToken: string>"
    list-experiences: "record<SummaryItems: table<Name: string, Id: string, CreatedAt: string, Status: string, Endpoints: list>, NextToken: string>"
    list-faqs: "record<NextToken: string, FaqSummaryItems: table<Id: string, Name: string, Status: string, CreatedAt: string, UpdatedAt: string, FileFormat: string, LanguageCode: string>>"
    list-featured-results-sets: "record<FeaturedResultsSetSummaryItems: table<FeaturedResultsSetId: string, FeaturedResultsSetName: string, Status: string, LastUpdatedTimestamp: int, CreationTimestamp: int>, NextToken: string>"
    list-groups-older-than-ordering-id: "record<GroupsSummaries: table<GroupId: string, OrderingId: int>, NextToken: string>"
    list-indices: "record<IndexConfigurationSummaryItems: table<Name: string, Id: string, Edition: string, CreatedAt: string, UpdatedAt: string, Status: string>, NextToken: string>"
    list-query-suggestions-block-lists: "record<BlockListSummaryItems: table<Id: string, Name: string, Status: string, CreatedAt: string, UpdatedAt: string, ItemCount: int>, NextToken: string>"
    list-tags-for-resource: "record<Tags: table<Key: string, Value: string>>"
    list-thesauri: "record<NextToken: string, ThesaurusSummaryItems: table<Id: string, Name: string, Status: string, CreatedAt: string, UpdatedAt: string>>"
    query: "record<QueryId: string, ResultItems: table<Id: string, Type: string, Format: string, AdditionalAttributes: list, DocumentId: string, DocumentTitle: record, DocumentExcerpt: record, DocumentURI: string, DocumentAttributes: list, ScoreAttributes: record, FeedbackToken: string, TableExcerpt: record>, FacetResults: table<DocumentAttributeKey: string, DocumentAttributeValueType: string, DocumentAttributeValueCountPairs: list>, TotalNumberOfResults: int, Warnings: table<Message: string, Code: string>, SpellCorrectedQueries: table<SuggestedQueryText: string, Corrections: list>, FeaturedResultsItems: table<Id: string, Type: string, AdditionalAttributes: list, DocumentId: string, DocumentTitle: record, DocumentExcerpt: record, DocumentURI: string, DocumentAttributes: list, FeedbackToken: string>>"
    start-data-source-sync-job: "record<ExecutionId: string>"
    tag-resource: "record"
    untag-resource: "record"
    update-access-control-configuration: "record"
    update-featured-results-set: "record<FeaturedResultsSet: record<FeaturedResultsSetId: string, FeaturedResultsSetName: string, Description: string, Status: string, QueryTexts: list<string>, FeaturedDocuments: list<record>, LastUpdatedTimestamp: int, CreationTimestamp: int>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["associate-entities-to-experience" "associate-personas-to-entities" "batch-delete-document" "batch-delete-featured-results-set" "batch-get-document-status" "batch-put-document" "clear-query-suggestions" "create-access-control-configuration" "create-data-source" "create-experience" "create-faq" "create-featured-results-set" "create-index" "create-query-suggestions-block-list" "create-thesaurus" "delete-access-control-configuration" "delete-data-source" "delete-experience" "delete-faq" "delete-index" "delete-principal-mapping" "delete-query-suggestions-block-list" "delete-thesaurus" "describe-access-control-configuration" "describe-data-source" "describe-experience" "describe-faq" "describe-featured-results-set" "describe-index" "describe-principal-mapping" "describe-query-suggestions-block-list" "describe-query-suggestions-config" "describe-thesaurus" "disassociate-entities-from-experience" "disassociate-personas-from-entities" "get-query-suggestions" "get-snapshots" "list-access-control-configurations" "list-data-source-sync-jobs" "list-data-sources" "list-entity-personas" "list-experience-entities" "list-experiences" "list-faqs" "list-featured-results-sets" "list-groups-older-than-ordering-id" "list-indices" "list-query-suggestions-block-lists" "list-tags-for-resource" "list-thesauri" "put-principal-mapping" "query" "start-data-source-sync-job" "stop-data-source-sync-job" "submit-feedback" "tag-resource" "untag-resource" "update-access-control-configuration" "update-data-source" "update-experience" "update-featured-results-set" "update-index" "update-query-suggestions-block-list" "update-query-suggestions-config" "update-thesaurus" "commands"] | sort) } | get name | first)
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

# Grants users or groups in your IAM Identity Center identity source access to your Amazon Kendra experience. You can create an Amazon Kendra experience such as a search application. For more information on creating a search application experience, see Building a search experience with no code (https://docs.aws.amazon.com/kendra/latest/dg/deploying-search-experience-no-code.html).
#
# POST /
# Returns: record<FailedEntityList: table<EntityId: string, ErrorMessage: string>>
# operationId: AssociateEntitiesToExperience
export def "associate-entities-to-experience" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of your Amazon Kendra experience.
  index_id: string # The identifier of the index for your Amazon Kendra experience.
  entity_list: list # Lists users or groups in your IAM Identity Center identity source. — item shape: {EntityId: string, EntityType: "USER"|"GROUP"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.AssociateEntitiesToExperience"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: IndexId, var: index_id}, {name: EntityList, var: entity_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, index_id: $index_id, entity_list: $entity_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Defines the specific permissions of users or groups in your IAM Identity Center identity source with access to your Amazon Kendra experience. You can create an Amazon Kendra experience such as a search application. For more information on creating a search application experience, see Building a search experience with no code (https://docs.aws.amazon.com/kendra/latest/dg/deploying-search-experience-no-code.html).
#
# POST /
# Returns: record<FailedEntityList: table<EntityId: string, ErrorMessage: string>>
# operationId: AssociatePersonasToEntities
export def "associate-personas-to-entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of your Amazon Kendra experience.
  index_id: string # The identifier of the index for your Amazon Kendra experience.
  personas: list # The personas that define the specific permissions of users or groups in your IAM Identity Center identity source. The available personas or access roles are Owner and Viewer. For more information on these personas, see Providing access to your search page (https://docs.aws.amazon.com/kendra/latest/dg/deploying-search-experience-no-code.html#access-search-experience). — item shape: {EntityId: string, Persona: "OWNER"|"VIEWER"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.AssociatePersonasToEntities"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: IndexId, var: index_id}, {name: Personas, var: personas}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, index_id: $index_id, personas: $personas
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes one or more documents from an index. The documents must have been added with the BatchPutDocument API. The documents are deleted asynchronously. You can see the progress of the deletion by using Amazon Web Services CloudWatch. Any error messages related to the processing of the batch are sent to you CloudWatch log.
#
# POST /
# Returns: record<FailedDocuments: table<Id: string, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchDeleteDocument
export def "batch-delete-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index that contains the documents to delete.
  document_id_list: list<string> # One or more identifiers for documents to delete from the index.
  --data-source-sync-job-metric-target: record # Maps a particular data source sync job to a particular data source. — shape: {DataSourceId: string, DataSourceSyncJobId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.BatchDeleteDocument"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: DocumentIdList, var: document_id_list}, {name: DataSourceSyncJobMetricTarget, var: data_source_sync_job_metric_target}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, document_id_list: $document_id_list, data_source_sync_job_metric_target: $data_source_sync_job_metric_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes one or more sets of featured results. Features results are placed above all other results for certain queries. If there's an exact match of a query, then one or more specific documents are featured in the search results.
#
# POST /
# Returns: record<Errors: table<Id: string, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchDeleteFeaturedResultsSet
export def "batch-delete-featured-results-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index used for featuring results.
  featured_results_set_ids: list<string> # The identifiers of the featured results sets that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.BatchDeleteFeaturedResultsSet"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: FeaturedResultsSetIds, var: featured_results_set_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, featured_results_set_ids: $featured_results_set_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the indexing status for one or more documents submitted with the BatchPutDocument (https://docs.aws.amazon.com/kendra/latest/dg/API_BatchPutDocument.html) API. When you use the BatchPutDocument API, documents are indexed asynchronously. You can use the BatchGetDocumentStatus API to get the current status of a list of documents so that you can determine if they have been successfully indexed. You can also use the BatchGetDocumentStatus API to check the status of the BatchDeleteDocument (https://docs.aws.amazon.com/kendra/latest/dg/API_BatchDeleteDocument.html) API. When a document is deleted from the index, Amazon Kendra returns NOT_FOUND as the status.
#
# POST /
# Returns: record<Errors: table<DocumentId: string, ErrorCode: string, ErrorMessage: string>, DocumentStatusList: table<DocumentId: string, DocumentStatus: string, FailureCode: string, FailureReason: string>>
# operationId: BatchGetDocumentStatus
export def "batch-get-document-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index to add documents to. The index ID is returned by the CreateIndex (https://docs.aws.amazon.com/kendra/latest/dg/API_CreateIndex.html) API.
  document_info_list: list # A list of DocumentInfo objects that identify the documents for which to get the status. You identify the documents by their document ID and optional attributes. — item shape: {DocumentId: string, Attributes?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.BatchGetDocumentStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: DocumentInfoList, var: document_info_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, document_info_list: $document_info_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds one or more documents to an index. The BatchPutDocument API enables you to ingest inline documents or a set of documents stored in an Amazon S3 bucket. Use this API to ingest your text and unstructured text into an index, add custom attributes to the documents, and to attach an access control list to the documents added to the index. The documents are indexed asynchronously. You can see the progress of the batch using Amazon Web Services CloudWatch. Any error messages related to processing the batch are sent to your Amazon Web Services CloudWatch log. For an example of ingesting inline documents using Python and Java SDKs, see Adding files directly to an index (https://docs.aws.amazon.com/kendra/latest/dg/in-adding-binary-doc.html).
#
# POST /
# Returns: record<FailedDocuments: table<Id: string, ErrorCode: string, ErrorMessage: string>>
# operationId: BatchPutDocument
export def "batch-put-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index to add the documents to. You need to create the index first using the CreateIndex API.
  --role-arn: string # The Amazon Resource Name (ARN) of an IAM role with permission to access your S3 bucket. For more information, see IAM access roles for Amazon Kendra (https://docs.aws.amazon.com/kendra/latest/dg/iam-roles.html).
  documents: list # One or more documents to add to the index. Documents have the following file size limits. 50 MB total size for any file 5 MB extracted text for any file For more information, see Quotas (https://docs.aws.amazon.com/kendra/latest/dg/quotas.html). — item shape: {Id: string, Title?: string, Blob?: string, S3Path?: record, Attributes?: list, AccessControlList?: list, HierarchicalAccessControlList?: list, ContentType?: "PDF"|"HTML"|"MS_WORD"|"PLAIN_TEXT"|"PPT"|"RTF"|"XML"|"XSLT"|"MS_EXCEL"|"CSV"|"JSON"|"MD", AccessControlConfigurationId?: string}
  --custom-document-enrichment-configuration: record # Provides the configuration information for altering document metadata and content during the document ingestion process. For more information, see Customizing document metadata during the ingestion process (https://docs.aws.amazon.com/kendra/latest/dg/custom-document-enrichment.html). — shape: {InlineConfigurations?: list, PreExtractionHookConfiguration?: record, PostExtractionHookConfiguration?: record, RoleArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.BatchPutDocument"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: RoleArn, var: role_arn}, {name: Documents, var: documents}, {name: CustomDocumentEnrichmentConfiguration, var: custom_document_enrichment_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, role_arn: $role_arn, documents: $documents, custom_document_enrichment_configuration: $custom_document_enrichment_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clears existing query suggestions from an index. This deletes existing suggestions only, not the queries in the query log. After you clear suggestions, Amazon Kendra learns new suggestions based on new queries added to the query log from the time you cleared suggestions. If you do not see any new suggestions, then please allow Amazon Kendra to collect enough queries to learn new suggestions. ClearQuerySuggestions is currently not supported in the Amazon Web Services GovCloud (US-West) region.
#
# POST /
# operationId: ClearQuerySuggestions
export def "clear-query-suggestions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index you want to clear query suggestions from.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.ClearQuerySuggestions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an access configuration for your documents. This includes user and group access information for your documents. This is useful for user context filtering, where search results are filtered based on the user or their group access to documents. You can use this to re-configure your existing document level access control without indexing all of your documents again. For example, your index contains top-secret company documents that only certain employees or users should access. One of these users leaves the company or switches to a team that should be blocked from accessing top-secret documents. The user still has access to top-secret documents because the user had access when your documents were previously indexed. You can create a specific access control configuration for the user with deny access. You can later update the access control configuration to allow access if the user returns to the company and re-joins the 'top-secret' team. You can re-configure access control for your documents as circumstances change. To apply your access control configuration to certain documents, you call the BatchPutDocument (https://docs.aws.amazon.com/kendra/latest/dg/API_BatchPutDocument.html) API with the AccessControlConfigurationId included in the Document (https://docs.aws.amazon.com/kendra/latest/dg/API_Document.html) object. If you use an S3 bucket as a data source, you update the .metadata.json with the AccessControlConfigurationId and synchronize your data source. Amazon Kendra currently only supports access control configuration for S3 data sources and documents indexed using the BatchPutDocument API.
#
# POST /
# Returns: record<Id: string>
# operationId: CreateAccessControlConfiguration
export def "create-access-control-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index to create an access control configuration for your documents.
  name: string # A name for the access control configuration.
  --description: string # A description for the access control configuration.
  --access-control-list: list # Information on principals (users and/or groups) and which documents they should have access to. This is useful for user context filtering, where search results are filtered based on the user or their group access to documents. — item shape: {Name: string, Type: "USER"|"GROUP", Access: "ALLOW"|"DENY", DataSourceId?: string}
  --hierarchical-access-control-list: list # A list of principal (https://docs.aws.amazon.com/kendra/latest/dg/API_Principal.html) lists that define the hierarchy for which documents users should have access to. Each hierarchical list specifies which user or group has allow or deny access for each document. — item shape: {PrincipalList: list}
  --client-token: string # A token that you provide to identify the request to create an access control configuration. Multiple calls to the CreateAccessControlConfiguration API with the same client token will create only one access control configuration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.CreateAccessControlConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: Name, var: name}, {name: Description, var: description}, {name: AccessControlList, var: access_control_list}, {name: HierarchicalAccessControlList, var: hierarchical_access_control_list}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, name: $name, description: $description, access_control_list: $access_control_list, hierarchical_access_control_list: $hierarchical_access_control_list, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a data source connector that you want to use with an Amazon Kendra index. You specify a name, data source connector type and description for your data source. You also specify configuration information for the data source connector. CreateDataSource is a synchronous operation. The operation returns 200 if the data source was successfully created. Otherwise, an exception is raised. For an example of creating an index and data source using the Python SDK, see Getting started with Python SDK (https://docs.aws.amazon.com/kendra/latest/dg/gs-python.html). For an example of creating an index and data source using the Java SDK, see Getting started with Java SDK (https://docs.aws.amazon.com/kendra/latest/dg/gs-java.html).
#
# POST /
# Returns: record<Id: string>
# operationId: CreateDataSource
export def "create-data-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # A name for the data source connector.
  index_id: string # The identifier of the index you want to use with the data source connector.
  type: string@type-completer # The type of data source repository. For example, SHAREPOINT.
  --configuration: record # Provides the configuration information for an Amazon Kendra data source. — shape: {S3Configuration?: record, SharePointConfiguration?: record, DatabaseConfiguration?: record, SalesforceConfiguration?: record, OneDriveConfiguration?: record, ServiceNowConfiguration?: record, ConfluenceConfiguration?: record, GoogleDriveConfiguration?: record, WebCrawlerConfiguration?: record, WorkDocsConfiguration?: record, FsxConfiguration?: record, SlackConfiguration?: record, BoxConfiguration?: record, QuipConfiguration?: record, JiraConfiguration?: record, GitHubConfiguration?: record, ... (2 more fields)}
  --vpc-configuration: record # Provides the configuration information to connect to an Amazon VPC. — shape: {SubnetIds: list<string>, SecurityGroupIds: list<string>}
  --description: string # A description for the data source connector.
  --schedule: string # Sets the frequency for Amazon Kendra to check the documents in your data source repository and update the index. If you don't set a schedule Amazon Kendra will not periodically update the index. You can call the StartDataSourceSyncJob API to update the index. Specify a cron- format schedule string or an empty string to indicate that the index is updated on demand. You can't specify the Schedule parameter when the Type parameter is set to CUSTOM. If you do, you receive a ValidationException exception.
  --role-arn: string # The Amazon Resource Name (ARN) of an IAM role with permission to access the data source and required resources. For more information, see IAM access roles for Amazon Kendra. (https://docs.aws.amazon.com/kendra/latest/dg/iam-roles.html). You can't specify the RoleArn parameter when the Type parameter is set to CUSTOM. If you do, you receive a ValidationException exception. The RoleArn parameter is required for all other data sources.
  --tags: list # A list of key-value pairs that identify or categorize the data source connector. You can also use tags to help control access to the data source connector. Tag keys and values can consist of Unicode letters, digits, white space, and any of the following symbols: _ . : / = + - @. — item shape: {Key: string, Value: string}
  --client-token: string # A token that you provide to identify the request to create a data source connector. Multiple calls to the CreateDataSource API with the same client token will create only one data source connector.
  --language-code: string # The code for a language. The default language is English. For more information on supported languages, including their codes, see Adding documents in languages other than English (https://docs.aws.amazon.com/kendra/latest/dg/in-adding-languages.html).
  --custom-document-enrichment-configuration: record # Provides the configuration information for altering document metadata and content during the document ingestion process. For more information, see Customizing document metadata during the ingestion process (https://docs.aws.amazon.com/kendra/latest/dg/custom-document-enrichment.html). — shape: {InlineConfigurations?: list, PreExtractionHookConfiguration?: record, PostExtractionHookConfiguration?: record, RoleArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.CreateDataSource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: IndexId, var: index_id}, {name: Type, var: type}, {name: Configuration, var: configuration}, {name: VpcConfiguration, var: vpc_configuration}, {name: Description, var: description}, {name: Schedule, var: schedule}, {name: RoleArn, var: role_arn}, {name: Tags, var: tags}, {name: ClientToken, var: client_token}, {name: LanguageCode, var: language_code}, {name: CustomDocumentEnrichmentConfiguration, var: custom_document_enrichment_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, index_id: $index_id, type: $type, configuration: $configuration, vpc_configuration: $vpc_configuration, description: $description, schedule: $schedule, role_arn: $role_arn, tags: $tags, client_token: $client_token, language_code: $language_code, custom_document_enrichment_configuration: $custom_document_enrichment_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon Kendra experience such as a search application. For more information on creating a search application experience, including using the Python and Java SDKs, see Building a search experience with no code (https://docs.aws.amazon.com/kendra/latest/dg/deploying-search-experience-no-code.html).
#
# POST /
# Returns: record<Id: string>
# operationId: CreateExperience
export def "create-experience" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # A name for your Amazon Kendra experience.
  index_id: string # The identifier of the index for your Amazon Kendra experience.
  --role-arn: string # The Amazon Resource Name (ARN) of an IAM role with permission to access Query API, GetQuerySuggestions API, and other required APIs. The role also must include permission to access IAM Identity Center (successor to Single Sign-On) that stores your user and group information. For more information, see IAM access roles for Amazon Kendra (https://docs.aws.amazon.com/kendra/latest/dg/iam-roles.html).
  --configuration: record # Provides the configuration information for your Amazon Kendra experience. This includes the data source IDs and/or FAQ IDs, and user or group information to grant access to your Amazon Kendra experience. — shape: {ContentSourceConfiguration?: record, UserIdentityConfiguration?: record}
  --description: string # A description for your Amazon Kendra experience.
  --client-token: string # A token that you provide to identify the request to create your Amazon Kendra experience. Multiple calls to the CreateExperience API with the same client token creates only one Amazon Kendra experience.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.CreateExperience"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: IndexId, var: index_id}, {name: RoleArn, var: role_arn}, {name: Configuration, var: configuration}, {name: Description, var: description}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, index_id: $index_id, role_arn: $role_arn, configuration: $configuration, description: $description, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a set of frequently ask questions (FAQs) using a specified FAQ file stored in an Amazon S3 bucket. Adding FAQs to an index is an asynchronous operation. For an example of adding an FAQ to an index using Python and Java SDKs, see Using your FAQ file (https://docs.aws.amazon.com/kendra/latest/dg/in-creating-faq.html#using-faq-file).
#
# POST /
# Returns: record<Id: string>
# operationId: CreateFaq
export def "create-faq" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index for the FAQ.
  name: string # A name for the FAQ.
  --description: string # A description for the FAQ.
  s3_path: record # Information required to find a specific file in an Amazon S3 bucket. — shape: {Bucket: string, Key: string}
  role_arn: string # The Amazon Resource Name (ARN) of an IAM role with permission to access the S3 bucket that contains the FAQs. For more information, see IAM access roles for Amazon Kendra (https://docs.aws.amazon.com/kendra/latest/dg/iam-roles.html).
  --tags: list # A list of key-value pairs that identify the FAQ. You can use the tags to identify and organize your resources and to control access to resources. — item shape: {Key: string, Value: string}
  --file-format: string@file-format-completer # The format of the FAQ input file. You can choose between a basic CSV format, a CSV format that includes customs attributes in a header, and a JSON format that includes custom attributes. The format must match the format of the file stored in the S3 bucket identified in the S3Path parameter. For more information, see Adding questions and answers (https://docs.aws.amazon.com/kendra/latest/dg/in-creating-faq.html).
  --client-token: string # A token that you provide to identify the request to create a FAQ. Multiple calls to the CreateFaqRequest API with the same client token will create only one FAQ.
  --language-code: string # The code for a language. The default language is English. For more information on supported languages, including their codes, see Adding documents in languages other than English (https://docs.aws.amazon.com/kendra/latest/dg/in-adding-languages.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.CreateFaq"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: Name, var: name}, {name: Description, var: description}, {name: S3Path, var: s3_path}, {name: RoleArn, var: role_arn}, {name: Tags, var: tags}, {name: FileFormat, var: file_format}, {name: ClientToken, var: client_token}, {name: LanguageCode, var: language_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, name: $name, description: $description, s3_path: $s3_path, role_arn: $role_arn, tags: $tags, file_format: $file_format, client_token: $client_token, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a set of featured results to display at the top of the search results page. Featured results are placed above all other results for certain queries. You map specific queries to specific documents for featuring in the results. If a query contains an exact match, then one or more specific documents are featured in the search results. You can create up to 50 sets of featured results per index. You can request to increase this limit by contacting Support (http://aws.amazon.com/contact-us/).
#
# POST /
# Returns: record<FeaturedResultsSet: record<FeaturedResultsSetId: string, FeaturedResultsSetName: string, Description: string, Status: string, QueryTexts: list<string>, FeaturedDocuments: list<record>, LastUpdatedTimestamp: int, CreationTimestamp: int>>
# operationId: CreateFeaturedResultsSet
export def "create-featured-results-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index that you want to use for featuring results.
  featured_results_set_name: string # A name for the set of featured results.
  --description: string # A description for the set of featured results.
  --client-token: string # A token that you provide to identify the request to create a set of featured results. Multiple calls to the CreateFeaturedResultsSet API with the same client token will create only one featured results set.
  --status: string@status-completer # The current status of the set of featured results. When the value is ACTIVE, featured results are ready for use. You can still configure your settings before setting the status to ACTIVE. You can set the status to ACTIVE or INACTIVE using the UpdateFeaturedResultsSet (https://docs.aws.amazon.com/kendra/latest/dg/API_UpdateFeaturedResultsSet.html) API. The queries you specify for featured results must be unique per featured results set for each index, whether the status is ACTIVE or INACTIVE.
  --query-texts: list<string> # A list of queries for featuring results. For more information on the list of queries, see FeaturedResultsSet (https://docs.aws.amazon.com/kendra/latest/dg/API_FeaturedResultsSet.html).
  --featured-documents: list # A list of document IDs for the documents you want to feature at the top of the search results page. For more information on the list of documents, see FeaturedResultsSet (https://docs.aws.amazon.com/kendra/latest/dg/API_FeaturedResultsSet.html). — item shape: {Id?: string}
  --tags: list # A list of key-value pairs that identify or categorize the featured results set. You can also use tags to help control access to the featured results set. Tag keys and values can consist of Unicode letters, digits, white space, and any of the following symbols:_ . : / = + - @. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.CreateFeaturedResultsSet"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: FeaturedResultsSetName, var: featured_results_set_name}, {name: Description, var: description}, {name: ClientToken, var: client_token}, {name: Status, var: status}, {name: QueryTexts, var: query_texts}, {name: FeaturedDocuments, var: featured_documents}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, featured_results_set_name: $featured_results_set_name, description: $description, client_token: $client_token, status: $status, query_texts: $query_texts, featured_documents: $featured_documents, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon Kendra index. Index creation is an asynchronous API. To determine if index creation has completed, check the Status field returned from a call to DescribeIndex. The Status field is set to ACTIVE when the index is ready to use. Once the index is active you can index your documents using the BatchPutDocument API or using one of the supported data sources. For an example of creating an index and data source using the Python SDK, see Getting started with Python SDK (https://docs.aws.amazon.com/kendra/latest/dg/gs-python.html). For an example of creating an index and data source using the Java SDK, see Getting started with Java SDK (https://docs.aws.amazon.com/kendra/latest/dg/gs-java.html).
#
# POST /
# Returns: record<Id: string>
# operationId: CreateIndex
export def "create-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # A name for the index.
  --edition: string@edition-completer # The Amazon Kendra edition to use for the index. Choose DEVELOPER_EDITION for indexes intended for development, testing, or proof of concept. Use ENTERPRISE_EDITION for production. Once you set the edition for an index, it can't be changed. The Edition parameter is optional. If you don't supply a value, the default is ENTERPRISE_EDITION. For more information on quota limits for Enterprise and Developer editions, see Quotas (https://docs.aws.amazon.com/kendra/latest/dg/quotas.html).
  role_arn: string # The Amazon Resource Name (ARN) of an IAM role with permission to access your Amazon CloudWatch logs and metrics. For more information, see IAM access roles for Amazon Kendra (https://docs.aws.amazon.com/kendra/latest/dg/iam-roles.html).
  --server-side-encryption-configuration: record # Provides the identifier of the KMS key used to encrypt data indexed by Amazon Kendra. Amazon Kendra doesn't support asymmetric keys. — shape: {KmsKeyId?: string}
  --description: string # A description for the index.
  --client-token: string # A token that you provide to identify the request to create an index. Multiple calls to the CreateIndex API with the same client token will create only one index.
  --tags: list # A list of key-value pairs that identify or categorize the index. You can also use tags to help control access to the index. Tag keys and values can consist of Unicode letters, digits, white space, and any of the following symbols: _ . : / = + - @. — item shape: {Key: string, Value: string}
  --user-token-configurations: list # The user token configuration. — item shape: {JwtTokenTypeConfiguration?: record, JsonTokenTypeConfiguration?: record}
  --user-context-policy: string@user-context-policy-completer # The user context policy. ATTRIBUTE_FILTER All indexed content is searchable and displayable for all users. If you want to filter search results on user context, you can use the attribute filters of _user_id and _group_ids or you can provide user and group information in UserContext. USER_TOKEN Enables token-based user access control to filter search results on user context. All documents with no access control and all documents accessible to the user will be searchable and displayable.
  --user-group-resolution-configuration: record # Provides the configuration information to get users and groups from an IAM Identity Center (successor to Single Sign-On) identity source. This is useful for user context filtering, where search results are filtered based on the user or their group access to documents. You can also use the PutPrincipalMapping (https://docs.aws.amazon.com/kendra/latest/dg/API_PutPrincipalMapping.html) API to map users to their groups so that you only need to provide the user ID when you issue the query. To set up an IAM Identity Center identity source in the console to use with Amazon Kendra, see Getting started with an IAM Identity Center identity source (https://docs.aws.amazon.com/kendra/latest/dg/getting-started-aws-sso.html). You must also grant the required permissions to use IAM Identity Center with Amazon Kendra. For more information, see IAM roles for IAM Identity Center (https://docs.aws.amazon.com/kendra/latest/dg/iam-roles.html#iam-roles-aws-sso). Amazon Kendra currently does not support using UserGroupResolutionConfiguration with an Amazon Web Services organization member account for your IAM Identity Center identify source. You must create your index in the management account for the organization in order to use UserGroupResolutionConfiguration. — shape: {UserGroupResolutionMode: "AWS_SSO"|"NONE"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.CreateIndex"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Edition, var: edition}, {name: RoleArn, var: role_arn}, {name: ServerSideEncryptionConfiguration, var: server_side_encryption_configuration}, {name: Description, var: description}, {name: ClientToken, var: client_token}, {name: Tags, var: tags}, {name: UserTokenConfigurations, var: user_token_configurations}, {name: UserContextPolicy, var: user_context_policy}, {name: UserGroupResolutionConfiguration, var: user_group_resolution_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, edition: $edition, role_arn: $role_arn, server_side_encryption_configuration: $server_side_encryption_configuration, description: $description, client_token: $client_token, tags: $tags, user_token_configurations: $user_token_configurations, user_context_policy: $user_context_policy, user_group_resolution_configuration: $user_group_resolution_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a block list to exlcude certain queries from suggestions. Any query that contains words or phrases specified in the block list is blocked or filtered out from being shown as a suggestion. You need to provide the file location of your block list text file in your S3 bucket. In your text file, enter each block word or phrase on a separate line. For information on the current quota limits for block lists, see Quotas for Amazon Kendra (https://docs.aws.amazon.com/kendra/latest/dg/quotas.html). CreateQuerySuggestionsBlockList is currently not supported in the Amazon Web Services GovCloud (US-West) region. For an example of creating a block list for query suggestions using the Python SDK, see Query suggestions block list (https://docs.aws.amazon.com/kendra/latest/dg/query-suggestions.html#suggestions-block-list).
#
# POST /
# Returns: record<Id: string>
# operationId: CreateQuerySuggestionsBlockList
export def "create-query-suggestions-block-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index you want to create a query suggestions block list for.
  name: string # A name for the block list. For example, the name 'offensive-words', which includes all offensive words that could appear in user queries and need to be blocked from suggestions.
  --description: string # A description for the block list. For example, the description "List of all offensive words that can appear in user queries and need to be blocked from suggestions."
  source_s3_path: record # Information required to find a specific file in an Amazon S3 bucket. — shape: {Bucket: string, Key: string}
  --client-token: string # A token that you provide to identify the request to create a query suggestions block list.
  role_arn: string # The Amazon Resource Name (ARN) of an IAM role with permission to access your S3 bucket that contains the block list text file. For more information, see IAM access roles for Amazon Kendra (https://docs.aws.amazon.com/kendra/latest/dg/iam-roles.html).
  --tags: list # A list of key-value pairs that identify or categorize the block list. Tag keys and values can consist of Unicode letters, digits, white space, and any of the following symbols: _ . : / = + - @. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.CreateQuerySuggestionsBlockList"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: Name, var: name}, {name: Description, var: description}, {name: SourceS3Path, var: source_s3_path}, {name: ClientToken, var: client_token}, {name: RoleArn, var: role_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, name: $name, description: $description, source_s3_path: $source_s3_path, client_token: $client_token, role_arn: $role_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a thesaurus for an index. The thesaurus contains a list of synonyms in Solr format. For an example of adding a thesaurus file to an index, see Adding custom synonyms to an index (https://docs.aws.amazon.com/kendra/latest/dg/index-synonyms-adding-thesaurus-file.html).
#
# POST /
# Returns: record<Id: string>
# operationId: CreateThesaurus
export def "create-thesaurus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index for the thesaurus.
  name: string # A name for the thesaurus.
  --description: string # A description for the thesaurus.
  role_arn: string # The Amazon Resource Name (ARN) of an IAM role with permission to access your S3 bucket that contains the thesaurus file. For more information, see IAM access roles for Amazon Kendra (https://docs.aws.amazon.com/kendra/latest/dg/iam-roles.html).
  --tags: list # A list of key-value pairs that identify or categorize the thesaurus. You can also use tags to help control access to the thesaurus. Tag keys and values can consist of Unicode letters, digits, white space, and any of the following symbols: _ . : / = + - @. — item shape: {Key: string, Value: string}
  source_s3_path: record # Information required to find a specific file in an Amazon S3 bucket. — shape: {Bucket: string, Key: string}
  --client-token: string # A token that you provide to identify the request to create a thesaurus. Multiple calls to the CreateThesaurus API with the same client token will create only one thesaurus.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.CreateThesaurus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: Name, var: name}, {name: Description, var: description}, {name: RoleArn, var: role_arn}, {name: Tags, var: tags}, {name: SourceS3Path, var: source_s3_path}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, name: $name, description: $description, role_arn: $role_arn, tags: $tags, source_s3_path: $source_s3_path, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an access control configuration that you created for your documents in an index. This includes user and group access information for your documents. This is useful for user context filtering, where search results are filtered based on the user or their group access to documents.
#
# POST /
# Returns: record
# operationId: DeleteAccessControlConfiguration
export def "delete-access-control-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index for an access control configuration.
  id: string # The identifier of the access control configuration you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DeleteAccessControlConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Amazon Kendra data source connector. An exception is not thrown if the data source is already being deleted. While the data source is being deleted, the Status field returned by a call to the DescribeDataSource API is set to DELETING. For more information, see Deleting Data Sources (https://docs.aws.amazon.com/kendra/latest/dg/delete-data-source.html).
#
# POST /
# operationId: DeleteDataSource
export def "delete-data-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of the data source connector you want to delete.
  index_id: string # The identifier of the index used with the data source connector.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DeleteDataSource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: IndexId, var: index_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, index_id: $index_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes your Amazon Kendra experience such as a search application. For more information on creating a search application experience, see Building a search experience with no code (https://docs.aws.amazon.com/kendra/latest/dg/deploying-search-experience-no-code.html).
#
# POST /
# Returns: record
# operationId: DeleteExperience
export def "delete-experience" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of your Amazon Kendra experience you want to delete.
  index_id: string # The identifier of the index for your Amazon Kendra experience.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DeleteExperience"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: IndexId, var: index_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, index_id: $index_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an FAQ from an index.
#
# POST /
# operationId: DeleteFaq
export def "delete-faq" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of the FAQ you want to remove.
  index_id: string # The identifier of the index for the FAQ.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DeleteFaq"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: IndexId, var: index_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, index_id: $index_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing Amazon Kendra index. An exception is not thrown if the index is already being deleted. While the index is being deleted, the Status field returned by a call to the DescribeIndex API is set to DELETING.
#
# POST /
# operationId: DeleteIndex
export def "delete-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of the index you want to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DeleteIndex"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a group so that all users and sub groups that belong to the group can no longer access documents only available to that group. For example, after deleting the group "Summer Interns", all interns who belonged to that group no longer see intern-only documents in their search results. If you want to delete or replace users or sub groups of a group, you need to use the PutPrincipalMapping operation. For example, if a user in the group "Engineering" leaves the engineering team and another user takes their place, you provide an updated list of users or sub groups that belong to the "Engineering" group when calling PutPrincipalMapping. You can update your internal list of users or sub groups and input this list when calling PutPrincipalMapping. DeletePrincipalMapping is currently not supported in the Amazon Web Services GovCloud (US-West) region.
#
# POST /
# operationId: DeletePrincipalMapping
export def "delete-principal-mapping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index you want to delete a group from.
  --data-source-id: string # The identifier of the data source you want to delete a group from. A group can be tied to multiple data sources. You can delete a group from accessing documents in a certain data source. For example, the groups "Research", "Engineering", and "Sales and Marketing" are all tied to the company's documents stored in the data sources Confluence and Salesforce. You want to delete "Research" and "Engineering" groups from Salesforce, so that these groups cannot access customer-related documents stored in Salesforce. Only "Sales and Marketing" should access documents in the Salesforce data source.
  group_id: string # The identifier of the group you want to delete.
  --ordering-id: int # The timestamp identifier you specify to ensure Amazon Kendra does not override the latest DELETE action with previous actions. The highest number ID, which is the ordering ID, is the latest action you want to process and apply on top of other actions with lower number IDs. This prevents previous actions with lower number IDs from possibly overriding the latest action. The ordering ID can be the Unix time of the last update you made to a group members list. You would then provide this list when calling PutPrincipalMapping. This ensures your DELETE action for that updated group with the latest members list doesn't get overwritten by earlier DELETE actions for the same group which are yet to be processed. The default ordering ID is the current Unix time in milliseconds that the action was received by Amazon Kendra.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DeletePrincipalMapping"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: DataSourceId, var: data_source_id}, {name: GroupId, var: group_id}, {name: OrderingId, var: ordering_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, data_source_id: $data_source_id, group_id: $group_id, ordering_id: $ordering_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a block list used for query suggestions for an index. A deleted block list might not take effect right away. Amazon Kendra needs to refresh the entire suggestions list to add back the queries that were previously blocked. DeleteQuerySuggestionsBlockList is currently not supported in the Amazon Web Services GovCloud (US-West) region.
#
# POST /
# operationId: DeleteQuerySuggestionsBlockList
export def "delete-query-suggestions-block-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index for the block list.
  id: string # The identifier of the block list you want to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DeleteQuerySuggestionsBlockList"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing Amazon Kendra thesaurus.
#
# POST /
# operationId: DeleteThesaurus
export def "delete-thesaurus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of the thesaurus you want to delete.
  index_id: string # The identifier of the index for the thesaurus.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DeleteThesaurus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: IndexId, var: index_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, index_id: $index_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about an access control configuration that you created for your documents in an index. This includes user and group access information for your documents. This is useful for user context filtering, where search results are filtered based on the user or their group access to documents.
#
# POST /
# Returns: record<Name: string, Description: string, ErrorMessage: string, AccessControlList: table<Name: string, Type: string, Access: string, DataSourceId: string>, HierarchicalAccessControlList: table<PrincipalList: list>>
# operationId: DescribeAccessControlConfiguration
export def "describe-access-control-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index for an access control configuration.
  id: string # The identifier of the access control configuration you want to get information on.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DescribeAccessControlConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about an Amazon Kendra data source connector.
#
# POST /
# Returns: record<Id: string, IndexId: string, Name: string, Type: string, Configuration: record<S3Configuration: record<BucketName: string, InclusionPrefixes: list, InclusionPatterns: list, ExclusionPatterns: list, DocumentsMetadataConfiguration: record, AccessControlListConfiguration: record>, SharePointConfiguration: record<SharePointVersion: string, Urls: list, SecretArn: string, CrawlAttachments: bool, UseChangeLog: bool, InclusionPatterns: list, ExclusionPatterns: list, VpcConfiguration: record, FieldMappings: list, DocumentTitleFieldName: string, DisableLocalGroups: bool, SslCertificateS3Path: record, AuthenticationType: string, ProxyConfiguration: record>, DatabaseConfiguration: record<DatabaseEngineType: string, ConnectionConfiguration: record, VpcConfiguration: record, ColumnConfiguration: record, AclConfiguration: record, SqlConfiguration: record>, SalesforceConfiguration: record<ServerUrl: string, SecretArn: string, StandardObjectConfigurations: list, KnowledgeArticleConfiguration: record, ChatterFeedConfiguration: record, CrawlAttachments: bool, StandardObjectAttachmentConfiguration: record, IncludeAttachmentFilePatterns: list, ExcludeAttachmentFilePatterns: list>, OneDriveConfiguration: record<TenantDomain: string, SecretArn: string, OneDriveUsers: record, InclusionPatterns: list, ExclusionPatterns: list, FieldMappings: list, DisableLocalGroups: bool>, ServiceNowConfiguration: record<HostUrl: string, SecretArn: string, ServiceNowBuildVersion: string, KnowledgeArticleConfiguration: record, ServiceCatalogConfiguration: record, AuthenticationType: string>, ConfluenceConfiguration: record<ServerUrl: string, SecretArn: string, Version: string, SpaceConfiguration: record, PageConfiguration: record, BlogConfiguration: record, AttachmentConfiguration: record, VpcConfiguration: record, InclusionPatterns: list, ExclusionPatterns: list, ProxyConfiguration: record, AuthenticationType: string>, GoogleDriveConfiguration: record<SecretArn: string, InclusionPatterns: list, ExclusionPatterns: list, FieldMappings: list, ExcludeMimeTypes: list, ExcludeUserAccounts: list, ExcludeSharedDrives: list>, WebCrawlerConfiguration: record<Urls: record, CrawlDepth: int, MaxLinksPerPage: int, MaxContentSizePerPageInMegaBytes: float, MaxUrlsPerMinuteCrawlRate: int, UrlInclusionPatterns: list, UrlExclusionPatterns: list, ProxyConfiguration: record, AuthenticationConfiguration: record>, WorkDocsConfiguration: record<OrganizationId: string, CrawlComments: bool, UseChangeLog: bool, InclusionPatterns: list, ExclusionPatterns: list, FieldMappings: list>, FsxConfiguration: record<FileSystemId: string, FileSystemType: string, VpcConfiguration: record, SecretArn: string, InclusionPatterns: list, ExclusionPatterns: list, FieldMappings: list>, SlackConfiguration: record<TeamId: string, SecretArn: string, VpcConfiguration: record, SlackEntityList: list, UseChangeLog: bool, CrawlBotMessage: bool, ExcludeArchived: bool, SinceCrawlDate: string, LookBackPeriod: int, PrivateChannelFilter: list, PublicChannelFilter: list, InclusionPatterns: list, ExclusionPatterns: list, FieldMappings: list>, BoxConfiguration: record<EnterpriseId: string, SecretArn: string, UseChangeLog: bool, CrawlComments: bool, CrawlTasks: bool, CrawlWebLinks: bool, FileFieldMappings: list, TaskFieldMappings: list, CommentFieldMappings: list, WebLinkFieldMappings: list, InclusionPatterns: list, ExclusionPatterns: list, VpcConfiguration: record>, QuipConfiguration: record<Domain: string, SecretArn: string, CrawlFileComments: bool, CrawlChatRooms: bool, CrawlAttachments: bool, FolderIds: list, ThreadFieldMappings: list, MessageFieldMappings: list, AttachmentFieldMappings: list, InclusionPatterns: list, ExclusionPatterns: list, VpcConfiguration: record>, JiraConfiguration: record<JiraAccountUrl: string, SecretArn: string, UseChangeLog: bool, Project: list, IssueType: list, Status: list, IssueSubEntityFilter: list, AttachmentFieldMappings: list, CommentFieldMappings: list, IssueFieldMappings: list, ProjectFieldMappings: list, WorkLogFieldMappings: list, InclusionPatterns: list, ExclusionPatterns: list, VpcConfiguration: record>, GitHubConfiguration: record<SaaSConfiguration: record, OnPremiseConfiguration: record, Type: string, SecretArn: string, UseChangeLog: bool, GitHubDocumentCrawlProperties: record, RepositoryFilter: list, InclusionFolderNamePatterns: list, InclusionFileTypePatterns: list, InclusionFileNamePatterns: list, ExclusionFolderNamePatterns: list, ExclusionFileTypePatterns: list, ExclusionFileNamePatterns: list, VpcConfiguration: record, GitHubRepositoryConfigurationFieldMappings: list, GitHubCommitConfigurationFieldMappings: list, GitHubIssueDocumentConfigurationFieldMappings: list, GitHubIssueCommentConfigurationFieldMappings: list, GitHubIssueAttachmentConfigurationFieldMappings: list, GitHubPullRequestCommentConfigurationFieldMappings: list, GitHubPullRequestDocumentConfigurationFieldMappings: list, GitHubPullRequestDocumentAttachmentConfigurationFieldMappings: list>, AlfrescoConfiguration: record<SiteUrl: string, SiteId: string, SecretArn: string, SslCertificateS3Path: record, CrawlSystemFolders: bool, CrawlComments: bool, EntityFilter: list, DocumentLibraryFieldMappings: list, BlogFieldMappings: list, WikiFieldMappings: list, InclusionPatterns: list, ExclusionPatterns: list, VpcConfiguration: record>, TemplateConfiguration: record<Template: record>>, VpcConfiguration: record<SubnetIds: list<string>, SecurityGroupIds: list<string>>, CreatedAt: string, UpdatedAt: string, Description: string, Status: string, Schedule: string, RoleArn: string, ErrorMessage: string, LanguageCode: string, CustomDocumentEnrichmentConfiguration: record<InlineConfigurations: list<record>, PreExtractionHookConfiguration: record<InvocationCondition: record, LambdaArn: string, S3Bucket: string>, PostExtractionHookConfiguration: record<InvocationCondition: record, LambdaArn: string, S3Bucket: string>, RoleArn: string>>
# operationId: DescribeDataSource
export def "describe-data-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of the data source connector.
  index_id: string # The identifier of the index used with the data source connector.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DescribeDataSource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: IndexId, var: index_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, index_id: $index_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about your Amazon Kendra experience such as a search application. For more information on creating a search application experience, see Building a search experience with no code (https://docs.aws.amazon.com/kendra/latest/dg/deploying-search-experience-no-code.html).
#
# POST /
# Returns: record<Id: string, IndexId: string, Name: string, Endpoints: table<EndpointType: string, Endpoint: string>, Configuration: record<ContentSourceConfiguration: record<DataSourceIds: list, FaqIds: list, DirectPutContent: bool>, UserIdentityConfiguration: record<IdentityAttributeName: string>>, CreatedAt: string, UpdatedAt: string, Description: string, Status: string, RoleArn: string, ErrorMessage: string>
# operationId: DescribeExperience
export def "describe-experience" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of your Amazon Kendra experience you want to get information on.
  index_id: string # The identifier of the index for your Amazon Kendra experience.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DescribeExperience"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: IndexId, var: index_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, index_id: $index_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about an FAQ list.
#
# POST /
# Returns: record<Id: string, IndexId: string, Name: string, Description: string, CreatedAt: string, UpdatedAt: string, S3Path: record<Bucket: string, Key: string>, Status: string, RoleArn: string, ErrorMessage: string, FileFormat: string, LanguageCode: string>
# operationId: DescribeFaq
export def "describe-faq" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of the FAQ you want to get information on.
  index_id: string # The identifier of the index for the FAQ.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DescribeFaq"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: IndexId, var: index_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, index_id: $index_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a set of featured results. Features results are placed above all other results for certain queries. If there's an exact match of a query, then one or more specific documents are featured in the search results.
#
# POST /
# Returns: record<FeaturedResultsSetId: string, FeaturedResultsSetName: string, Description: string, Status: string, QueryTexts: list<string>, FeaturedDocumentsWithMetadata: table<Id: string, Title: string, URI: string>, FeaturedDocumentsMissing: table<Id: string>, LastUpdatedTimestamp: int, CreationTimestamp: int>
# operationId: DescribeFeaturedResultsSet
export def "describe-featured-results-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index used for featuring results.
  featured_results_set_id: string # The identifier of the set of featured results that you want to get information on.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DescribeFeaturedResultsSet"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: FeaturedResultsSetId, var: featured_results_set_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, featured_results_set_id: $featured_results_set_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about an existing Amazon Kendra index.
#
# POST /
# Returns: record<Name: string, Id: string, Edition: string, RoleArn: string, ServerSideEncryptionConfiguration: record<KmsKeyId: string>, Status: string, Description: string, CreatedAt: string, UpdatedAt: string, DocumentMetadataConfigurations: table<Name: string, Type: string, Relevance: record, Search: record>, IndexStatistics: record<FaqStatistics: record<IndexedQuestionAnswersCount: int>, TextDocumentStatistics: record<IndexedTextDocumentsCount: int, IndexedTextBytes: int>>, ErrorMessage: string, CapacityUnits: record<StorageCapacityUnits: int, QueryCapacityUnits: int>, UserTokenConfigurations: table<JwtTokenTypeConfiguration: record, JsonTokenTypeConfiguration: record>, UserContextPolicy: string, UserGroupResolutionConfiguration: record<UserGroupResolutionMode: string>>
# operationId: DescribeIndex
export def "describe-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of the index you want to get information on.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DescribeIndex"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the processing of PUT and DELETE actions for mapping users to their groups. This includes information on the status of actions currently processing or yet to be processed, when actions were last updated, when actions were received by Amazon Kendra, the latest action that should process and apply after other actions, and useful error messages if an action could not be processed. DescribePrincipalMapping is currently not supported in the Amazon Web Services GovCloud (US-West) region.
#
# POST /
# Returns: record<IndexId: string, DataSourceId: string, GroupId: string, GroupOrderingIdSummaries: table<Status: string, LastUpdatedAt: string, ReceivedAt: string, OrderingId: int, FailureReason: string>>
# operationId: DescribePrincipalMapping
export def "describe-principal-mapping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index required to check the processing of PUT and DELETE actions for mapping users to their groups.
  --data-source-id: string # The identifier of the data source to check the processing of PUT and DELETE actions for mapping users to their groups.
  group_id: string # The identifier of the group required to check the processing of PUT and DELETE actions for mapping users to their groups.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DescribePrincipalMapping"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: DataSourceId, var: data_source_id}, {name: GroupId, var: group_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, data_source_id: $data_source_id, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a block list used for query suggestions for an index. This is used to check the current settings that are applied to a block list. DescribeQuerySuggestionsBlockList is currently not supported in the Amazon Web Services GovCloud (US-West) region.
#
# POST /
# Returns: record<IndexId: string, Id: string, Name: string, Description: string, Status: string, ErrorMessage: string, CreatedAt: string, UpdatedAt: string, SourceS3Path: record<Bucket: string, Key: string>, ItemCount: int, FileSizeBytes: int, RoleArn: string>
# operationId: DescribeQuerySuggestionsBlockList
export def "describe-query-suggestions-block-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index for the block list.
  id: string # The identifier of the block list you want to get information on.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DescribeQuerySuggestionsBlockList"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information on the settings of query suggestions for an index. This is used to check the current settings applied to query suggestions. DescribeQuerySuggestionsConfig is currently not supported in the Amazon Web Services GovCloud (US-West) region.
#
# POST /
# Returns: record<Mode: string, Status: string, QueryLogLookBackWindowInDays: int, IncludeQueriesWithoutUserInformation: bool, MinimumNumberOfQueryingUsers: int, MinimumQueryCount: int, LastSuggestionsBuildTime: string, LastClearTime: string, TotalSuggestionsCount: int>
# operationId: DescribeQuerySuggestionsConfig
export def "describe-query-suggestions-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index with query suggestions that you want to get information on.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DescribeQuerySuggestionsConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about an existing Amazon Kendra thesaurus.
#
# POST /
# Returns: record<Id: string, IndexId: string, Name: string, Description: string, Status: string, ErrorMessage: string, CreatedAt: string, UpdatedAt: string, RoleArn: string, SourceS3Path: record<Bucket: string, Key: string>, FileSizeBytes: int, TermCount: int, SynonymRuleCount: int>
# operationId: DescribeThesaurus
export def "describe-thesaurus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of the thesaurus you want to get information on.
  index_id: string # The identifier of the index for the thesaurus.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DescribeThesaurus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: IndexId, var: index_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, index_id: $index_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Prevents users or groups in your IAM Identity Center identity source from accessing your Amazon Kendra experience. You can create an Amazon Kendra experience such as a search application. For more information on creating a search application experience, see Building a search experience with no code (https://docs.aws.amazon.com/kendra/latest/dg/deploying-search-experience-no-code.html).
#
# POST /
# Returns: record<FailedEntityList: table<EntityId: string, ErrorMessage: string>>
# operationId: DisassociateEntitiesFromExperience
export def "disassociate-entities-from-experience" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of your Amazon Kendra experience.
  index_id: string # The identifier of the index for your Amazon Kendra experience.
  entity_list: list # Lists users or groups in your IAM Identity Center identity source. — item shape: {EntityId: string, EntityType: "USER"|"GROUP"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DisassociateEntitiesFromExperience"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: IndexId, var: index_id}, {name: EntityList, var: entity_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, index_id: $index_id, entity_list: $entity_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the specific permissions of users or groups in your IAM Identity Center identity source with access to your Amazon Kendra experience. You can create an Amazon Kendra experience such as a search application. For more information on creating a search application experience, see Building a search experience with no code (https://docs.aws.amazon.com/kendra/latest/dg/deploying-search-experience-no-code.html).
#
# POST /
# Returns: record<FailedEntityList: table<EntityId: string, ErrorMessage: string>>
# operationId: DisassociatePersonasFromEntities
export def "disassociate-personas-from-entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of your Amazon Kendra experience.
  index_id: string # The identifier of the index for your Amazon Kendra experience.
  entity_ids: list<string> # The identifiers of users or groups in your IAM Identity Center identity source. For example, user IDs could be user emails.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.DisassociatePersonasFromEntities"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: IndexId, var: index_id}, {name: EntityIds, var: entity_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, index_id: $index_id, entity_ids: $entity_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the queries that are suggested to your users. GetQuerySuggestions is currently not supported in the Amazon Web Services GovCloud (US-West) region.
#
# POST /
# Returns: record<QuerySuggestionsId: string, Suggestions: table<Id: string, Value: record>>
# operationId: GetQuerySuggestions
export def "get-query-suggestions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index you want to get query suggestions from.
  query_text: string # The text of a user's query to generate query suggestions. A query is suggested if the query prefix matches what a user starts to type as their query. Amazon Kendra does not show any suggestions if a user types fewer than two characters or more than 60 characters. A query must also have at least one search result and contain at least one word of more than four characters.
  --max-suggestions-count: int # The maximum number of query suggestions you want to show to your users.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.GetQuerySuggestions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: QueryText, var: query_text}, {name: MaxSuggestionsCount, var: max_suggestions_count}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, query_text: $query_text, max_suggestions_count: $max_suggestions_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves search metrics data. The data provides a snapshot of how your users interact with your search application and how effective the application is.
#
# POST /
# Returns: record<SnapShotTimeFilter: record<StartTime: string, EndTime: string>, SnapshotsDataHeader: list<string>, SnapshotsData: list<list<string>>, NextToken: string>
# operationId: GetSnapshots
export def "get-snapshots" [
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  index_id: string # The identifier of the index to get search metrics data.
  interval: string@interval-completer # The time interval or time window to get search metrics data. The time interval uses the time zone of your index. You can view data in the following time windows: THIS_WEEK: The current week, starting on the Sunday and ending on the day before the current date. ONE_WEEK_AGO: The previous week, starting on the Sunday and ending on the following Saturday. TWO_WEEKS_AGO: The week before the previous week, starting on the Sunday and ending on the following Saturday. THIS_MONTH: The current month, starting on the first day of the month and ending on the day before the current date. ONE_MONTH_AGO: The previous month, starting on the first day of the month and ending on the last day of the month. TWO_MONTHS_AGO: The month before the previous month, starting on the first day of the month and ending on last day of the month.
  metric_type: string@metric-type-completer # The metric you want to retrieve. You can specify only one metric per call. For more information about the metrics you can view, see Gaining insights with search analytics (https://docs.aws.amazon.com/kendra/latest/dg/search-analytics.html).
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Kendra returns a pagination token in the response. You can use this pagination token to retrieve the next set of search metrics data. (spec name: NextToken)
  --body-max-results: int # The maximum number of returned data for the metric. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.GetSnapshots"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: Interval, var: interval}, {name: MetricType, var: metric_type}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, interval: $interval, metric_type: $metric_type, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists one or more access control configurations for an index. This includes user and group access information for your documents. This is useful for user context filtering, where search results are filtered based on the user or their group access to documents.
#
# POST /
# Returns: record<NextToken: string, AccessControlConfigurations: table<Id: string>>
# operationId: ListAccessControlConfigurations
export def "list-access-control-configurations" [
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
  --x-amz-target: string@x-amz-target-completer-37 # required
  index_id: string # The identifier of the index for the access control configuration.
  --body-next-token: string # If the previous response was incomplete (because there's more data to retrieve), Amazon Kendra returns a pagination token in the response. You can use this pagination token to retrieve the next set of access control configurations. (spec name: NextToken)
  --body-max-results: int # The maximum number of access control configurations to return. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.ListAccessControlConfigurations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets statistics about synchronizing a data source connector.
#
# POST /
# Returns: record<History: table<ExecutionId: string, StartTime: string, EndTime: string, Status: string, ErrorMessage: string, ErrorCode: string, DataSourceErrorCode: string, Metrics: record>, NextToken: string>
# operationId: ListDataSourceSyncJobs
export def "list-data-source-sync-jobs" [
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
  --x-amz-target: string@x-amz-target-completer-38 # required
  id: string # The identifier of the data source connector.
  index_id: string # The identifier of the index used with the data source connector.
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Kendra returns a pagination token in the response. You can use this pagination token to retrieve the next set of jobs. (spec name: NextToken)
  --body-max-results: int # The maximum number of synchronization jobs to return in the response. If there are fewer results in the list, this response contains only the actual results. (spec name: MaxResults)
  --start-time-filter: record # Provides a range of time. — shape: {StartTime?: string, EndTime?: string}
  --status-filter: string@status-filter-completer # Only returns synchronization jobs with the Status field equal to the specified status.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.ListDataSourceSyncJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: IndexId, var: index_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: StartTimeFilter, var: start_time_filter}, {name: StatusFilter, var: status_filter}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, index_id: $index_id, body_next_token: $body_next_token, body_max_results: $body_max_results, start_time_filter: $start_time_filter, status_filter: $status_filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the data source connectors that you have created.
#
# POST /
# Returns: record<SummaryItems: table<Name: string, Id: string, Type: string, CreatedAt: string, UpdatedAt: string, Status: string, LanguageCode: string>, NextToken: string>
# operationId: ListDataSources
export def "list-data-sources" [
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
  --x-amz-target: string@x-amz-target-completer-39 # required
  index_id: string # The identifier of the index used with one or more data source connectors.
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Kendra returns a pagination token in the response. You can use this pagination token to retrieve the next set of data source connectors. (spec name: NextToken)
  --body-max-results: int # The maximum number of data source connectors to return. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.ListDataSources"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists specific permissions of users and groups with access to your Amazon Kendra experience.
#
# POST /
# Returns: record<SummaryItems: table<EntityId: string, Persona: string, CreatedAt: string, UpdatedAt: string>, NextToken: string>
# operationId: ListEntityPersonas
export def "list-entity-personas" [
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
  --x-amz-target: string@x-amz-target-completer-40 # required
  id: string # The identifier of your Amazon Kendra experience.
  index_id: string # The identifier of the index for your Amazon Kendra experience.
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Kendra returns a pagination token in the response. You can use this pagination token to retrieve the next set of users or groups. (spec name: NextToken)
  --body-max-results: int # The maximum number of returned users or groups. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.ListEntityPersonas"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: IndexId, var: index_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, index_id: $index_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists users or groups in your IAM Identity Center identity source that are granted access to your Amazon Kendra experience. You can create an Amazon Kendra experience such as a search application. For more information on creating a search application experience, see Building a search experience with no code (https://docs.aws.amazon.com/kendra/latest/dg/deploying-search-experience-no-code.html).
#
# POST /
# Returns: record<SummaryItems: table<EntityId: string, EntityType: string, DisplayData: record>, NextToken: string>
# operationId: ListExperienceEntities
export def "list-experience-entities" [
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
  --x-amz-target: string@x-amz-target-completer-41 # required
  id: string # The identifier of your Amazon Kendra experience.
  index_id: string # The identifier of the index for your Amazon Kendra experience.
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Kendra returns a pagination token in the response. You can use this pagination token to retrieve the next set of users or groups. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.ListExperienceEntities"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: IndexId, var: index_id}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, index_id: $index_id, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists one or more Amazon Kendra experiences. You can create an Amazon Kendra experience such as a search application. For more information on creating a search application experience, see Building a search experience with no code (https://docs.aws.amazon.com/kendra/latest/dg/deploying-search-experience-no-code.html).
#
# POST /
# Returns: record<SummaryItems: table<Name: string, Id: string, CreatedAt: string, Status: string, Endpoints: list>, NextToken: string>
# operationId: ListExperiences
export def "list-experiences" [
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
  --x-amz-target: string@x-amz-target-completer-42 # required
  index_id: string # The identifier of the index for your Amazon Kendra experience.
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Kendra returns a pagination token in the response. You can use this pagination token to retrieve the next set of Amazon Kendra experiences. (spec name: NextToken)
  --body-max-results: int # The maximum number of returned Amazon Kendra experiences. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.ListExperiences"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of FAQ lists associated with an index.
#
# POST /
# Returns: record<NextToken: string, FaqSummaryItems: table<Id: string, Name: string, Status: string, CreatedAt: string, UpdatedAt: string, FileFormat: string, LanguageCode: string>>
# operationId: ListFaqs
export def "list-faqs" [
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
  --x-amz-target: string@x-amz-target-completer-43 # required
  index_id: string # The index that contains the FAQ lists.
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Kendra returns a pagination token in the response. You can use this pagination token to retrieve the next set of FAQs. (spec name: NextToken)
  --body-max-results: int # The maximum number of FAQs to return in the response. If there are fewer results in the list, this response contains only the actual results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.ListFaqs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all your sets of featured results for a given index. Features results are placed above all other results for certain queries. If there's an exact match of a query, then one or more specific documents are featured in the search results.
#
# POST /
# Returns: record<FeaturedResultsSetSummaryItems: table<FeaturedResultsSetId: string, FeaturedResultsSetName: string, Status: string, LastUpdatedTimestamp: int, CreationTimestamp: int>, NextToken: string>
# operationId: ListFeaturedResultsSets
export def "list-featured-results-sets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index used for featuring results.
  --next-token: string # If the response is truncated, Amazon Kendra returns a pagination token in the response. You can use this pagination token to retrieve the next set of featured results sets.
  --max-results: int # The maximum number of featured results sets to return.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.ListFeaturedResultsSets"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a list of groups that are mapped to users before a given ordering or timestamp identifier. ListGroupsOlderThanOrderingId is currently not supported in the Amazon Web Services GovCloud (US-West) region.
#
# POST /
# Returns: record<GroupsSummaries: table<GroupId: string, OrderingId: int>, NextToken: string>
# operationId: ListGroupsOlderThanOrderingId
export def "list-groups-older-than-ordering-id" [
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
  --x-amz-target: string@x-amz-target-completer-45 # required
  index_id: string # The identifier of the index for getting a list of groups mapped to users before a given ordering or timestamp identifier.
  --data-source-id: string # The identifier of the data source for getting a list of groups mapped to users before a given ordering timestamp identifier.
  ordering_id: int # The timestamp identifier used for the latest PUT or DELETE action for mapping users to their groups.
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Kendra returns a pagination token in the response. You can use this pagination token to retrieve the next set of groups that are mapped to users before a given ordering or timestamp identifier. (spec name: NextToken)
  --body-max-results: int # The maximum number of returned groups that are mapped to users before a given ordering or timestamp identifier. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.ListGroupsOlderThanOrderingId"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: DataSourceId, var: data_source_id}, {name: OrderingId, var: ordering_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, data_source_id: $data_source_id, ordering_id: $ordering_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Amazon Kendra indexes that you created.
#
# POST /
# Returns: record<IndexConfigurationSummaryItems: table<Name: string, Id: string, Edition: string, CreatedAt: string, UpdatedAt: string, Status: string>, NextToken: string>
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
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-46 # required
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Kendra returns a pagination token in the response. You can use this pagination token to retrieve the next set of indexes. (spec name: NextToken)
  --body-max-results: int # The maximum number of indices to return. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.ListIndices"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the block lists used for query suggestions for an index. For information on the current quota limits for block lists, see Quotas for Amazon Kendra (https://docs.aws.amazon.com/kendra/latest/dg/quotas.html). ListQuerySuggestionsBlockLists is currently not supported in the Amazon Web Services GovCloud (US-West) region.
#
# POST /
# Returns: record<BlockListSummaryItems: table<Id: string, Name: string, Status: string, CreatedAt: string, UpdatedAt: string, ItemCount: int>, NextToken: string>
# operationId: ListQuerySuggestionsBlockLists
export def "list-query-suggestions-block-lists" [
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
  --x-amz-target: string@x-amz-target-completer-47 # required
  index_id: string # The identifier of the index for a list of all block lists that exist for that index. For information on the current quota limits for block lists, see Quotas for Amazon Kendra (https://docs.aws.amazon.com/kendra/latest/dg/quotas.html).
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Kendra returns a pagination token in the response. You can use this pagination token to retrieve the next set of block lists (BlockListSummaryItems). (spec name: NextToken)
  --body-max-results: int # The maximum number of block lists to return. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.ListQuerySuggestionsBlockLists"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of tags associated with a specified resource. Indexes, FAQs, and data sources can have tags associated with them.
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
  --x-amz-target: string@x-amz-target-completer-48 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the index, FAQ, or data source to get a list of tags for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceARN, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the thesauri for an index.
#
# POST /
# Returns: record<NextToken: string, ThesaurusSummaryItems: table<Id: string, Name: string, Status: string, CreatedAt: string, UpdatedAt: string>>
# operationId: ListThesauri
export def "list-thesauri" [
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
  --x-amz-target: string@x-amz-target-completer-49 # required
  index_id: string # The identifier of the index with one or more thesauri.
  --body-next-token: string # If the previous response was incomplete (because there is more data to retrieve), Amazon Kendra returns a pagination token in the response. You can use this pagination token to retrieve the next set of thesauri (ThesaurusSummaryItems). (spec name: NextToken)
  --body-max-results: int # The maximum number of thesauri to return. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.ListThesauri"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Maps users to their groups so that you only need to provide the user ID when you issue the query. You can also map sub groups to groups. For example, the group "Company Intellectual Property Teams" includes sub groups "Research" and "Engineering". These sub groups include their own list of users or people who work in these teams. Only users who work in research and engineering, and therefore belong in the intellectual property group, can see top-secret company documents in their search results. This is useful for user context filtering, where search results are filtered based on the user or their group access to documents. For more information, see Filtering on user context (https://docs.aws.amazon.com/kendra/latest/dg/user-context-filter.html). If more than five PUT actions for a group are currently processing, a validation exception is thrown.
#
# POST /
# operationId: PutPrincipalMapping
export def "put-principal-mapping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index you want to map users to their groups.
  --data-source-id: string # The identifier of the data source you want to map users to their groups. This is useful if a group is tied to multiple data sources, but you only want the group to access documents of a certain data source. For example, the groups "Research", "Engineering", and "Sales and Marketing" are all tied to the company's documents stored in the data sources Confluence and Salesforce. However, "Sales and Marketing" team only needs access to customer-related documents stored in Salesforce.
  group_id: string # The identifier of the group you want to map its users to.
  group_members: record # A list of users or sub groups that belong to a group. This is useful for user context filtering, where search results are filtered based on the user or their group access to documents. — shape: {MemberGroups?: list, MemberUsers?: list, S3PathforGroupMembers?: record}
  --ordering-id: int # The timestamp identifier you specify to ensure Amazon Kendra does not override the latest PUT action with previous actions. The highest number ID, which is the ordering ID, is the latest action you want to process and apply on top of other actions with lower number IDs. This prevents previous actions with lower number IDs from possibly overriding the latest action. The ordering ID can be the Unix time of the last update you made to a group members list. You would then provide this list when calling PutPrincipalMapping. This ensures your PUT action for that updated group with the latest members list doesn't get overwritten by earlier PUT actions for the same group which are yet to be processed. The default ordering ID is the current Unix time in milliseconds that the action was received by Amazon Kendra.
  --role-arn: string # The Amazon Resource Name (ARN) of a role that has access to the S3 file that contains your list of users or sub groups that belong to a group. For more information, see IAM roles for Amazon Kendra (https://docs.aws.amazon.com/kendra/latest/dg/iam-roles.html#iam-roles-ds).
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.PutPrincipalMapping"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: DataSourceId, var: data_source_id}, {name: GroupId, var: group_id}, {name: GroupMembers, var: group_members}, {name: OrderingId, var: ordering_id}, {name: RoleArn, var: role_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, data_source_id: $data_source_id, group_id: $group_id, group_members: $group_members, ordering_id: $ordering_id, role_arn: $role_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches an active index. Use this API to search your documents using query. The Query API enables to do faceted search and to filter results based on document attributes. It also enables you to provide user context that Amazon Kendra uses to enforce document access control in the search results. Amazon Kendra searches your index for text content and question and answer (FAQ) content. By default the response contains three types of results. Relevant passages Matching FAQs Relevant documents You can specify that the query return only one type of result using the QueryResultTypeFilter parameter. Each query returns the 100 most relevant results.
#
# POST /
# Returns: record<QueryId: string, ResultItems: table<Id: string, Type: string, Format: string, AdditionalAttributes: list, DocumentId: string, DocumentTitle: record, DocumentExcerpt: record, DocumentURI: string, DocumentAttributes: list, ScoreAttributes: record, FeedbackToken: string, TableExcerpt: record>, FacetResults: table<DocumentAttributeKey: string, DocumentAttributeValueType: string, DocumentAttributeValueCountPairs: list>, TotalNumberOfResults: int, Warnings: table<Message: string, Code: string>, SpellCorrectedQueries: table<SuggestedQueryText: string, Corrections: list>, FeaturedResultsItems: table<Id: string, Type: string, AdditionalAttributes: list, DocumentId: string, DocumentTitle: record, DocumentExcerpt: record, DocumentURI: string, DocumentAttributes: list, FeedbackToken: string>>
# operationId: Query
export def "query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index to search. The identifier is returned in the response from the CreateIndex API.
  --query-text: string # The input query text for the search. Amazon Kendra truncates queries at 30 token words, which excludes punctuation and stop words. Truncation still applies if you use Boolean or more advanced, complex queries.
  --attribute-filter: record # Provides filtering the query results based on document attributes or metadata fields. When you use the AndAllFilters or OrAllFilters, filters you can use 2 layers under the first attribute filter. For example, you can use: <AndAllFilters> <OrAllFilters> <EqualsTo> If you use more than 2 layers, you receive a ValidationException exception with the message "AttributeFilter cannot have a depth of more than 2." If you use more than 10 attribute filters in a given list for AndAllFilters or OrAllFilters, you receive a ValidationException with the message "AttributeFilter cannot have a length of more than 10". — shape: {AndAllFilters?: list, OrAllFilters?: list, NotFilter?: record, EqualsTo?: record, ContainsAll?: record, ContainsAny?: record, GreaterThan?: record, GreaterThanOrEquals?: record, LessThan?: record, LessThanOrEquals?: record}
  --facets: list # An array of documents attributes. Amazon Kendra returns a count for each attribute key specified. This helps your users narrow their search. — item shape: {DocumentAttributeKey?: string, Facets?: list, MaxResults?: int}
  --requested-document-attributes: list<string> # An array of document attributes to include in the response. You can limit the response to include certain document attributes. By default all document attributes are included in the response.
  --query-result-type-filter: string@query-result-type-filter-completer # Sets the type of query. Only results for the specified query type are returned.
  --document-relevance-override-configurations: list # Overrides relevance tuning configurations of fields or attributes set at the index level. If you use this API to override the relevance tuning configured at the index level, but there is no relevance tuning configured at the index level, then Amazon Kendra does not apply any relevance tuning. If there is relevance tuning configured at the index level, but you do not use this API to override any relevance tuning in the index, then Amazon Kendra uses the relevance tuning that is configured at the index level. If there is relevance tuning configured for fields at the index level, but you use this API to override only some of these fields, then for the fields you did not override, the importance is set to 1. — item shape: {Name: string, Relevance: record}
  --page-number: int # Query results are returned in pages the size of the PageSize parameter. By default, Amazon Kendra returns the first page of results. Use this parameter to get result pages after the first one.
  --page-size: int # Sets the number of results that are returned in each page of results. The default page size is 10. The maximum number of results returned is 100. If you ask for more than 100 results, only 100 are returned.
  --sorting-configuration: record # Specifies the document attribute to use to sort the response to a Amazon Kendra query. You can specify a single attribute for sorting. The attribute must have the Sortable flag set to true, otherwise Amazon Kendra returns an exception. You can sort attributes of the following types. Date value Long value String value You can't sort attributes of the following type. String list value — shape: {DocumentAttributeKey: string, SortOrder: "DESC"|"ASC"}
  --user-context: record # Provides information about the user context for an Amazon Kendra index. User context filtering is a kind of personalized search with the benefit of controlling access to documents. For example, not all teams that search the company portal for information should access top-secret company documents, nor are these documents relevant to all users. Only specific users or groups of teams given access to top-secret documents should see these documents in their search results. You provide one of the following: User token User ID, the groups the user belongs to, and any data sources the groups can access. If you provide both, an exception is thrown. — shape: {Token?: string, UserId?: string, Groups?: list<string>, DataSourceGroups?: list}
  --visitor-id: string # Provides an identifier for a specific user. The VisitorId should be a unique identifier, such as a GUID. Don't use personally identifiable information, such as the user's email address, as the VisitorId.
  --spell-correction-configuration: record # Provides the configuration information for suggested query spell corrections. Suggested spell corrections are based on words that appear in your indexed documents and how closely a corrected word matches a misspelled word. This feature is designed with certain defaults or limits. For information on the current limits and how to request more support for some limits, see the Spell Checker documentation (https://docs.aws.amazon.com/kendra/latest/dg/query-spell-check.html). — shape: {IncludeQuerySpellCheckSuggestions: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.Query"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: QueryText, var: query_text}, {name: AttributeFilter, var: attribute_filter}, {name: Facets, var: facets}, {name: RequestedDocumentAttributes, var: requested_document_attributes}, {name: QueryResultTypeFilter, var: query_result_type_filter}, {name: DocumentRelevanceOverrideConfigurations, var: document_relevance_override_configurations}, {name: PageNumber, var: page_number}, {name: PageSize, var: page_size}, {name: SortingConfiguration, var: sorting_configuration}, {name: UserContext, var: user_context}, {name: VisitorId, var: visitor_id}, {name: SpellCorrectionConfiguration, var: spell_correction_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, query_text: $query_text, attribute_filter: $attribute_filter, facets: $facets, requested_document_attributes: $requested_document_attributes, query_result_type_filter: $query_result_type_filter, document_relevance_override_configurations: $document_relevance_override_configurations, page_number: $page_number, page_size: $page_size, sorting_configuration: $sorting_configuration, user_context: $user_context, visitor_id: $visitor_id, spell_correction_configuration: $spell_correction_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a synchronization job for a data source connector. If a synchronization job is already in progress, Amazon Kendra returns a ResourceInUseException exception.
#
# POST /
# Returns: record<ExecutionId: string>
# operationId: StartDataSourceSyncJob
export def "start-data-source-sync-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of the data source connector to synchronize.
  index_id: string # The identifier of the index used with the data source connector.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.StartDataSourceSyncJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: IndexId, var: index_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, index_id: $index_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a synchronization job that is currently running. You can't stop a scheduled synchronization job.
#
# POST /
# operationId: StopDataSourceSyncJob
export def "stop-data-source-sync-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of the data source connector for which to stop the synchronization jobs.
  index_id: string # The identifier of the index used with the data source connector.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.StopDataSourceSyncJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: IndexId, var: index_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, index_id: $index_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables you to provide feedback to Amazon Kendra to improve the performance of your index. SubmitFeedback is currently not supported in the Amazon Web Services GovCloud (US-West) region.
#
# POST /
# operationId: SubmitFeedback
export def "submit-feedback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index that was queried.
  query_id: string # The identifier of the specific query for which you are submitting feedback. The query ID is returned in the response to the Query API.
  --click-feedback-items: list # Tells Amazon Kendra that a particular search result link was chosen by the user. — item shape: {ResultId: string, ClickTime: string}
  --relevance-feedback-items: list # Provides Amazon Kendra with relevant or not relevant feedback for whether a particular item was relevant to the search. — item shape: {ResultId: string, RelevanceValue: "RELEVANT"|"NOT_RELEVANT"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.SubmitFeedback"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: QueryId, var: query_id}, {name: ClickFeedbackItems, var: click_feedback_items}, {name: RelevanceFeedbackItems, var: relevance_feedback_items}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, query_id: $query_id, click_feedback_items: $click_feedback_items, relevance_feedback_items: $relevance_feedback_items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds the specified tag to the specified index, FAQ, or data source resource. If the tag already exists, the existing value is replaced with the new value.
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
  --x-amz-target: string@x-amz-target-completer-55 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the index, FAQ, or data source to tag.
  tags: list # A list of tag keys to add to the index, FAQ, or data source. If a tag already exists, the existing value is replaced with the new value. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceARN, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a tag from an index, FAQ, or a data source.
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
  --x-amz-target: string@x-amz-target-completer-56 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the index, FAQ, or data source to remove the tag from.
  tag_keys: list<string> # A list of tag keys to remove from the index, FAQ, or data source. If a tag key does not exist on the resource, it is ignored.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceARN, var: resource_arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an access control configuration for your documents in an index. This includes user and group access information for your documents. This is useful for user context filtering, where search results are filtered based on the user or their group access to documents. You can update an access control configuration you created without indexing all of your documents again. For example, your index contains top-secret company documents that only certain employees or users should access. You created an 'allow' access control configuration for one user who recently joined the 'top-secret' team, switching from a team with 'deny' access to top-secret documents. However, the user suddenly returns to their previous team and should no longer have access to top secret documents. You can update the access control configuration to re-configure access control for your documents as circumstances change. You call the BatchPutDocument (https://docs.aws.amazon.com/kendra/latest/dg/API_BatchPutDocument.html) API to apply the updated access control configuration, with the AccessControlConfigurationId included in the Document (https://docs.aws.amazon.com/kendra/latest/dg/API_Document.html) object. If you use an S3 bucket as a data source, you synchronize your data source to apply the AccessControlConfigurationId in the .metadata.json file. Amazon Kendra currently only supports access control configuration for S3 data sources and documents indexed using the BatchPutDocument API.
#
# POST /
# Returns: record
# operationId: UpdateAccessControlConfiguration
export def "update-access-control-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index for an access control configuration.
  id: string # The identifier of the access control configuration you want to update.
  --name: string # A new name for the access control configuration.
  --description: string # A new description for the access control configuration.
  --access-control-list: list # Information you want to update on principals (users and/or groups) and which documents they should have access to. This is useful for user context filtering, where search results are filtered based on the user or their group access to documents. — item shape: {Name: string, Type: "USER"|"GROUP", Access: "ALLOW"|"DENY", DataSourceId?: string}
  --hierarchical-access-control-list: list # A list of principal (https://docs.aws.amazon.com/kendra/latest/dg/API_Principal.html) lists that define the hierarchy for which documents users should have access to. Each hierarchical list specifies which user or group has allow or deny access for each document. — item shape: {PrincipalList: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.UpdateAccessControlConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: Id, var: id}, {name: Name, var: name}, {name: Description, var: description}, {name: AccessControlList, var: access_control_list}, {name: HierarchicalAccessControlList, var: hierarchical_access_control_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, id: $id, name: $name, description: $description, access_control_list: $access_control_list, hierarchical_access_control_list: $hierarchical_access_control_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Amazon Kendra data source connector.
#
# POST /
# operationId: UpdateDataSource
export def "update-data-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of the data source connector you want to update.
  --name: string # A new name for the data source connector.
  index_id: string # The identifier of the index used with the data source connector.
  --configuration: record # Provides the configuration information for an Amazon Kendra data source. — shape: {S3Configuration?: record, SharePointConfiguration?: record, DatabaseConfiguration?: record, SalesforceConfiguration?: record, OneDriveConfiguration?: record, ServiceNowConfiguration?: record, ConfluenceConfiguration?: record, GoogleDriveConfiguration?: record, WebCrawlerConfiguration?: record, WorkDocsConfiguration?: record, FsxConfiguration?: record, SlackConfiguration?: record, BoxConfiguration?: record, QuipConfiguration?: record, JiraConfiguration?: record, GitHubConfiguration?: record, ... (2 more fields)}
  --vpc-configuration: record # Provides the configuration information to connect to an Amazon VPC. — shape: {SubnetIds: list<string>, SecurityGroupIds: list<string>}
  --description: string # A new description for the data source connector.
  --schedule: string # The sync schedule you want to update for the data source connector.
  --role-arn: string # The Amazon Resource Name (ARN) of a role with permission to access the data source and required resources. For more information, see IAM roles for Amazon Kendra (https://docs.aws.amazon.com/kendra/latest/dg/iam-roles.html).
  --language-code: string # The code for a language. The default language is English. For more information on supported languages, including their codes, see Adding documents in languages other than English (https://docs.aws.amazon.com/kendra/latest/dg/in-adding-languages.html).
  --custom-document-enrichment-configuration: record # Provides the configuration information for altering document metadata and content during the document ingestion process. For more information, see Customizing document metadata during the ingestion process (https://docs.aws.amazon.com/kendra/latest/dg/custom-document-enrichment.html). — shape: {InlineConfigurations?: list, PreExtractionHookConfiguration?: record, PostExtractionHookConfiguration?: record, RoleArn?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.UpdateDataSource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: Name, var: name}, {name: IndexId, var: index_id}, {name: Configuration, var: configuration}, {name: VpcConfiguration, var: vpc_configuration}, {name: Description, var: description}, {name: Schedule, var: schedule}, {name: RoleArn, var: role_arn}, {name: LanguageCode, var: language_code}, {name: CustomDocumentEnrichmentConfiguration, var: custom_document_enrichment_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, name: $name, index_id: $index_id, configuration: $configuration, vpc_configuration: $vpc_configuration, description: $description, schedule: $schedule, role_arn: $role_arn, language_code: $language_code, custom_document_enrichment_configuration: $custom_document_enrichment_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates your Amazon Kendra experience such as a search application. For more information on creating a search application experience, see Building a search experience with no code (https://docs.aws.amazon.com/kendra/latest/dg/deploying-search-experience-no-code.html).
#
# POST /
# operationId: UpdateExperience
export def "update-experience" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of your Amazon Kendra experience you want to update.
  --name: string # A new name for your Amazon Kendra experience.
  index_id: string # The identifier of the index for your Amazon Kendra experience.
  --role-arn: string # The Amazon Resource Name (ARN) of a role with permission to access Query API, QuerySuggestions API, SubmitFeedback API, and IAM Identity Center that stores your user and group information. For more information, see IAM roles for Amazon Kendra (https://docs.aws.amazon.com/kendra/latest/dg/iam-roles.html).
  --configuration: record # Provides the configuration information for your Amazon Kendra experience. This includes the data source IDs and/or FAQ IDs, and user or group information to grant access to your Amazon Kendra experience. — shape: {ContentSourceConfiguration?: record, UserIdentityConfiguration?: record}
  --description: string # A new description for your Amazon Kendra experience.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.UpdateExperience"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: Name, var: name}, {name: IndexId, var: index_id}, {name: RoleArn, var: role_arn}, {name: Configuration, var: configuration}, {name: Description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, name: $name, index_id: $index_id, role_arn: $role_arn, configuration: $configuration, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a set of featured results. Features results are placed above all other results for certain queries. You map specific queries to specific documents for featuring in the results. If a query contains an exact match of a query, then one or more specific documents are featured in the search results.
#
# POST /
# Returns: record<FeaturedResultsSet: record<FeaturedResultsSetId: string, FeaturedResultsSetName: string, Description: string, Status: string, QueryTexts: list<string>, FeaturedDocuments: list<record>, LastUpdatedTimestamp: int, CreationTimestamp: int>>
# operationId: UpdateFeaturedResultsSet
export def "update-featured-results-set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index used for featuring results.
  featured_results_set_id: string # The identifier of the index used for featuring results.
  --featured-results-set-name: string # A new name for the set of featured results.
  --description: string # A new description for the set of featured results.
  --status: string@status-completer # You can set the status to ACTIVE or INACTIVE. When the value is ACTIVE, featured results are ready for use. You can still configure your settings before setting the status to ACTIVE. The queries you specify for featured results must be unique per featured results set for each index, whether the status is ACTIVE or INACTIVE.
  --query-texts: list<string> # A list of queries for featuring results. For more information on the list of queries, see FeaturedResultsSet (https://docs.aws.amazon.com/kendra/latest/dg/API_FeaturedResultsSet.html).
  --featured-documents: list # A list of document IDs for the documents you want to feature at the top of the search results page. For more information on the list of featured documents, see FeaturedResultsSet (https://docs.aws.amazon.com/kendra/latest/dg/API_FeaturedResultsSet.html). — item shape: {Id?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.UpdateFeaturedResultsSet"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: FeaturedResultsSetId, var: featured_results_set_id}, {name: FeaturedResultsSetName, var: featured_results_set_name}, {name: Description, var: description}, {name: Status, var: status}, {name: QueryTexts, var: query_texts}, {name: FeaturedDocuments, var: featured_documents}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, featured_results_set_id: $featured_results_set_id, featured_results_set_name: $featured_results_set_name, description: $description, status: $status, query_texts: $query_texts, featured_documents: $featured_documents
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Amazon Kendra index.
#
# POST /
# operationId: UpdateIndex
export def "update-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of the index you want to update.
  --name: string # The name of the index you want to update.
  --role-arn: string # An Identity and Access Management (IAM) role that gives Amazon Kendra permission to access Amazon CloudWatch logs and metrics.
  --description: string # A new description for the index.
  --document-metadata-configuration-updates: list # The document metadata configuration you want to update for the index. Document metadata are fields or attributes associated with your documents. For example, the company department name associated with each document. — item shape: {Name: string, Type: "STRING_VALUE"|"STRING_LIST_VALUE"|"LONG_VALUE"|"DATE_VALUE", Relevance?: record, Search?: record}
  --capacity-units: record # Specifies additional capacity units configured for your Enterprise Edition index. You can add and remove capacity units to fit your usage requirements. — shape: {StorageCapacityUnits: int, QueryCapacityUnits: int}
  --user-token-configurations: list # The user token configuration. — item shape: {JwtTokenTypeConfiguration?: record, JsonTokenTypeConfiguration?: record}
  --user-context-policy: string@user-context-policy-completer # The user context policy.
  --user-group-resolution-configuration: record # Provides the configuration information to get users and groups from an IAM Identity Center (successor to Single Sign-On) identity source. This is useful for user context filtering, where search results are filtered based on the user or their group access to documents. You can also use the PutPrincipalMapping (https://docs.aws.amazon.com/kendra/latest/dg/API_PutPrincipalMapping.html) API to map users to their groups so that you only need to provide the user ID when you issue the query. To set up an IAM Identity Center identity source in the console to use with Amazon Kendra, see Getting started with an IAM Identity Center identity source (https://docs.aws.amazon.com/kendra/latest/dg/getting-started-aws-sso.html). You must also grant the required permissions to use IAM Identity Center with Amazon Kendra. For more information, see IAM roles for IAM Identity Center (https://docs.aws.amazon.com/kendra/latest/dg/iam-roles.html#iam-roles-aws-sso). Amazon Kendra currently does not support using UserGroupResolutionConfiguration with an Amazon Web Services organization member account for your IAM Identity Center identify source. You must create your index in the management account for the organization in order to use UserGroupResolutionConfiguration. — shape: {UserGroupResolutionMode: "AWS_SSO"|"NONE"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.UpdateIndex"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: Name, var: name}, {name: RoleArn, var: role_arn}, {name: Description, var: description}, {name: DocumentMetadataConfigurationUpdates, var: document_metadata_configuration_updates}, {name: CapacityUnits, var: capacity_units}, {name: UserTokenConfigurations, var: user_token_configurations}, {name: UserContextPolicy, var: user_context_policy}, {name: UserGroupResolutionConfiguration, var: user_group_resolution_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, name: $name, role_arn: $role_arn, description: $description, document_metadata_configuration_updates: $document_metadata_configuration_updates, capacity_units: $capacity_units, user_token_configurations: $user_token_configurations, user_context_policy: $user_context_policy, user_group_resolution_configuration: $user_group_resolution_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a block list used for query suggestions for an index. Updates to a block list might not take effect right away. Amazon Kendra needs to refresh the entire suggestions list to apply any updates to the block list. Other changes not related to the block list apply immediately. If a block list is updating, then you need to wait for the first update to finish before submitting another update. Amazon Kendra supports partial updates, so you only need to provide the fields you want to update. UpdateQuerySuggestionsBlockList is currently not supported in the Amazon Web Services GovCloud (US-West) region.
#
# POST /
# operationId: UpdateQuerySuggestionsBlockList
export def "update-query-suggestions-block-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index for the block list.
  id: string # The identifier of the block list you want to update.
  --name: string # A new name for the block list.
  --description: string # A new description for the block list.
  --source-s3-path: record # Information required to find a specific file in an Amazon S3 bucket. — shape: {Bucket: string, Key: string}
  --role-arn: string # The IAM (Identity and Access Management) role used to access the block list text file in S3.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.UpdateQuerySuggestionsBlockList"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: Id, var: id}, {name: Name, var: name}, {name: Description, var: description}, {name: SourceS3Path, var: source_s3_path}, {name: RoleArn, var: role_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, id: $id, name: $name, description: $description, source_s3_path: $source_s3_path, role_arn: $role_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the settings of query suggestions for an index. Amazon Kendra supports partial updates, so you only need to provide the fields you want to update. If an update is currently processing (i.e. 'happening'), you need to wait for the update to finish before making another update. Updates to query suggestions settings might not take effect right away. The time for your updated settings to take effect depends on the updates made and the number of search queries in your index. You can still enable/disable query suggestions at any time. UpdateQuerySuggestionsConfig is currently not supported in the Amazon Web Services GovCloud (US-West) region.
#
# POST /
# operationId: UpdateQuerySuggestionsConfig
export def "update-query-suggestions-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  index_id: string # The identifier of the index with query suggestions you want to update.
  --mode: string@mode-completer # Set the mode to ENABLED or LEARN_ONLY. By default, Amazon Kendra enables query suggestions. LEARN_ONLY mode allows you to turn off query suggestions. You can to update this at any time. In LEARN_ONLY mode, Amazon Kendra continues to learn from new queries to keep suggestions up to date for when you are ready to switch to ENABLED mode again.
  --query-log-look-back-window-in-days: int # How recent your queries are in your query log time window. The time window is the number of days from current day to past days. By default, Amazon Kendra sets this to 180.
  --include-queries-without-user-information: oneof<nothing, bool> # TRUE to include queries without user information (i.e. all queries, irrespective of the user), otherwise FALSE to only include queries with user information. If you pass user information to Amazon Kendra along with the queries, you can set this flag to FALSE and instruct Amazon Kendra to only consider queries with user information. If you set to FALSE, Amazon Kendra only considers queries searched at least MinimumQueryCount times across MinimumNumberOfQueryingUsers unique users for suggestions. If you set to TRUE, Amazon Kendra ignores all user information and learns from all queries.
  --minimum-number-of-querying-users: int # The minimum number of unique users who must search a query in order for the query to be eligible to suggest to your users. Increasing this number might decrease the number of suggestions. However, this ensures a query is searched by many users and is truly popular to suggest to users. How you tune this setting depends on your specific needs.
  --minimum-query-count: int # The the minimum number of times a query must be searched in order to be eligible to suggest to your users. Decreasing this number increases the number of suggestions. However, this affects the quality of suggestions as it sets a low bar for a query to be considered popular to suggest to users. How you tune this setting depends on your specific needs.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.UpdateQuerySuggestionsConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IndexId, var: index_id}, {name: Mode, var: mode}, {name: QueryLogLookBackWindowInDays, var: query_log_look_back_window_in_days}, {name: IncludeQueriesWithoutUserInformation, var: include_queries_without_user_information}, {name: MinimumNumberOfQueryingUsers, var: minimum_number_of_querying_users}, {name: MinimumQueryCount, var: minimum_query_count}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, index_id: $index_id, mode: $mode, query_log_look_back_window_in_days: $query_log_look_back_window_in_days, include_queries_without_user_information: $include_queries_without_user_information, minimum_number_of_querying_users: $minimum_number_of_querying_users, minimum_query_count: $minimum_query_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a thesaurus for an index.
#
# POST /
# operationId: UpdateThesaurus
export def "update-thesaurus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of the thesaurus you want to update.
  --name: string # A new name for the thesaurus.
  index_id: string # The identifier of the index for the thesaurus.
  --description: string # A new description for the thesaurus.
  --role-arn: string # An IAM role that gives Amazon Kendra permissions to access thesaurus file specified in SourceS3Path.
  --source-s3-path: record # Information required to find a specific file in an Amazon S3 bucket. — shape: {Bucket: string, Key: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSKendraFrontendService.UpdateThesaurus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: Name, var: name}, {name: IndexId, var: index_id}, {name: Description, var: description}, {name: RoleArn, var: role_arn}, {name: SourceS3Path, var: source_s3_path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, name: $name, index_id: $index_id, description: $description, role_arn: $role_arn, source_s3_path: $source_s3_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
