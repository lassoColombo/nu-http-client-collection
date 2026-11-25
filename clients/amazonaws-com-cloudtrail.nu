# Auto-generated client for AWS CloudTrail v2013-11-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/cloudtrail/2013-11-01/openapi.json
# Auth: --token flag or $env.AWS_CLOUDTRAIL_TOKEN

const CLIENT = {
  base_url: "http://cloudtrail.us-east-1.amazonaws.com"
  token_env_var: "AWS_CLOUDTRAIL_TOKEN"
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

def base-url-completer [] { ["http://cloudtrail.us-east-1.amazonaws.com" "http://cloudtrail.us-east-2.amazonaws.com" "http://cloudtrail.us-west-1.amazonaws.com" "http://cloudtrail.us-west-2.amazonaws.com" "http://cloudtrail.us-gov-west-1.amazonaws.com" "http://cloudtrail.us-gov-east-1.amazonaws.com" "http://cloudtrail.ca-central-1.amazonaws.com" "http://cloudtrail.eu-north-1.amazonaws.com" "http://cloudtrail.eu-west-1.amazonaws.com" "http://cloudtrail.eu-west-2.amazonaws.com" "http://cloudtrail.eu-west-3.amazonaws.com" "http://cloudtrail.eu-central-1.amazonaws.com" "http://cloudtrail.eu-south-1.amazonaws.com" "http://cloudtrail.af-south-1.amazonaws.com" "http://cloudtrail.ap-northeast-1.amazonaws.com" "http://cloudtrail.ap-northeast-2.amazonaws.com" "http://cloudtrail.ap-northeast-3.amazonaws.com" "http://cloudtrail.ap-southeast-1.amazonaws.com" "http://cloudtrail.ap-southeast-2.amazonaws.com" "http://cloudtrail.ap-east-1.amazonaws.com" "http://cloudtrail.ap-south-1.amazonaws.com" "http://cloudtrail.sa-east-1.amazonaws.com" "http://cloudtrail.me-south-1.amazonaws.com" "https://cloudtrail.us-east-1.amazonaws.com" "https://cloudtrail.us-east-2.amazonaws.com" "https://cloudtrail.us-west-1.amazonaws.com" "https://cloudtrail.us-west-2.amazonaws.com" "https://cloudtrail.us-gov-west-1.amazonaws.com" "https://cloudtrail.us-gov-east-1.amazonaws.com" "https://cloudtrail.ca-central-1.amazonaws.com" "https://cloudtrail.eu-north-1.amazonaws.com" "https://cloudtrail.eu-west-1.amazonaws.com" "https://cloudtrail.eu-west-2.amazonaws.com" "https://cloudtrail.eu-west-3.amazonaws.com" "https://cloudtrail.eu-central-1.amazonaws.com" "https://cloudtrail.eu-south-1.amazonaws.com" "https://cloudtrail.af-south-1.amazonaws.com" "https://cloudtrail.ap-northeast-1.amazonaws.com" "https://cloudtrail.ap-northeast-2.amazonaws.com" "https://cloudtrail.ap-northeast-3.amazonaws.com" "https://cloudtrail.ap-southeast-1.amazonaws.com" "https://cloudtrail.ap-southeast-2.amazonaws.com" "https://cloudtrail.ap-east-1.amazonaws.com" "https://cloudtrail.ap-south-1.amazonaws.com" "https://cloudtrail.sa-east-1.amazonaws.com" "https://cloudtrail.me-south-1.amazonaws.com" "http://cloudtrail.cn-north-1.amazonaws.com.cn" "http://cloudtrail.cn-northwest-1.amazonaws.com.cn" "https://cloudtrail.cn-north-1.amazonaws.com.cn" "https://cloudtrail.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.AddTags"] }
def x-amz-target-completer-1 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.CancelQuery"] }
def x-amz-target-completer-2 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.CreateChannel"] }
def x-amz-target-completer-3 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.CreateEventDataStore"] }
def x-amz-target-completer-4 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.CreateTrail"] }
def x-amz-target-completer-5 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DeleteChannel"] }
def x-amz-target-completer-6 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DeleteEventDataStore"] }
def x-amz-target-completer-7 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DeleteResourcePolicy"] }
def x-amz-target-completer-8 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DeleteTrail"] }
def x-amz-target-completer-9 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DeregisterOrganizationDelegatedAdmin"] }
def x-amz-target-completer-10 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DescribeQuery"] }
def x-amz-target-completer-11 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DescribeTrails"] }
def x-amz-target-completer-12 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetChannel"] }
def x-amz-target-completer-13 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetEventDataStore"] }
def x-amz-target-completer-14 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetEventSelectors"] }
def x-amz-target-completer-15 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetImport"] }
def x-amz-target-completer-16 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetInsightSelectors"] }
def x-amz-target-completer-17 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetQueryResults"] }
def x-amz-target-completer-18 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetResourcePolicy"] }
def x-amz-target-completer-19 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetTrail"] }
def x-amz-target-completer-20 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetTrailStatus"] }
def x-amz-target-completer-21 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListChannels"] }
def x-amz-target-completer-22 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListEventDataStores"] }
def x-amz-target-completer-23 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListImportFailures"] }
def import-status-completer [] { ["COMPLETED" "FAILED" "INITIALIZING" "IN_PROGRESS" "STOPPED"] }
def x-amz-target-completer-24 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListImports"] }
def x-amz-target-completer-25 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListPublicKeys"] }
def query-status-completer [] { ["CANCELLED" "FAILED" "FINISHED" "QUEUED" "RUNNING" "TIMED_OUT"] }
def x-amz-target-completer-26 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListQueries"] }
def x-amz-target-completer-27 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListTags"] }
def x-amz-target-completer-28 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListTrails"] }
def event-category-completer [] { ["insight"] }
def x-amz-target-completer-29 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.LookupEvents"] }
def x-amz-target-completer-30 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.PutEventSelectors"] }
def x-amz-target-completer-31 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.PutInsightSelectors"] }
def x-amz-target-completer-32 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.PutResourcePolicy"] }
def x-amz-target-completer-33 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.RegisterOrganizationDelegatedAdmin"] }
def x-amz-target-completer-34 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.RemoveTags"] }
def x-amz-target-completer-35 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.RestoreEventDataStore"] }
def x-amz-target-completer-36 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.StartImport"] }
def x-amz-target-completer-37 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.StartLogging"] }
def x-amz-target-completer-38 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.StartQuery"] }
def x-amz-target-completer-39 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.StopImport"] }
def x-amz-target-completer-40 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.StopLogging"] }
def x-amz-target-completer-41 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.UpdateChannel"] }
def x-amz-target-completer-42 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.UpdateEventDataStore"] }
def x-amz-target-completer-43 [] { ["com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.UpdateTrail"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    add-tags: "record"
    cancel-query: "record<QueryId: string, QueryStatus: string>"
    create-channel: "record<ChannelArn: string, Name: string, Source: string, Destinations: table<Type: string, Location: string>, Tags: table<Key: string, Value: string>>"
    create-event-data-store: "record<EventDataStoreArn: string, Name: string, Status: string, AdvancedEventSelectors: table<Name: string, FieldSelectors: list>, MultiRegionEnabled: bool, OrganizationEnabled: bool, RetentionPeriod: int, TerminationProtectionEnabled: bool, TagsList: table<Key: string, Value: string>, CreatedTimestamp: string, UpdatedTimestamp: string, KmsKeyId: string>"
    create-trail: "record<Name: string, S3BucketName: string, S3KeyPrefix: string, SnsTopicName: string, SnsTopicARN: string, IncludeGlobalServiceEvents: bool, IsMultiRegionTrail: bool, TrailARN: string, LogFileValidationEnabled: bool, CloudWatchLogsLogGroupArn: string, CloudWatchLogsRoleArn: string, KmsKeyId: string, IsOrganizationTrail: bool>"
    delete-channel: "record"
    delete-event-data-store: "record"
    delete-resource-policy: "record"
    delete-trail: "record"
    deregister-organization-delegated-admin: "record"
    describe-query: "record<QueryId: string, QueryString: string, QueryStatus: string, QueryStatistics: record<EventsMatched: int, EventsScanned: int, BytesScanned: int, ExecutionTimeInMillis: int, CreationTime: string>, ErrorMessage: string, DeliveryS3Uri: string, DeliveryStatus: string>"
    describe-trails: "record<trailList: table<Name: string, S3BucketName: string, S3KeyPrefix: string, SnsTopicName: string, SnsTopicARN: string, IncludeGlobalServiceEvents: bool, IsMultiRegionTrail: bool, HomeRegion: string, TrailARN: string, LogFileValidationEnabled: bool, CloudWatchLogsLogGroupArn: string, CloudWatchLogsRoleArn: string, KmsKeyId: string, HasCustomEventSelectors: bool, HasInsightSelectors: bool, IsOrganizationTrail: bool>>"
    get-channel: "record<ChannelArn: string, Name: string, Source: string, SourceConfig: record<ApplyToAllRegions: bool, AdvancedEventSelectors: list<record>>, Destinations: table<Type: string, Location: string>, IngestionStatus: record<LatestIngestionSuccessTime: string, LatestIngestionSuccessEventID: string, LatestIngestionErrorCode: string, LatestIngestionAttemptTime: string, LatestIngestionAttemptEventID: string>>"
    get-event-data-store: "record<EventDataStoreArn: string, Name: string, Status: string, AdvancedEventSelectors: table<Name: string, FieldSelectors: list>, MultiRegionEnabled: bool, OrganizationEnabled: bool, RetentionPeriod: int, TerminationProtectionEnabled: bool, CreatedTimestamp: string, UpdatedTimestamp: string, KmsKeyId: string>"
    get-event-selectors: "record<TrailARN: string, EventSelectors: table<ReadWriteType: string, IncludeManagementEvents: bool, DataResources: list, ExcludeManagementEventSources: list>, AdvancedEventSelectors: table<Name: string, FieldSelectors: list>>"
    get-import: "record<ImportId: string, Destinations: list<string>, ImportSource: record<S3: record<S3LocationUri: string, S3BucketRegion: string, S3BucketAccessRoleArn: string>>, StartEventTime: string, EndEventTime: string, ImportStatus: string, CreatedTimestamp: string, UpdatedTimestamp: string, ImportStatistics: record<PrefixesFound: int, PrefixesCompleted: int, FilesCompleted: int, EventsCompleted: int, FailedEntries: int>>"
    get-insight-selectors: "record<TrailARN: string, InsightSelectors: table<InsightType: string>>"
    get-query-results: "record<QueryStatus: string, QueryStatistics: record<ResultsCount: int, TotalResultsCount: int, BytesScanned: int>, QueryResultRows: list<list<record>>, NextToken: string, ErrorMessage: string>"
    get-resource-policy: "record<ResourceArn: string, ResourcePolicy: string>"
    get-trail: "record<Trail: record<Name: string, S3BucketName: string, S3KeyPrefix: string, SnsTopicName: string, SnsTopicARN: string, IncludeGlobalServiceEvents: bool, IsMultiRegionTrail: bool, HomeRegion: string, TrailARN: string, LogFileValidationEnabled: bool, CloudWatchLogsLogGroupArn: string, CloudWatchLogsRoleArn: string, KmsKeyId: string, HasCustomEventSelectors: bool, HasInsightSelectors: bool, IsOrganizationTrail: bool>>"
    get-trail-status: "record<IsLogging: bool, LatestDeliveryError: string, LatestNotificationError: string, LatestDeliveryTime: string, LatestNotificationTime: string, StartLoggingTime: string, StopLoggingTime: string, LatestCloudWatchLogsDeliveryError: string, LatestCloudWatchLogsDeliveryTime: string, LatestDigestDeliveryTime: string, LatestDigestDeliveryError: string, LatestDeliveryAttemptTime: string, LatestNotificationAttemptTime: string, LatestNotificationAttemptSucceeded: string, LatestDeliveryAttemptSucceeded: string, TimeLoggingStarted: string, TimeLoggingStopped: string>"
    list-channels: "record<Channels: table<ChannelArn: string, Name: string>, NextToken: string>"
    list-event-data-stores: "record<EventDataStores: table<EventDataStoreArn: string, Name: string, TerminationProtectionEnabled: bool, Status: string, AdvancedEventSelectors: list, MultiRegionEnabled: bool, OrganizationEnabled: bool, RetentionPeriod: int, CreatedTimestamp: string, UpdatedTimestamp: string>, NextToken: string>"
    list-import-failures: "record<Failures: table<Location: string, Status: string, ErrorType: string, ErrorMessage: string, LastUpdatedTime: string>, NextToken: string>"
    list-imports: "record<Imports: table<ImportId: string, ImportStatus: string, Destinations: list, CreatedTimestamp: string, UpdatedTimestamp: string>, NextToken: string>"
    list-public-keys: "record<PublicKeyList: table<Value: string, ValidityStartTime: string, ValidityEndTime: string, Fingerprint: string>, NextToken: string>"
    list-queries: "record<Queries: table<QueryId: string, QueryStatus: string, CreationTime: string>, NextToken: string>"
    list-tags: "record<ResourceTagList: table<ResourceId: string, TagsList: list>, NextToken: string>"
    list-trails: "record<Trails: table<TrailARN: string, Name: string, HomeRegion: string>, NextToken: string>"
    lookup-events: "record<Events: table<EventId: string, EventName: string, ReadOnly: string, AccessKeyId: string, EventTime: string, EventSource: string, Username: string, Resources: list, CloudTrailEvent: string>, NextToken: string>"
    put-event-selectors: "record<TrailARN: string, EventSelectors: table<ReadWriteType: string, IncludeManagementEvents: bool, DataResources: list, ExcludeManagementEventSources: list>, AdvancedEventSelectors: table<Name: string, FieldSelectors: list>>"
    put-insight-selectors: "record<TrailARN: string, InsightSelectors: table<InsightType: string>>"
    put-resource-policy: "record<ResourceArn: string, ResourcePolicy: string>"
    register-organization-delegated-admin: "record"
    remove-tags: "record"
    restore-event-data-store: "record<EventDataStoreArn: string, Name: string, Status: string, AdvancedEventSelectors: table<Name: string, FieldSelectors: list>, MultiRegionEnabled: bool, OrganizationEnabled: bool, RetentionPeriod: int, TerminationProtectionEnabled: bool, CreatedTimestamp: string, UpdatedTimestamp: string, KmsKeyId: string>"
    start-import: "record<ImportId: string, Destinations: list<string>, ImportSource: record<S3: record<S3LocationUri: string, S3BucketRegion: string, S3BucketAccessRoleArn: string>>, StartEventTime: string, EndEventTime: string, ImportStatus: string, CreatedTimestamp: string, UpdatedTimestamp: string>"
    start-logging: "record"
    start-query: "record<QueryId: string>"
    stop-import: "record<ImportId: string, ImportSource: record<S3: record<S3LocationUri: string, S3BucketRegion: string, S3BucketAccessRoleArn: string>>, Destinations: list<string>, ImportStatus: string, CreatedTimestamp: string, UpdatedTimestamp: string, StartEventTime: string, EndEventTime: string, ImportStatistics: record<PrefixesFound: int, PrefixesCompleted: int, FilesCompleted: int, EventsCompleted: int, FailedEntries: int>>"
    stop-logging: "record"
    update-channel: "record<ChannelArn: string, Name: string, Source: string, Destinations: table<Type: string, Location: string>>"
    update-event-data-store: "record<EventDataStoreArn: string, Name: string, Status: string, AdvancedEventSelectors: table<Name: string, FieldSelectors: list>, MultiRegionEnabled: bool, OrganizationEnabled: bool, RetentionPeriod: int, TerminationProtectionEnabled: bool, CreatedTimestamp: string, UpdatedTimestamp: string, KmsKeyId: string>"
    update-trail: "record<Name: string, S3BucketName: string, S3KeyPrefix: string, SnsTopicName: string, SnsTopicARN: string, IncludeGlobalServiceEvents: bool, IsMultiRegionTrail: bool, TrailARN: string, LogFileValidationEnabled: bool, CloudWatchLogsLogGroupArn: string, CloudWatchLogsRoleArn: string, KmsKeyId: string, IsOrganizationTrail: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["add-tags" "cancel-query" "create-channel" "create-event-data-store" "create-trail" "delete-channel" "delete-event-data-store" "delete-resource-policy" "delete-trail" "deregister-organization-delegated-admin" "describe-query" "describe-trails" "get-channel" "get-event-data-store" "get-event-selectors" "get-import" "get-insight-selectors" "get-query-results" "get-resource-policy" "get-trail" "get-trail-status" "list-channels" "list-event-data-stores" "list-import-failures" "list-imports" "list-public-keys" "list-queries" "list-tags" "list-trails" "lookup-events" "put-event-selectors" "put-insight-selectors" "put-resource-policy" "register-organization-delegated-admin" "remove-tags" "restore-event-data-store" "start-import" "start-logging" "start-query" "stop-import" "stop-logging" "update-channel" "update-event-data-store" "update-trail" "commands"] | sort) } | get name | first)
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

# Adds one or more tags to a trail, event data store, or channel, up to a limit of 50. Overwrites an existing tag's value when a new value is specified for an existing tag key. Tag key names must be unique; you cannot have two keys with the same name but different values. If you specify a key without a value, the tag will be created with the specified key and a value of null. You can tag a trail or event data store that applies to all Amazon Web Services Regions only from the Region in which the trail or event data store was created (also known as its home region).
#
# POST /
# Returns: record
# operationId: AddTags
export def "add-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_id: string # Specifies the ARN of the trail, event data store, or channel to which one or more tags will be added. The format of a trail ARN is: arn:aws:cloudtrail:us-east-2:123456789012:trail/MyTrail The format of an event data store ARN is: arn:aws:cloudtrail:us-east-2:12345678910:eventdatastore/EXAMPLE-f852-4e8f-8bd1-bcf6cEXAMPLE The format of a channel ARN is: arn:aws:cloudtrail:us-east-2:123456789012:channel/01234567890
  tags_list: list # A list of tags. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.AddTags"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceId, var: resource_id}, {name: TagsList, var: tags_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id: $resource_id, tags_list: $tags_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a query if the query is not in a terminated state, such as CANCELLED, FAILED, TIMED_OUT, or FINISHED. You must specify an ARN value for EventDataStore. The ID of the query that you want to cancel is also required. When you run CancelQuery, the query status might show as CANCELLED even if the operation is not yet finished.
#
# POST /
# Returns: record<QueryId: string, QueryStatus: string>
# operationId: CancelQuery
export def "cancel-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --event-data-store: string # The ARN (or the ID suffix of the ARN) of an event data store on which the specified query is running.EventDataStore is no longer required by CancelQueryRequest
  query_id: string # The ID of the query that you want to cancel. The QueryId comes from the response of a StartQuery operation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.CancelQuery"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EventDataStore, var: event_data_store}, {name: QueryId, var: query_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, event_data_store: $event_data_store, query_id: $query_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a channel for CloudTrail to ingest events from a partner or external source. After you create a channel, a CloudTrail Lake event data store can log events from the partner or source that you specify.
#
# POST /
# Returns: record<ChannelArn: string, Name: string, Source: string, Destinations: table<Type: string, Location: string>, Tags: table<Key: string, Value: string>>
# operationId: CreateChannel
export def "create-channel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the channel.
  source: string # The name of the partner or external event source. You cannot change this name after you create the channel. A maximum of one channel is allowed per source. A source can be either Custom for all valid non-Amazon Web Services events, or the name of a partner event source. For information about the source names for available partners, see Additional information about integration partners (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/query-event-data-store-integration.html#cloudtrail-lake-partner-information) in the CloudTrail User Guide.
  destinations: list # One or more event data stores to which events arriving through a channel will be logged. — item shape: {Type: "EVENT_DATA_STORE"|"AWS_SERVICE", Location: string}
  --tags: list # A list of tags. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.CreateChannel"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Source, var: source}, {name: Destinations, var: destinations}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, source: $source, destinations: $destinations, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new event data store.
#
# POST /
# Returns: record<EventDataStoreArn: string, Name: string, Status: string, AdvancedEventSelectors: table<Name: string, FieldSelectors: list>, MultiRegionEnabled: bool, OrganizationEnabled: bool, RetentionPeriod: int, TerminationProtectionEnabled: bool, TagsList: table<Key: string, Value: string>, CreatedTimestamp: string, UpdatedTimestamp: string, KmsKeyId: string>
# operationId: CreateEventDataStore
export def "create-event-data-store" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the event data store.
  --advanced-event-selectors: list # The advanced event selectors to use to select the events for the data store. You can configure up to five advanced event selectors for each event data store. For more information about how to use advanced event selectors to log CloudTrail events, see Log events by using advanced event selectors (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-data-events-with-cloudtrail.html#creating-data-event-selectors-advanced) in the CloudTrail User Guide. For more information about how to use advanced event selectors to include Config configuration items in your event data store, see Create an event data store for Config configuration items (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/query-lake-cli.html#lake-cli-create-eds-config) in the CloudTrail User Guide. For more information about how to use advanced event selectors to include non-Amazon Web Services events in your event data store, see Create an integration to log events from outside Amazon Web Services (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/query-lake-cli.html#lake-cli-create-integration) in the CloudTrail User Guide. — item shape: {Name?: string, FieldSelectors: list}
  --multi-region-enabled: oneof<nothing, bool> # Specifies whether the event data store includes events from all regions, or only from the region in which the event data store is created.
  --organization-enabled: oneof<nothing, bool> # Specifies whether an event data store collects events logged for an organization in Organizations.
  --retention-period: int # The retention period of the event data store, in days. You can set a retention period of up to 2557 days, the equivalent of seven years.
  --termination-protection-enabled: oneof<nothing, bool> # Specifies whether termination protection is enabled for the event data store. If termination protection is enabled, you cannot delete the event data store until termination protection is disabled.
  --tags-list: list # A list of tags. — item shape: {Key: string, Value?: string}
  --kms-key-id: string # Specifies the KMS key ID to use to encrypt the events delivered by CloudTrail. The value can be an alias name prefixed by alias/, a fully specified ARN to an alias, a fully specified ARN to a key, or a globally unique identifier. Disabling or deleting the KMS key, or removing CloudTrail permissions on the key, prevents CloudTrail from logging events to the event data store, and prevents users from querying the data in the event data store that was encrypted with the key. After you associate an event data store with a KMS key, the KMS key cannot be removed or changed. Before you disable or delete a KMS key that you are using with an event data store, delete or back up your event data store. CloudTrail also supports KMS multi-Region keys. For more information about multi-Region keys, see Using multi-Region keys (https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html) in the Key Management Service Developer Guide. Examples: alias/MyAliasName arn:aws:kms:us-east-2:123456789012:alias/MyAliasName arn:aws:kms:us-east-2:123456789012:key/12345678-1234-1234-1234-123456789012 12345678-1234-1234-1234-123456789012
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.CreateEventDataStore"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: AdvancedEventSelectors, var: advanced_event_selectors}, {name: MultiRegionEnabled, var: multi_region_enabled}, {name: OrganizationEnabled, var: organization_enabled}, {name: RetentionPeriod, var: retention_period}, {name: TerminationProtectionEnabled, var: termination_protection_enabled}, {name: TagsList, var: tags_list}, {name: KmsKeyId, var: kms_key_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, advanced_event_selectors: $advanced_event_selectors, multi_region_enabled: $multi_region_enabled, organization_enabled: $organization_enabled, retention_period: $retention_period, termination_protection_enabled: $termination_protection_enabled, tags_list: $tags_list, kms_key_id: $kms_key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a trail that specifies the settings for delivery of log data to an Amazon S3 bucket.
#
# POST /
# Returns: record<Name: string, S3BucketName: string, S3KeyPrefix: string, SnsTopicName: string, SnsTopicARN: string, IncludeGlobalServiceEvents: bool, IsMultiRegionTrail: bool, TrailARN: string, LogFileValidationEnabled: bool, CloudWatchLogsLogGroupArn: string, CloudWatchLogsRoleArn: string, KmsKeyId: string, IsOrganizationTrail: bool>
# operationId: CreateTrail
export def "create-trail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # Specifies the name of the trail. The name must meet the following requirements: Contain only ASCII letters (a-z, A-Z), numbers (0-9), periods (.), underscores (_), or dashes (-) Start with a letter or number, and end with a letter or number Be between 3 and 128 characters Have no adjacent periods, underscores or dashes. Names like my-_namespace and my--namespace are not valid. Not be in IP address format (for example, 192.168.5.4)
  s3_bucket_name: string # Specifies the name of the Amazon S3 bucket designated for publishing log files. See Amazon S3 Bucket Naming Requirements (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create_trail_naming_policy.html).
  --s3-key-prefix: string # Specifies the Amazon S3 key prefix that comes after the name of the bucket you have designated for log file delivery. For more information, see Finding Your CloudTrail Log Files (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-find-log-files.html). The maximum length is 200 characters.
  --sns-topic-name: string # Specifies the name of the Amazon SNS topic defined for notification of log file delivery. The maximum length is 256 characters.
  --include-global-service-events: oneof<nothing, bool> # Specifies whether the trail is publishing events from global services such as IAM to the log files.
  --is-multi-region-trail: oneof<nothing, bool> # Specifies whether the trail is created in the current region or in all regions. The default is false, which creates a trail only in the region where you are signed in. As a best practice, consider creating trails that log events in all regions.
  --enable-log-file-validation: oneof<nothing, bool> # Specifies whether log file integrity validation is enabled. The default is false. When you disable log file integrity validation, the chain of digest files is broken after one hour. CloudTrail does not create digest files for log files that were delivered during a period in which log file integrity validation was disabled. For example, if you enable log file integrity validation at noon on January 1, disable it at noon on January 2, and re-enable it at noon on January 10, digest files will not be created for the log files delivered from noon on January 2 to noon on January 10. The same applies whenever you stop CloudTrail logging or delete a trail.
  --cloud-watch-logs-log-group-arn: string # Specifies a log group name using an Amazon Resource Name (ARN), a unique identifier that represents the log group to which CloudTrail logs will be delivered. You must use a log group that exists in your account. Not required unless you specify CloudWatchLogsRoleArn.
  --cloud-watch-logs-role-arn: string # Specifies the role for the CloudWatch Logs endpoint to assume to write to a user's log group. You must use a role that exists in your account.
  --kms-key-id: string # Specifies the KMS key ID to use to encrypt the logs delivered by CloudTrail. The value can be an alias name prefixed by alias/, a fully specified ARN to an alias, a fully specified ARN to a key, or a globally unique identifier. CloudTrail also supports KMS multi-Region keys. For more information about multi-Region keys, see Using multi-Region keys (https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html) in the Key Management Service Developer Guide. Examples: alias/MyAliasName arn:aws:kms:us-east-2:123456789012:alias/MyAliasName arn:aws:kms:us-east-2:123456789012:key/12345678-1234-1234-1234-123456789012 12345678-1234-1234-1234-123456789012
  --is-organization-trail: oneof<nothing, bool> # Specifies whether the trail is created for all accounts in an organization in Organizations, or only for the current Amazon Web Services account. The default is false, and cannot be true unless the call is made on behalf of an Amazon Web Services account that is the management account or delegated administrator account for an organization in Organizations.
  --tags-list: list # A list of tags. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.CreateTrail"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: S3BucketName, var: s3_bucket_name}, {name: S3KeyPrefix, var: s3_key_prefix}, {name: SnsTopicName, var: sns_topic_name}, {name: IncludeGlobalServiceEvents, var: include_global_service_events}, {name: IsMultiRegionTrail, var: is_multi_region_trail}, {name: EnableLogFileValidation, var: enable_log_file_validation}, {name: CloudWatchLogsLogGroupArn, var: cloud_watch_logs_log_group_arn}, {name: CloudWatchLogsRoleArn, var: cloud_watch_logs_role_arn}, {name: KmsKeyId, var: kms_key_id}, {name: IsOrganizationTrail, var: is_organization_trail}, {name: TagsList, var: tags_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, s3_bucket_name: $s3_bucket_name, s3_key_prefix: $s3_key_prefix, sns_topic_name: $sns_topic_name, include_global_service_events: $include_global_service_events, is_multi_region_trail: $is_multi_region_trail, enable_log_file_validation: $enable_log_file_validation, cloud_watch_logs_log_group_arn: $cloud_watch_logs_log_group_arn, cloud_watch_logs_role_arn: $cloud_watch_logs_role_arn, kms_key_id: $kms_key_id, is_organization_trail: $is_organization_trail, tags_list: $tags_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a channel.
#
# POST /
# Returns: record
# operationId: DeleteChannel
export def "delete-channel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  channel: string # The ARN or the UUID value of the channel that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DeleteChannel"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Channel, var: channel}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, channel: $channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables the event data store specified by EventDataStore, which accepts an event data store ARN. After you run DeleteEventDataStore, the event data store enters a PENDING_DELETION state, and is automatically deleted after a wait period of seven days. TerminationProtectionEnabled must be set to False on the event data store; this operation cannot work if TerminationProtectionEnabled is True. After you run DeleteEventDataStore on an event data store, you cannot run ListQueries, DescribeQuery, or GetQueryResults on queries that are using an event data store in a PENDING_DELETION state. An event data store in the PENDING_DELETION state does not incur costs.
#
# POST /
# Returns: record
# operationId: DeleteEventDataStore
export def "delete-event-data-store" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  event_data_store: string # The ARN (or the ID suffix of the ARN) of the event data store to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DeleteEventDataStore"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EventDataStore, var: event_data_store}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, event_data_store: $event_data_store
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the resource-based policy attached to the CloudTrail channel.
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
  --x-amz-target: string@x-amz-target-completer-7 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the CloudTrail channel you're deleting the resource-based policy from. The following is the format of a resource ARN: arn:aws:cloudtrail:us-east-2:123456789012:channel/MyChannel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DeleteResourcePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a trail. This operation must be called from the region in which the trail was created. DeleteTrail cannot be called on the shadow trails (replicated trails in other regions) of a trail that is enabled in all regions.
#
# POST /
# Returns: record
# operationId: DeleteTrail
export def "delete-trail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # Specifies the name or the CloudTrail ARN of the trail to be deleted. The following is the format of a trail ARN. arn:aws:cloudtrail:us-east-2:123456789012:trail/MyTrail
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DeleteTrail"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes CloudTrail delegated administrator permissions from a member account in an organization.
#
# POST /
# Returns: record
# operationId: DeregisterOrganizationDelegatedAdmin
export def "deregister-organization-delegated-admin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  delegated_admin_account_id: string # A delegated administrator account ID. This is a member account in an organization that is currently designated as a delegated administrator.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DeregisterOrganizationDelegatedAdmin"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DelegatedAdminAccountId, var: delegated_admin_account_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, delegated_admin_account_id: $delegated_admin_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns metadata about a query, including query run time in milliseconds, number of events scanned and matched, and query status. You must specify an ARN for EventDataStore, and a value for QueryID.
#
# POST /
# Returns: record<QueryId: string, QueryString: string, QueryStatus: string, QueryStatistics: record<EventsMatched: int, EventsScanned: int, BytesScanned: int, ExecutionTimeInMillis: int, CreationTime: string>, ErrorMessage: string, DeliveryS3Uri: string, DeliveryStatus: string>
# operationId: DescribeQuery
export def "describe-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --event-data-store: string # The ARN (or the ID suffix of the ARN) of an event data store on which the specified query was run.EventDataStore is no longer required by DescribeQueryRequest
  query_id: string # The query ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DescribeQuery"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EventDataStore, var: event_data_store}, {name: QueryId, var: query_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, event_data_store: $event_data_store, query_id: $query_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves settings for one or more trails associated with the current region for your account.
#
# POST /
# Returns: record<trailList: table<Name: string, S3BucketName: string, S3KeyPrefix: string, SnsTopicName: string, SnsTopicARN: string, IncludeGlobalServiceEvents: bool, IsMultiRegionTrail: bool, HomeRegion: string, TrailARN: string, LogFileValidationEnabled: bool, CloudWatchLogsLogGroupArn: string, CloudWatchLogsRoleArn: string, KmsKeyId: string, HasCustomEventSelectors: bool, HasInsightSelectors: bool, IsOrganizationTrail: bool>>
# operationId: DescribeTrails
export def "describe-trails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --trail-name-list: list<string> # Specifies a list of trail names, trail ARNs, or both, of the trails to describe. The format of a trail ARN is: arn:aws:cloudtrail:us-east-2:123456789012:trail/MyTrail If an empty list is specified, information for the trail in the current region is returned. If an empty list is specified and IncludeShadowTrails is false, then information for all trails in the current region is returned. If an empty list is specified and IncludeShadowTrails is null or true, then information for all trails in the current region and any associated shadow trails in other regions is returned. If one or more trail names are specified, information is returned only if the names match the names of trails belonging only to the current region and current account. To return information about a trail in another region, you must specify its trail ARN.
  --include-shadow-trails: oneof<nothing, bool> # Specifies whether to include shadow trails in the response. A shadow trail is the replication in a region of a trail that was created in a different region, or in the case of an organization trail, the replication of an organization trail in member accounts. If you do not include shadow trails, organization trails in a member account and region replication trails will not be returned. The default is true.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DescribeTrails"}]
    body: {content_type: "application/json", kind: json, fields: [{name: trailNameList, var: trail_name_list}, {name: includeShadowTrails, var: include_shadow_trails}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, trail_name_list: $trail_name_list, include_shadow_trails: $include_shadow_trails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a specific channel.
#
# POST /
# Returns: record<ChannelArn: string, Name: string, Source: string, SourceConfig: record<ApplyToAllRegions: bool, AdvancedEventSelectors: list<record>>, Destinations: table<Type: string, Location: string>, IngestionStatus: record<LatestIngestionSuccessTime: string, LatestIngestionSuccessEventID: string, LatestIngestionErrorCode: string, LatestIngestionAttemptTime: string, LatestIngestionAttemptEventID: string>>
# operationId: GetChannel
export def "get-channel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  channel: string # The ARN or UUID of a channel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetChannel"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Channel, var: channel}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, channel: $channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about an event data store specified as either an ARN or the ID portion of the ARN.
#
# POST /
# Returns: record<EventDataStoreArn: string, Name: string, Status: string, AdvancedEventSelectors: table<Name: string, FieldSelectors: list>, MultiRegionEnabled: bool, OrganizationEnabled: bool, RetentionPeriod: int, TerminationProtectionEnabled: bool, CreatedTimestamp: string, UpdatedTimestamp: string, KmsKeyId: string>
# operationId: GetEventDataStore
export def "get-event-data-store" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  event_data_store: string # The ARN (or ID suffix of the ARN) of the event data store about which you want information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetEventDataStore"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EventDataStore, var: event_data_store}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, event_data_store: $event_data_store
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the settings for the event selectors that you configured for your trail. The information returned for your event selectors includes the following: If your event selector includes read-only events, write-only events, or all events. This applies to both management events and data events. If your event selector includes management events. If your event selector includes data events, the resources on which you are logging data events. For more information about logging management and data events, see the following topics in the CloudTrail User Guide: Logging management events for trails (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-management-events-with-cloudtrail.html) Logging data events for trails (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-data-events-with-cloudtrail.html)
#
# POST /
# Returns: record<TrailARN: string, EventSelectors: table<ReadWriteType: string, IncludeManagementEvents: bool, DataResources: list, ExcludeManagementEventSources: list>, AdvancedEventSelectors: table<Name: string, FieldSelectors: list>>
# operationId: GetEventSelectors
export def "get-event-selectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  trail_name: string # Specifies the name of the trail or trail ARN. If you specify a trail name, the string must meet the following requirements: Contain only ASCII letters (a-z, A-Z), numbers (0-9), periods (.), underscores (_), or dashes (-) Start with a letter or number, and end with a letter or number Be between 3 and 128 characters Have no adjacent periods, underscores or dashes. Names like my-_namespace and my--namespace are not valid. Not be in IP address format (for example, 192.168.5.4) If you specify a trail ARN, it must be in the format: arn:aws:cloudtrail:us-east-2:123456789012:trail/MyTrail
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetEventSelectors"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TrailName, var: trail_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, trail_name: $trail_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a specific import.
#
# POST /
# Returns: record<ImportId: string, Destinations: list<string>, ImportSource: record<S3: record<S3LocationUri: string, S3BucketRegion: string, S3BucketAccessRoleArn: string>>, StartEventTime: string, EndEventTime: string, ImportStatus: string, CreatedTimestamp: string, UpdatedTimestamp: string, ImportStatistics: record<PrefixesFound: int, PrefixesCompleted: int, FilesCompleted: int, EventsCompleted: int, FailedEntries: int>>
# operationId: GetImport
export def "get-import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  import_id: string # The ID for the import.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetImport"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ImportId, var: import_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, import_id: $import_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the settings for the Insights event selectors that you configured for your trail. GetInsightSelectors shows if CloudTrail Insights event logging is enabled on the trail, and if it is, which insight types are enabled. If you run GetInsightSelectors on a trail that does not have Insights events enabled, the operation throws the exception InsightNotEnabledException For more information, see Logging CloudTrail Insights Events for Trails (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-insights-events-with-cloudtrail.html) in the CloudTrail User Guide.
#
# POST /
# Returns: record<TrailARN: string, InsightSelectors: table<InsightType: string>>
# operationId: GetInsightSelectors
export def "get-insight-selectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  trail_name: string # Specifies the name of the trail or trail ARN. If you specify a trail name, the string must meet the following requirements: Contain only ASCII letters (a-z, A-Z), numbers (0-9), periods (.), underscores (_), or dashes (-) Start with a letter or number, and end with a letter or number Be between 3 and 128 characters Have no adjacent periods, underscores or dashes. Names like my-_namespace and my--namespace are not valid. Not be in IP address format (for example, 192.168.5.4) If you specify a trail ARN, it must be in the format: arn:aws:cloudtrail:us-east-2:123456789012:trail/MyTrail
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetInsightSelectors"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TrailName, var: trail_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, trail_name: $trail_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets event data results of a query. You must specify the QueryID value returned by the StartQuery operation, and an ARN for EventDataStore.
#
# POST /
# Returns: record<QueryStatus: string, QueryStatistics: record<ResultsCount: int, TotalResultsCount: int, BytesScanned: int>, QueryResultRows: list<list<record>>, NextToken: string, ErrorMessage: string>
# operationId: GetQueryResults
export def "get-query-results" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  --event-data-store: string # The ARN (or ID suffix of the ARN) of the event data store against which the query was run.EventDataStore is no longer required by GetQueryResultsRequest
  query_id: string # The ID of the query for which you want to get results.
  --body-next-token: string # A token you can use to get the next page of query results. (spec name: NextToken)
  --max-query-results: int # The maximum number of query results to display on a single page.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetQueryResults"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EventDataStore, var: event_data_store}, {name: QueryId, var: query_id}, {name: NextToken, var: body_next_token}, {name: MaxQueryResults, var: max_query_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, event_data_store: $event_data_store, query_id: $query_id, body_next_token: $body_next_token, max_query_results: $max_query_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the JSON text of the resource-based policy document attached to the CloudTrail channel.
#
# POST /
# Returns: record<ResourceArn: string, ResourcePolicy: string>
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the CloudTrail channel attached to the resource-based policy. The following is the format of a resource ARN: arn:aws:cloudtrail:us-east-2:123456789012:channel/MyChannel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetResourcePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns settings information for a specified trail.
#
# POST /
# Returns: record<Trail: record<Name: string, S3BucketName: string, S3KeyPrefix: string, SnsTopicName: string, SnsTopicARN: string, IncludeGlobalServiceEvents: bool, IsMultiRegionTrail: bool, HomeRegion: string, TrailARN: string, LogFileValidationEnabled: bool, CloudWatchLogsLogGroupArn: string, CloudWatchLogsRoleArn: string, KmsKeyId: string, HasCustomEventSelectors: bool, HasInsightSelectors: bool, IsOrganizationTrail: bool>>
# operationId: GetTrail
export def "get-trail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name or the Amazon Resource Name (ARN) of the trail for which you want to retrieve settings information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetTrail"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a JSON-formatted list of information about the specified trail. Fields include information on delivery errors, Amazon SNS and Amazon S3 errors, and start and stop logging times for each trail. This operation returns trail status from a single region. To return trail status from all regions, you must call the operation on each region.
#
# POST /
# Returns: record<IsLogging: bool, LatestDeliveryError: string, LatestNotificationError: string, LatestDeliveryTime: string, LatestNotificationTime: string, StartLoggingTime: string, StopLoggingTime: string, LatestCloudWatchLogsDeliveryError: string, LatestCloudWatchLogsDeliveryTime: string, LatestDigestDeliveryTime: string, LatestDigestDeliveryError: string, LatestDeliveryAttemptTime: string, LatestNotificationAttemptTime: string, LatestNotificationAttemptSucceeded: string, LatestDeliveryAttemptSucceeded: string, TimeLoggingStarted: string, TimeLoggingStopped: string>
# operationId: GetTrailStatus
export def "get-trail-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # Specifies the name or the CloudTrail ARN of the trail for which you are requesting status. To get the status of a shadow trail (a replication of the trail in another region), you must specify its ARN. The following is the format of a trail ARN. arn:aws:cloudtrail:us-east-2:123456789012:trail/MyTrail
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetTrailStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the channels in the current account, and their source names.
#
# POST /
# Returns: record<Channels: table<ChannelArn: string, Name: string>, NextToken: string>
# operationId: ListChannels
export def "list-channels" [
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
  --x-amz-target: string@x-amz-target-completer-21 # required
  --body-max-results: int # The maximum number of CloudTrail channels to display on a single page. (spec name: MaxResults)
  --body-next-token: string # The token to use to get the next page of results after a previous API call. This token must be passed in with the same parameters that were specified in the original call. For example, if the original call specified an AttributeKey of 'Username' with a value of 'root', the call with NextToken should include those same parameters. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListChannels"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about all event data stores in the account, in the current region.
#
# POST /
# Returns: record<EventDataStores: table<EventDataStoreArn: string, Name: string, TerminationProtectionEnabled: bool, Status: string, AdvancedEventSelectors: list, MultiRegionEnabled: bool, OrganizationEnabled: bool, RetentionPeriod: int, CreatedTimestamp: string, UpdatedTimestamp: string>, NextToken: string>
# operationId: ListEventDataStores
export def "list-event-data-stores" [
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
  --body-next-token: string # A token you can use to get the next page of event data store results. (spec name: NextToken)
  --body-max-results: int # The maximum number of event data stores to display on a single page. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListEventDataStores"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of failures for the specified import.
#
# POST /
# Returns: record<Failures: table<Location: string, Status: string, ErrorType: string, ErrorMessage: string, LastUpdatedTime: string>, NextToken: string>
# operationId: ListImportFailures
export def "list-import-failures" [
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
  import_id: string # The ID of the import.
  --body-max-results: int # The maximum number of failures to display on a single page. (spec name: MaxResults)
  --body-next-token: string # A token you can use to get the next page of import failures. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListImportFailures"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ImportId, var: import_id}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, import_id: $import_id, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information on all imports, or a select set of imports by ImportStatus or Destination.
#
# POST /
# Returns: record<Imports: table<ImportId: string, ImportStatus: string, Destinations: list, CreatedTimestamp: string, UpdatedTimestamp: string>, NextToken: string>
# operationId: ListImports
export def "list-imports" [
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
  --x-amz-target: string@x-amz-target-completer-24 # required
  --body-max-results: int # The maximum number of imports to display on a single page. (spec name: MaxResults)
  --destination: string # The ARN of the destination event data store.
  --import-status: string@import-status-completer # The status of the import.
  --body-next-token: string # A token you can use to get the next page of import results. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListImports"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: Destination, var: destination}, {name: ImportStatus, var: import_status}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, destination: $destination, import_status: $import_status, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all public keys whose private keys were used to sign the digest files within the specified time range. The public key is needed to validate digest files that were signed with its corresponding private key. CloudTrail uses different private and public key pairs per region. Each digest file is signed with a private key unique to its region. When you validate a digest file from a specific region, you must look in the same region for its corresponding public key.
#
# POST /
# Returns: record<PublicKeyList: table<Value: string, ValidityStartTime: string, ValidityEndTime: string, Fingerprint: string>, NextToken: string>
# operationId: ListPublicKeys
export def "list-public-keys" [
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
  --start-time: string # Optionally specifies, in UTC, the start of the time range to look up public keys for CloudTrail digest files. If not specified, the current time is used, and the current public key is returned. (format: date-time)
  --end-time: string # Optionally specifies, in UTC, the end of the time range to look up public keys for CloudTrail digest files. If not specified, the current time is used. (format: date-time)
  --body-next-token: string # Reserved for future use. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListPublicKeys"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StartTime, var: start_time}, {name: EndTime, var: end_time}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, start_time: $start_time, end_time: $end_time, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of queries and query statuses for the past seven days. You must specify an ARN value for EventDataStore. Optionally, to shorten the list of results, you can specify a time range, formatted as timestamps, by adding StartTime and EndTime parameters, and a QueryStatus value. Valid values for QueryStatus include QUEUED, RUNNING, FINISHED, FAILED, TIMED_OUT, or CANCELLED.
#
# POST /
# Returns: record<Queries: table<QueryId: string, QueryStatus: string, CreationTime: string>, NextToken: string>
# operationId: ListQueries
export def "list-queries" [
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  event_data_store: string # The ARN (or the ID suffix of the ARN) of an event data store on which queries were run.
  --body-next-token: string # A token you can use to get the next page of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of queries to show on a page. (spec name: MaxResults)
  --start-time: string # Use with EndTime to bound a ListQueries request, and limit its results to only those queries run within a specified time period. (format: date-time)
  --end-time: string # Use with StartTime to bound a ListQueries request, and limit its results to only those queries run within a specified time period. (format: date-time)
  --query-status: string@query-status-completer # The status of queries that you want to return in results. Valid values for QueryStatus include QUEUED, RUNNING, FINISHED, FAILED, TIMED_OUT, or CANCELLED.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListQueries"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EventDataStore, var: event_data_store}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: StartTime, var: start_time}, {name: EndTime, var: end_time}, {name: QueryStatus, var: query_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, event_data_store: $event_data_store, body_next_token: $body_next_token, body_max_results: $body_max_results, start_time: $start_time, end_time: $end_time, query_status: $query_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the tags for the trail, event data store, or channel in the current region.
#
# POST /
# Returns: record<ResourceTagList: table<ResourceId: string, TagsList: list>, NextToken: string>
# operationId: ListTags
export def "list-tags" [
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
  resource_id_list: list<string> # Specifies a list of trail, event data store, or channel ARNs whose tags will be listed. The list has a limit of 20 ARNs.
  --body-next-token: string # Reserved for future use. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListTags"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceIdList, var: resource_id_list}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id_list: $resource_id_list, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists trails that are in the current account.
#
# POST /
# Returns: record<Trails: table<TrailARN: string, Name: string, HomeRegion: string>, NextToken: string>
# operationId: ListTrails
export def "list-trails" [
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  --body-next-token: string # The token to use to get the next page of results after a previous API call. This token must be passed in with the same parameters that were specified in the original call. For example, if the original call specified an AttributeKey of 'Username' with a value of 'root', the call with NextToken should include those same parameters. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListTrails"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Looks up management events (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-concepts.html#cloudtrail-concepts-management-events) or CloudTrail Insights events (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-concepts.html#cloudtrail-concepts-insights-events) that are captured by CloudTrail. You can look up events that occurred in a region within the last 90 days. Lookup supports the following attributes for management events: Amazon Web Services access key Event ID Event name Event source Read only Resource name Resource type User name Lookup supports the following attributes for Insights events: Event ID Event name Event source All attributes are optional. The default number of results returned is 50, with a maximum of 50 possible. The response includes a token that you can use to get the next page of results. The rate of lookup requests is limited to two per second, per account, per region. If this limit is exceeded, a throttling error occurs.
#
# POST /
# Returns: record<Events: table<EventId: string, EventName: string, ReadOnly: string, AccessKeyId: string, EventTime: string, EventSource: string, Username: string, Resources: list, CloudTrailEvent: string>, NextToken: string>
# operationId: LookupEvents
export def "lookup-events" [
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
  --lookup-attributes: list # Contains a list of lookup attributes. Currently the list can contain only one item. — item shape: {AttributeKey: "EventId"|"EventName"|"ReadOnly"|"Username"|"ResourceType"|"ResourceName"|"EventSource"|"AccessKeyId", AttributeValue: string}
  --start-time: string # Specifies that only events that occur after or at the specified time are returned. If the specified start time is after the specified end time, an error is returned. (format: date-time)
  --end-time: string # Specifies that only events that occur before or at the specified time are returned. If the specified end time is before the specified start time, an error is returned. (format: date-time)
  --event-category: string@event-category-completer # Specifies the event category. If you do not specify an event category, events of the category are not returned in the response. For example, if you do not specify insight as the value of EventCategory, no Insights events are returned.
  --body-max-results: int # The number of events to return. Possible values are 1 through 50. The default is 50. (spec name: MaxResults)
  --body-next-token: string # The token to use to get the next page of results after a previous API call. This token must be passed in with the same parameters that were specified in the original call. For example, if the original call specified an AttributeKey of 'Username' with a value of 'root', the call with NextToken should include those same parameters. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.LookupEvents"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LookupAttributes, var: lookup_attributes}, {name: StartTime, var: start_time}, {name: EndTime, var: end_time}, {name: EventCategory, var: event_category}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, lookup_attributes: $lookup_attributes, start_time: $start_time, end_time: $end_time, event_category: $event_category, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configures an event selector or advanced event selectors for your trail. Use event selectors or advanced event selectors to specify management and data event settings for your trail. By default, trails created without specific event selectors are configured to log all read and write management events, and no data events. When an event occurs in your account, CloudTrail evaluates the event selectors or advanced event selectors in all trails. For each trail, if the event matches any event selector, the trail processes and logs the event. If the event doesn't match any event selector, the trail doesn't log the event. Example You create an event selector for a trail and specify that you want write-only events. The EC2 GetConsoleOutput and RunInstances API operations occur in your account. CloudTrail evaluates whether the events match your event selectors. The RunInstances is a write-only event and it matches your event selector. The trail logs the event. The GetConsoleOutput is a read-only event that doesn't match your event selector. The trail doesn't log the event. The PutEventSelectors operation must be called from the region in which the trail was created; otherwise, an InvalidHomeRegionException exception is thrown. You can configure up to five event selectors for each trail. For more information, see Logging management events for trails (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-management-events-with-cloudtrail.html), Logging data events for trails (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-data-events-with-cloudtrail.html), and Quotas in CloudTrail (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/WhatIsCloudTrail-Limits.html) in the CloudTrail User Guide. You can add advanced event selectors, and conditions for your advanced event selectors, up to a maximum of 500 values for all conditions and selectors on a trail. You can use either AdvancedEventSelectors or EventSelectors, but not both. If you apply AdvancedEventSelectors to a trail, any existing EventSelectors are overwritten. For more information about advanced event selectors, see Logging data events for trails (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-data-events-with-cloudtrail.html) in the CloudTrail User Guide.
#
# POST /
# Returns: record<TrailARN: string, EventSelectors: table<ReadWriteType: string, IncludeManagementEvents: bool, DataResources: list, ExcludeManagementEventSources: list>, AdvancedEventSelectors: table<Name: string, FieldSelectors: list>>
# operationId: PutEventSelectors
export def "put-event-selectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  trail_name: string # Specifies the name of the trail or trail ARN. If you specify a trail name, the string must meet the following requirements: Contain only ASCII letters (a-z, A-Z), numbers (0-9), periods (.), underscores (_), or dashes (-) Start with a letter or number, and end with a letter or number Be between 3 and 128 characters Have no adjacent periods, underscores or dashes. Names like my-_namespace and my--namespace are not valid. Not be in IP address format (for example, 192.168.5.4) If you specify a trail ARN, it must be in the following format. arn:aws:cloudtrail:us-east-2:123456789012:trail/MyTrail
  --event-selectors: list # Specifies the settings for your event selectors. You can configure up to five event selectors for a trail. You can use either EventSelectors or AdvancedEventSelectors in a PutEventSelectors request, but not both. If you apply EventSelectors to a trail, any existing AdvancedEventSelectors are overwritten. — item shape: {ReadWriteType?: "ReadOnly"|"WriteOnly"|"All", IncludeManagementEvents?: bool, DataResources?: list, ExcludeManagementEventSources?: list<string>}
  --advanced-event-selectors: list # Specifies the settings for advanced event selectors. You can add advanced event selectors, and conditions for your advanced event selectors, up to a maximum of 500 values for all conditions and selectors on a trail. You can use either AdvancedEventSelectors or EventSelectors, but not both. If you apply AdvancedEventSelectors to a trail, any existing EventSelectors are overwritten. For more information about advanced event selectors, see Logging data events for trails (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-data-events-with-cloudtrail.html) in the CloudTrail User Guide. — item shape: {Name?: string, FieldSelectors: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.PutEventSelectors"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TrailName, var: trail_name}, {name: EventSelectors, var: event_selectors}, {name: AdvancedEventSelectors, var: advanced_event_selectors}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, trail_name: $trail_name, event_selectors: $event_selectors, advanced_event_selectors: $advanced_event_selectors
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lets you enable Insights event logging by specifying the Insights selectors that you want to enable on an existing trail. You also use PutInsightSelectors to turn off Insights event logging, by passing an empty list of insight types. The valid Insights event types in this release are ApiErrorRateInsight and ApiCallRateInsight.
#
# POST /
# Returns: record<TrailARN: string, InsightSelectors: table<InsightType: string>>
# operationId: PutInsightSelectors
export def "put-insight-selectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  trail_name: string # The name of the CloudTrail trail for which you want to change or add Insights selectors.
  insight_selectors: list # A JSON string that contains the insight types you want to log on a trail. ApiCallRateInsight and ApiErrorRateInsight are valid insight types. — item shape: {InsightType?: "ApiCallRateInsight"|"ApiErrorRateInsight"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.PutInsightSelectors"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TrailName, var: trail_name}, {name: InsightSelectors, var: insight_selectors}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, trail_name: $trail_name, insight_selectors: $insight_selectors
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches a resource-based permission policy to a CloudTrail channel that is used for an integration with an event source outside of Amazon Web Services. For more information about resource-based policies, see CloudTrail resource-based policy examples (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/security_iam_resource-based-policy-examples.html) in the CloudTrail User Guide.
#
# POST /
# Returns: record<ResourceArn: string, ResourcePolicy: string>
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
  --x-amz-target: string@x-amz-target-completer-32 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the CloudTrail channel attached to the resource-based policy. The following is the format of a resource ARN: arn:aws:cloudtrail:us-east-2:123456789012:channel/MyChannel.
  resource_policy: string # A JSON-formatted string for an Amazon Web Services resource-based policy. The following are requirements for the resource policy: Contains only one action: cloudtrail-data:PutAuditEvents Contains at least one statement. The policy can have a maximum of 20 statements. Each statement contains at least one principal. A statement can have a maximum of 50 principals.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.PutResourcePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: ResourcePolicy, var: resource_policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, resource_policy: $resource_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers an organization’s member account as the CloudTrail delegated administrator.
#
# POST /
# Returns: record
# operationId: RegisterOrganizationDelegatedAdmin
export def "register-organization-delegated-admin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  member_account_id: string # An organization member account ID that you want to designate as a delegated administrator.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.RegisterOrganizationDelegatedAdmin"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MemberAccountId, var: member_account_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, member_account_id: $member_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the specified tags from a trail, event data store, or channel.
#
# POST /
# Returns: record
# operationId: RemoveTags
export def "remove-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_id: string # Specifies the ARN of the trail, event data store, or channel from which tags should be removed. Example trail ARN format: arn:aws:cloudtrail:us-east-2:123456789012:trail/MyTrail Example event data store ARN format: arn:aws:cloudtrail:us-east-2:12345678910:eventdatastore/EXAMPLE-f852-4e8f-8bd1-bcf6cEXAMPLE Example channel ARN format: arn:aws:cloudtrail:us-east-2:123456789012:channel/01234567890
  tags_list: list # A list of tags. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.RemoveTags"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceId, var: resource_id}, {name: TagsList, var: tags_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id: $resource_id, tags_list: $tags_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restores a deleted event data store specified by EventDataStore, which accepts an event data store ARN. You can only restore a deleted event data store within the seven-day wait period after deletion. Restoring an event data store can take several minutes, depending on the size of the event data store.
#
# POST /
# Returns: record<EventDataStoreArn: string, Name: string, Status: string, AdvancedEventSelectors: table<Name: string, FieldSelectors: list>, MultiRegionEnabled: bool, OrganizationEnabled: bool, RetentionPeriod: int, TerminationProtectionEnabled: bool, CreatedTimestamp: string, UpdatedTimestamp: string, KmsKeyId: string>
# operationId: RestoreEventDataStore
export def "restore-event-data-store" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  event_data_store: string # The ARN (or the ID suffix of the ARN) of the event data store that you want to restore.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.RestoreEventDataStore"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EventDataStore, var: event_data_store}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, event_data_store: $event_data_store
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an import of logged trail events from a source S3 bucket to a destination event data store. By default, CloudTrail only imports events contained in the S3 bucket's CloudTrail prefix and the prefixes inside the CloudTrail prefix, and does not check prefixes for other Amazon Web Services services. If you want to import CloudTrail events contained in another prefix, you must include the prefix in the S3LocationUri. For more considerations about importing trail events, see Considerations (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-copy-trail-to-lake.html#cloudtrail-trail-copy-considerations). When you start a new import, the Destinations and ImportSource parameters are required. Before starting a new import, disable any access control lists (ACLs) attached to the source S3 bucket. For more information about disabling ACLs, see Controlling ownership of objects and disabling ACLs for your bucket (https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html). When you retry an import, the ImportID parameter is required. If the destination event data store is for an organization, you must use the management account to import trail events. You cannot use the delegated administrator account for the organization.
#
# POST /
# Returns: record<ImportId: string, Destinations: list<string>, ImportSource: record<S3: record<S3LocationUri: string, S3BucketRegion: string, S3BucketAccessRoleArn: string>>, StartEventTime: string, EndEventTime: string, ImportStatus: string, CreatedTimestamp: string, UpdatedTimestamp: string>
# operationId: StartImport
export def "start-import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --destinations: list<string> # The ARN of the destination event data store. Use this parameter for a new import.
  --import-source: record # The import source. — shape: {S3: record}
  --start-event-time: string # Use with EndEventTime to bound a StartImport request, and limit imported trail events to only those events logged within a specified time period. When you specify a time range, CloudTrail checks the prefix and log file names to verify the names contain a date between the specified StartEventTime and EndEventTime before attempting to import events. (format: date-time)
  --end-event-time: string # Use with StartEventTime to bound a StartImport request, and limit imported trail events to only those events logged within a specified time period. When you specify a time range, CloudTrail checks the prefix and log file names to verify the names contain a date between the specified StartEventTime and EndEventTime before attempting to import events. (format: date-time)
  --import-id: string # The ID of the import. Use this parameter when you are retrying an import.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.StartImport"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Destinations, var: destinations}, {name: ImportSource, var: import_source}, {name: StartEventTime, var: start_event_time}, {name: EndEventTime, var: end_event_time}, {name: ImportId, var: import_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, destinations: $destinations, import_source: $import_source, start_event_time: $start_event_time, end_event_time: $end_event_time, import_id: $import_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts the recording of Amazon Web Services API calls and log file delivery for a trail. For a trail that is enabled in all regions, this operation must be called from the region in which the trail was created. This operation cannot be called on the shadow trails (replicated trails in other regions) of a trail that is enabled in all regions.
#
# POST /
# Returns: record
# operationId: StartLogging
export def "start-logging" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # Specifies the name or the CloudTrail ARN of the trail for which CloudTrail logs Amazon Web Services API calls. The following is the format of a trail ARN. arn:aws:cloudtrail:us-east-2:123456789012:trail/MyTrail
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.StartLogging"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a CloudTrail Lake query. The required QueryStatement parameter provides your SQL query, enclosed in single quotation marks. Use the optional DeliveryS3Uri parameter to deliver the query results to an S3 bucket.
#
# POST /
# Returns: record<QueryId: string>
# operationId: StartQuery
export def "start-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  query_statement: string # The SQL code of your query.
  --delivery-s3-uri: string # The URI for the S3 bucket where CloudTrail delivers the query results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.StartQuery"}]
    body: {content_type: "application/json", kind: json, fields: [{name: QueryStatement, var: query_statement}, {name: DeliveryS3Uri, var: delivery_s3_uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, query_statement: $query_statement, delivery_s3_uri: $delivery_s3_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a specified import.
#
# POST /
# Returns: record<ImportId: string, ImportSource: record<S3: record<S3LocationUri: string, S3BucketRegion: string, S3BucketAccessRoleArn: string>>, Destinations: list<string>, ImportStatus: string, CreatedTimestamp: string, UpdatedTimestamp: string, StartEventTime: string, EndEventTime: string, ImportStatistics: record<PrefixesFound: int, PrefixesCompleted: int, FilesCompleted: int, EventsCompleted: int, FailedEntries: int>>
# operationId: StopImport
export def "stop-import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  import_id: string # The ID of the import.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.StopImport"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ImportId, var: import_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, import_id: $import_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suspends the recording of Amazon Web Services API calls and log file delivery for the specified trail. Under most circumstances, there is no need to use this action. You can update a trail without stopping it first. This action is the only way to stop recording. For a trail enabled in all regions, this operation must be called from the region in which the trail was created, or an InvalidHomeRegionException will occur. This operation cannot be called on the shadow trails (replicated trails in other regions) of a trail enabled in all regions.
#
# POST /
# Returns: record
# operationId: StopLogging
export def "stop-logging" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # Specifies the name or the CloudTrail ARN of the trail for which CloudTrail will stop logging Amazon Web Services API calls. The following is the format of a trail ARN. arn:aws:cloudtrail:us-east-2:123456789012:trail/MyTrail
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.StopLogging"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a channel specified by a required channel ARN or UUID.
#
# POST /
# Returns: record<ChannelArn: string, Name: string, Source: string, Destinations: table<Type: string, Location: string>>
# operationId: UpdateChannel
export def "update-channel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  channel: string # The ARN or ID (the ARN suffix) of the channel that you want to update.
  --destinations: list # The ARNs of event data stores that you want to log events arriving through the channel. — item shape: {Type: "EVENT_DATA_STORE"|"AWS_SERVICE", Location: string}
  --name: string # Changes the name of the channel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.UpdateChannel"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Channel, var: channel}, {name: Destinations, var: destinations}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, channel: $channel, destinations: $destinations, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an event data store. The required EventDataStore value is an ARN or the ID portion of the ARN. Other parameters are optional, but at least one optional parameter must be specified, or CloudTrail throws an error. RetentionPeriod is in days, and valid values are integers between 90 and 2557. By default, TerminationProtection is enabled. For event data stores for CloudTrail events, AdvancedEventSelectors includes or excludes management and data events in your event data store. For more information about AdvancedEventSelectors, see PutEventSelectorsRequest$AdvancedEventSelectors. For event data stores for Config configuration items, Audit Manager evidence, or non-Amazon Web Services events, AdvancedEventSelectors includes events of that type in your event data store.
#
# POST /
# Returns: record<EventDataStoreArn: string, Name: string, Status: string, AdvancedEventSelectors: table<Name: string, FieldSelectors: list>, MultiRegionEnabled: bool, OrganizationEnabled: bool, RetentionPeriod: int, TerminationProtectionEnabled: bool, CreatedTimestamp: string, UpdatedTimestamp: string, KmsKeyId: string>
# operationId: UpdateEventDataStore
export def "update-event-data-store" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  event_data_store: string # The ARN (or the ID suffix of the ARN) of the event data store that you want to update.
  --name: string # The event data store name.
  --advanced-event-selectors: list # The advanced event selectors used to select events for the event data store. You can configure up to five advanced event selectors for each event data store. — item shape: {Name?: string, FieldSelectors: list}
  --multi-region-enabled: oneof<nothing, bool> # Specifies whether an event data store collects events from all regions, or only from the region in which it was created.
  --organization-enabled: oneof<nothing, bool> # Specifies whether an event data store collects events logged for an organization in Organizations.
  --retention-period: int # The retention period, in days.
  --termination-protection-enabled: oneof<nothing, bool> # Indicates that termination protection is enabled and the event data store cannot be automatically deleted.
  --kms-key-id: string # Specifies the KMS key ID to use to encrypt the events delivered by CloudTrail. The value can be an alias name prefixed by alias/, a fully specified ARN to an alias, a fully specified ARN to a key, or a globally unique identifier. Disabling or deleting the KMS key, or removing CloudTrail permissions on the key, prevents CloudTrail from logging events to the event data store, and prevents users from querying the data in the event data store that was encrypted with the key. After you associate an event data store with a KMS key, the KMS key cannot be removed or changed. Before you disable or delete a KMS key that you are using with an event data store, delete or back up your event data store. CloudTrail also supports KMS multi-Region keys. For more information about multi-Region keys, see Using multi-Region keys (https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html) in the Key Management Service Developer Guide. Examples: alias/MyAliasName arn:aws:kms:us-east-2:123456789012:alias/MyAliasName arn:aws:kms:us-east-2:123456789012:key/12345678-1234-1234-1234-123456789012 12345678-1234-1234-1234-123456789012
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.UpdateEventDataStore"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EventDataStore, var: event_data_store}, {name: Name, var: name}, {name: AdvancedEventSelectors, var: advanced_event_selectors}, {name: MultiRegionEnabled, var: multi_region_enabled}, {name: OrganizationEnabled, var: organization_enabled}, {name: RetentionPeriod, var: retention_period}, {name: TerminationProtectionEnabled, var: termination_protection_enabled}, {name: KmsKeyId, var: kms_key_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, event_data_store: $event_data_store, name: $name, advanced_event_selectors: $advanced_event_selectors, multi_region_enabled: $multi_region_enabled, organization_enabled: $organization_enabled, retention_period: $retention_period, termination_protection_enabled: $termination_protection_enabled, kms_key_id: $kms_key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates trail settings that control what events you are logging, and how to handle log files. Changes to a trail do not require stopping the CloudTrail service. Use this action to designate an existing bucket for log delivery. If the existing bucket has previously been a target for CloudTrail log files, an IAM policy exists for the bucket. UpdateTrail must be called from the region in which the trail was created; otherwise, an InvalidHomeRegionException is thrown.
#
# POST /
# Returns: record<Name: string, S3BucketName: string, S3KeyPrefix: string, SnsTopicName: string, SnsTopicARN: string, IncludeGlobalServiceEvents: bool, IsMultiRegionTrail: bool, TrailARN: string, LogFileValidationEnabled: bool, CloudWatchLogsLogGroupArn: string, CloudWatchLogsRoleArn: string, KmsKeyId: string, IsOrganizationTrail: bool>
# operationId: UpdateTrail
export def "update-trail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # Specifies the name of the trail or trail ARN. If Name is a trail name, the string must meet the following requirements: Contain only ASCII letters (a-z, A-Z), numbers (0-9), periods (.), underscores (_), or dashes (-) Start with a letter or number, and end with a letter or number Be between 3 and 128 characters Have no adjacent periods, underscores or dashes. Names like my-_namespace and my--namespace are not valid. Not be in IP address format (for example, 192.168.5.4) If Name is a trail ARN, it must be in the following format. arn:aws:cloudtrail:us-east-2:123456789012:trail/MyTrail
  --s3-bucket-name: string # Specifies the name of the Amazon S3 bucket designated for publishing log files. See Amazon S3 Bucket Naming Requirements (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create_trail_naming_policy.html).
  --s3-key-prefix: string # Specifies the Amazon S3 key prefix that comes after the name of the bucket you have designated for log file delivery. For more information, see Finding Your CloudTrail Log Files (https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-find-log-files.html). The maximum length is 200 characters.
  --sns-topic-name: string # Specifies the name of the Amazon SNS topic defined for notification of log file delivery. The maximum length is 256 characters.
  --include-global-service-events: oneof<nothing, bool> # Specifies whether the trail is publishing events from global services such as IAM to the log files.
  --is-multi-region-trail: oneof<nothing, bool> # Specifies whether the trail applies only to the current region or to all regions. The default is false. If the trail exists only in the current region and this value is set to true, shadow trails (replications of the trail) will be created in the other regions. If the trail exists in all regions and this value is set to false, the trail will remain in the region where it was created, and its shadow trails in other regions will be deleted. As a best practice, consider using trails that log events in all regions.
  --enable-log-file-validation: oneof<nothing, bool> # Specifies whether log file validation is enabled. The default is false. When you disable log file integrity validation, the chain of digest files is broken after one hour. CloudTrail does not create digest files for log files that were delivered during a period in which log file integrity validation was disabled. For example, if you enable log file integrity validation at noon on January 1, disable it at noon on January 2, and re-enable it at noon on January 10, digest files will not be created for the log files delivered from noon on January 2 to noon on January 10. The same applies whenever you stop CloudTrail logging or delete a trail.
  --cloud-watch-logs-log-group-arn: string # Specifies a log group name using an Amazon Resource Name (ARN), a unique identifier that represents the log group to which CloudTrail logs are delivered. You must use a log group that exists in your account. Not required unless you specify CloudWatchLogsRoleArn.
  --cloud-watch-logs-role-arn: string # Specifies the role for the CloudWatch Logs endpoint to assume to write to a user's log group. You must use a role that exists in your account.
  --kms-key-id: string # Specifies the KMS key ID to use to encrypt the logs delivered by CloudTrail. The value can be an alias name prefixed by "alias/", a fully specified ARN to an alias, a fully specified ARN to a key, or a globally unique identifier. CloudTrail also supports KMS multi-Region keys. For more information about multi-Region keys, see Using multi-Region keys (https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html) in the Key Management Service Developer Guide. Examples: alias/MyAliasName arn:aws:kms:us-east-2:123456789012:alias/MyAliasName arn:aws:kms:us-east-2:123456789012:key/12345678-1234-1234-1234-123456789012 12345678-1234-1234-1234-123456789012
  --is-organization-trail: oneof<nothing, bool> # Specifies whether the trail is applied to all accounts in an organization in Organizations, or only for the current Amazon Web Services account. The default is false, and cannot be true unless the call is made on behalf of an Amazon Web Services account that is the management account or delegated administrator account for an organization in Organizations. If the trail is not an organization trail and this is set to true, the trail will be created in all Amazon Web Services accounts that belong to the organization. If the trail is an organization trail and this is set to false, the trail will remain in the current Amazon Web Services account but be deleted from all member accounts in the organization.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.UpdateTrail"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: S3BucketName, var: s3_bucket_name}, {name: S3KeyPrefix, var: s3_key_prefix}, {name: SnsTopicName, var: sns_topic_name}, {name: IncludeGlobalServiceEvents, var: include_global_service_events}, {name: IsMultiRegionTrail, var: is_multi_region_trail}, {name: EnableLogFileValidation, var: enable_log_file_validation}, {name: CloudWatchLogsLogGroupArn, var: cloud_watch_logs_log_group_arn}, {name: CloudWatchLogsRoleArn, var: cloud_watch_logs_role_arn}, {name: KmsKeyId, var: kms_key_id}, {name: IsOrganizationTrail, var: is_organization_trail}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, s3_bucket_name: $s3_bucket_name, s3_key_prefix: $s3_key_prefix, sns_topic_name: $sns_topic_name, include_global_service_events: $include_global_service_events, is_multi_region_trail: $is_multi_region_trail, enable_log_file_validation: $enable_log_file_validation, cloud_watch_logs_log_group_arn: $cloud_watch_logs_log_group_arn, cloud_watch_logs_role_arn: $cloud_watch_logs_role_arn, kms_key_id: $kms_key_id, is_organization_trail: $is_organization_trail
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
