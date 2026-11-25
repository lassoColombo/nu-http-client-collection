# Auto-generated client for Amazon Kinesis Video Streams Archived Media v2017-09-30
# Source: https://api.apis.guru/v2/specs/amazonaws.com/kinesis-video-archived-media/2017-09-30/openapi.json
# Auth: --token flag or $env.AMAZON_KINESIS_VIDEO_STREAMS_ARCHIVED_MEDIA_TOKEN

const CLIENT = {
  base_url: "http://kinesisvideo.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_KINESIS_VIDEO_STREAMS_ARCHIVED_MEDIA_TOKEN"
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

def base-url-completer [] { ["http://kinesisvideo.us-east-1.amazonaws.com" "http://kinesisvideo.us-east-2.amazonaws.com" "http://kinesisvideo.us-west-1.amazonaws.com" "http://kinesisvideo.us-west-2.amazonaws.com" "http://kinesisvideo.us-gov-west-1.amazonaws.com" "http://kinesisvideo.us-gov-east-1.amazonaws.com" "http://kinesisvideo.ca-central-1.amazonaws.com" "http://kinesisvideo.eu-north-1.amazonaws.com" "http://kinesisvideo.eu-west-1.amazonaws.com" "http://kinesisvideo.eu-west-2.amazonaws.com" "http://kinesisvideo.eu-west-3.amazonaws.com" "http://kinesisvideo.eu-central-1.amazonaws.com" "http://kinesisvideo.eu-south-1.amazonaws.com" "http://kinesisvideo.af-south-1.amazonaws.com" "http://kinesisvideo.ap-northeast-1.amazonaws.com" "http://kinesisvideo.ap-northeast-2.amazonaws.com" "http://kinesisvideo.ap-northeast-3.amazonaws.com" "http://kinesisvideo.ap-southeast-1.amazonaws.com" "http://kinesisvideo.ap-southeast-2.amazonaws.com" "http://kinesisvideo.ap-east-1.amazonaws.com" "http://kinesisvideo.ap-south-1.amazonaws.com" "http://kinesisvideo.sa-east-1.amazonaws.com" "http://kinesisvideo.me-south-1.amazonaws.com" "https://kinesisvideo.us-east-1.amazonaws.com" "https://kinesisvideo.us-east-2.amazonaws.com" "https://kinesisvideo.us-west-1.amazonaws.com" "https://kinesisvideo.us-west-2.amazonaws.com" "https://kinesisvideo.us-gov-west-1.amazonaws.com" "https://kinesisvideo.us-gov-east-1.amazonaws.com" "https://kinesisvideo.ca-central-1.amazonaws.com" "https://kinesisvideo.eu-north-1.amazonaws.com" "https://kinesisvideo.eu-west-1.amazonaws.com" "https://kinesisvideo.eu-west-2.amazonaws.com" "https://kinesisvideo.eu-west-3.amazonaws.com" "https://kinesisvideo.eu-central-1.amazonaws.com" "https://kinesisvideo.eu-south-1.amazonaws.com" "https://kinesisvideo.af-south-1.amazonaws.com" "https://kinesisvideo.ap-northeast-1.amazonaws.com" "https://kinesisvideo.ap-northeast-2.amazonaws.com" "https://kinesisvideo.ap-northeast-3.amazonaws.com" "https://kinesisvideo.ap-southeast-1.amazonaws.com" "https://kinesisvideo.ap-southeast-2.amazonaws.com" "https://kinesisvideo.ap-east-1.amazonaws.com" "https://kinesisvideo.ap-south-1.amazonaws.com" "https://kinesisvideo.sa-east-1.amazonaws.com" "https://kinesisvideo.me-south-1.amazonaws.com" "http://kinesisvideo.cn-north-1.amazonaws.com.cn" "http://kinesisvideo.cn-northwest-1.amazonaws.com.cn" "https://kinesisvideo.cn-north-1.amazonaws.com.cn" "https://kinesisvideo.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def playback-mode-completer [] { ["LIVE" "LIVE_REPLAY" "ON_DEMAND"] }
def display-fragment-timestamp-completer [] { ["ALWAYS" "NEVER"] }
def display-fragment-number-completer [] { ["ALWAYS" "NEVER"] }
def container-format-completer [] { ["FRAGMENTED_MP4" "MPEG_TS"] }
def discontinuity-mode-completer [] { ["ALWAYS" "NEVER" "ON_DISCONTINUITY"] }
def image-selector-type-completer [] { ["PRODUCER_TIMESTAMP" "SERVER_TIMESTAMP"] }
def format-completer [] { ["JPEG" "PNG"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-clip: "record<Payload: string>"
    get-dash-streaming-session-url: "record<DASHStreamingSessionURL: string>"
    get-hls-streaming-session-url: "record<HLSStreamingSessionURL: string>"
    get-images: "record<Images: table<TimeStamp: string, Error: string, ImageContent: string>, NextToken: string>"
    get-media-for-fragment-list: "record<Payload: string>"
    list-fragments: "record<Fragments: table<FragmentNumber: string, FragmentSizeInBytes: int, ProducerTimestamp: string, ServerTimestamp: string, FragmentLengthInMilliseconds: int>, NextToken: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-clip" "get-dash-streaming-session-url" "get-hls-streaming-session-url" "get-images" "get-media-for-fragment-list" "list-fragments" "commands"] | sort) } | get name | first)
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

# Downloads an MP4 file (clip) containing the archived, on-demand media from the specified video stream over the specified time range. Both the StreamName and the StreamARN parameters are optional, but you must specify either the StreamName or the StreamARN when invoking this API operation. As a prerequisite to using GetCLip API, you must obtain an endpoint using GetDataEndpoint, specifying GET_CLIP for the APIName parameter. An Amazon Kinesis video stream has the following requirements for providing data through MP4: The media must contain h.264 or h.265 encoded video and, optionally, AAC or G.711 encoded audio. Specifically, the codec ID of track 1 should be V_MPEG/ISO/AVC (for h.264) or V_MPEGH/ISO/HEVC (for H.265). Optionally, the codec ID of track 2 should be A_AAC (for AAC) or A_MS/ACM (for G.711). Data retention must be greater than 0. The video track of each fragment must contain codec private data in the Advanced Video Coding (AVC) for H.264 format and HEVC for H.265 format. For more information, see MPEG-4 specification ISO/IEC 14496-15 (https://www.iso.org/standard/55980.html). For information about adapting stream data to a given format, see NAL Adaptation Flags (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/producer-reference-nal.html). The audio track (if present) of each fragment must contain codec private data in the AAC format (AAC specification ISO/IEC 13818-7 (https://www.iso.org/standard/43345.html)) or the MS Wave format (http://www-mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/WAVE.html). You can monitor the amount of outgoing data by monitoring the GetClip.OutgoingBytes Amazon CloudWatch metric. For information about using CloudWatch to monitor Kinesis Video Streams, see Monitoring Kinesis Video Streams (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/monitoring.html). For pricing information, see Amazon Kinesis Video Streams Pricing (https://aws.amazon.com/kinesis/video-streams/pricing/) and AWS Pricing (https://aws.amazon.com/pricing/). Charges for outgoing AWS data apply.
#
# POST /getClip
# Returns: record<Payload: string>
# operationId: GetClip
export def "get-clip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --stream-name: string # The name of the stream for which to retrieve the media clip. You must specify either the StreamName or the StreamARN.
  --stream-arn: string # The Amazon Resource Name (ARN) of the stream for which to retrieve the media clip. You must specify either the StreamName or the StreamARN.
  clip_fragment_selector: record # Describes the timestamp range and timestamp origin of a range of fragments. Fragments that have duplicate producer timestamps are deduplicated. This means that if producers are producing a stream of fragments with producer timestamps that are approximately equal to the true clock time, the clip will contain all of the fragments within the requested timestamp range. If some fragments are ingested within the same time range and very different points in time, only the oldest ingested collection of fragments are returned. — shape: {FragmentSelectorType?: "PRODUCER_TIMESTAMP"|"SERVER_TIMESTAMP", TimestampRange?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getClip"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: StreamARN, var: stream_arn}, {name: ClipFragmentSelector, var: clip_fragment_selector}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, stream_name: $stream_name, stream_arn: $stream_arn, clip_fragment_selector: $clip_fragment_selector
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an MPEG Dynamic Adaptive Streaming over HTTP (DASH) URL for the stream. You can then open the URL in a media player to view the stream contents. Both the StreamName and the StreamARN parameters are optional, but you must specify either the StreamName or the StreamARN when invoking this API operation. An Amazon Kinesis video stream has the following requirements for providing data through MPEG-DASH: The media must contain h.264 or h.265 encoded video and, optionally, AAC or G.711 encoded audio. Specifically, the codec ID of track 1 should be V_MPEG/ISO/AVC (for h.264) or V_MPEGH/ISO/HEVC (for H.265). Optionally, the codec ID of track 2 should be A_AAC (for AAC) or A_MS/ACM (for G.711). Data retention must be greater than 0. The video track of each fragment must contain codec private data in the Advanced Video Coding (AVC) for H.264 format and HEVC for H.265 format. For more information, see MPEG-4 specification ISO/IEC 14496-15 (https://www.iso.org/standard/55980.html). For information about adapting stream data to a given format, see NAL Adaptation Flags (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/producer-reference-nal.html). The audio track (if present) of each fragment must contain codec private data in the AAC format (AAC specification ISO/IEC 13818-7 (https://www.iso.org/standard/43345.html)) or the MS Wave format (http://www-mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/WAVE.html). The following procedure shows how to use MPEG-DASH with Kinesis Video Streams: Get an endpoint using GetDataEndpoint (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/API_GetDataEndpoint.html), specifying GET_DASH_STREAMING_SESSION_URL for the APIName parameter. Retrieve the MPEG-DASH URL using GetDASHStreamingSessionURL. Kinesis Video Streams creates an MPEG-DASH streaming session to be used for accessing content in a stream using the MPEG-DASH protocol. GetDASHStreamingSessionURL returns an authenticated URL (that includes an encrypted session token) for the session's MPEG-DASH manifest (the root resource needed for streaming with MPEG-DASH). Don't share or store this token where an unauthorized entity can access it. The token provides access to the content of the stream. Safeguard the token with the same measures that you use with your AWS credentials. The media that is made available through the manifest consists only of the requested stream, time range, and format. No other media data (such as frames outside the requested window or alternate bitrates) is made available. Provide the URL (containing the encrypted session token) for the MPEG-DASH manifest to a media player that supports the MPEG-DASH protocol. Kinesis Video Streams makes the initialization fragment and media fragments available through the manifest URL. The initialization fragment contains the codec private data for the stream, and other data needed to set up the video or audio decoder and renderer. The media fragments contain encoded video frames or encoded audio samples. The media player receives the authenticated URL and requests stream metadata and media data normally. When the media player requests data, it calls the following actions: GetDASHManifest: Retrieves an MPEG DASH manifest, which contains the metadata for the media that you want to playback. GetMP4InitFragment: Retrieves the MP4 initialization fragment. The media player typically loads the initialization fragment before loading any media fragments. This fragment contains the "fytp" and "moov" MP4 atoms, and the child atoms that are needed to initialize the media player decoder. The initialization fragment does not correspond to a fragment in a Kinesis video stream. It contains only the codec private data for the stream and respective track, which the media player needs to decode the media frames. GetMP4MediaFragment: Retrieves MP4 media fragments. These fragments contain the "moof" and "mdat" MP4 atoms and their child atoms, containing the encoded fragment's media frames and their timestamps. After the first media fragment is made available in a streaming session, any fragments that don't contain the same codec private data cause an error to be returned when those different media fragments are loaded. Therefore, the codec private data should not change between fragments in a session. This also means that the session fails if the fragments in a stream change from having only video to having both audio and video. Data retrieved with this action is billable. See Pricing (https://aws.amazon.com/kinesis/video-streams/pricing/) for details. For restrictions that apply to MPEG-DASH sessions, see Kinesis Video Streams Limits (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/limits.html). You can monitor the amount of data that the media player consumes by monitoring the GetMP4MediaFragment.OutgoingBytes Amazon CloudWatch metric. For information about using CloudWatch to monitor Kinesis Video Streams, see Monitoring Kinesis Video Streams (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/monitoring.html). For pricing information, see Amazon Kinesis Video Streams Pricing (https://aws.amazon.com/kinesis/video-streams/pricing/) and AWS Pricing (https://aws.amazon.com/pricing/). Charges for both HLS sessions and outgoing AWS data apply. For more information about HLS, see HTTP Live Streaming (https://developer.apple.com/streaming/) on the Apple Developer site (https://developer.apple.com). If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: x-amz-ErrorType HTTP header – contains a more specific error type in addition to what the HTTP status code provides. x-amz-RequestId HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id. Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again. For more information, see the Errors section at the bottom of this topic, as well as Common Errors (https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html).
#
# POST /getDASHStreamingSessionURL
# Returns: record<DASHStreamingSessionURL: string>
# operationId: GetDASHStreamingSessionURL
export def "get-dash-streaming-session-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --stream-name: string # The name of the stream for which to retrieve the MPEG-DASH manifest URL. You must specify either the StreamName or the StreamARN.
  --stream-arn: string # The Amazon Resource Name (ARN) of the stream for which to retrieve the MPEG-DASH manifest URL. You must specify either the StreamName or the StreamARN.
  --playback-mode: string@playback-mode-completer # Whether to retrieve live, live replay, or archived, on-demand data. Features of the three types of sessions include the following: LIVE : For sessions of this type, the MPEG-DASH manifest is continually updated with the latest fragments as they become available. We recommend that the media player retrieve a new manifest on a one-second interval. When this type of session is played in a media player, the user interface typically displays a "live" notification, with no scrubber control for choosing the position in the playback window to display. In LIVE mode, the newest available fragments are included in an MPEG-DASH manifest, even if there is a gap between fragments (that is, if a fragment is missing). A gap like this might cause a media player to halt or cause a jump in playback. In this mode, fragments are not added to the MPEG-DASH manifest if they are older than the newest fragment in the playlist. If the missing fragment becomes available after a subsequent fragment is added to the manifest, the older fragment is not added, and the gap is not filled. LIVE_REPLAY : For sessions of this type, the MPEG-DASH manifest is updated similarly to how it is updated for LIVE mode except that it starts by including fragments from a given start time. Instead of fragments being added as they are ingested, fragments are added as the duration of the next fragment elapses. For example, if the fragments in the session are two seconds long, then a new fragment is added to the manifest every two seconds. This mode is useful to be able to start playback from when an event is detected and continue live streaming media that has not yet been ingested as of the time of the session creation. This mode is also useful to stream previously archived media without being limited by the 1,000 fragment limit in the ON_DEMAND mode. ON_DEMAND : For sessions of this type, the MPEG-DASH manifest contains all the fragments for the session, up to the number that is specified in MaxManifestFragmentResults. The manifest must be retrieved only once for each session. When this type of session is played in a media player, the user interface typically displays a scrubber control for choosing the position in the playback window to display. In all playback modes, if FragmentSelectorType is PRODUCER_TIMESTAMP, and if there are multiple fragments with the same start timestamp, the fragment that has the larger fragment number (that is, the newer fragment) is included in the MPEG-DASH manifest. The other fragments are not included. Fragments that have different timestamps but have overlapping durations are still included in the MPEG-DASH manifest. This can lead to unexpected behavior in the media player. The default is LIVE.
  --display-fragment-timestamp: string@display-fragment-timestamp-completer # Per the MPEG-DASH specification, the wall-clock time of fragments in the manifest file can be derived using attributes in the manifest itself. However, typically, MPEG-DASH compatible media players do not properly handle gaps in the media timeline. Kinesis Video Streams adjusts the media timeline in the manifest file to enable playback of media with discontinuities. Therefore, the wall-clock time derived from the manifest file may be inaccurate. If DisplayFragmentTimestamp is set to ALWAYS, the accurate fragment timestamp is added to each S element in the manifest file with the attribute name “kvs:ts”. A custom MPEG-DASH media player is necessary to leverage this custom attribute. The default value is NEVER. When DASHFragmentSelector is SERVER_TIMESTAMP, the timestamps will be the server start timestamps. Similarly, when DASHFragmentSelector is PRODUCER_TIMESTAMP, the timestamps will be the producer start timestamps.
  --display-fragment-number: string@display-fragment-number-completer # Fragments are identified in the manifest file based on their sequence number in the session. If DisplayFragmentNumber is set to ALWAYS, the Kinesis Video Streams fragment number is added to each S element in the manifest file with the attribute name “kvs:fn”. These fragment numbers can be used for logging or for use with other APIs (e.g. GetMedia and GetMediaForFragmentList). A custom MPEG-DASH media player is necessary to leverage these this custom attribute. The default value is NEVER.
  --dash-fragment-selector: record # Contains the range of timestamps for the requested media, and the source of the timestamps. — shape: {FragmentSelectorType?: "PRODUCER_TIMESTAMP"|"SERVER_TIMESTAMP", TimestampRange?: record}
  --expires: int # The time in seconds until the requested session expires. This value can be between 300 (5 minutes) and 43200 (12 hours). When a session expires, no new calls to GetDashManifest, GetMP4InitFragment, or GetMP4MediaFragment can be made for that session. The default is 300 (5 minutes).
  --max-manifest-fragment-results: int # The maximum number of fragments that are returned in the MPEG-DASH manifest. When the PlaybackMode is LIVE, the most recent fragments are returned up to this value. When the PlaybackMode is ON_DEMAND, the oldest fragments are returned, up to this maximum number. When there are a higher number of fragments available in a live MPEG-DASH manifest, video players often buffer content before starting playback. Increasing the buffer size increases the playback latency, but it decreases the likelihood that rebuffering will occur during playback. We recommend that a live MPEG-DASH manifest have a minimum of 3 fragments and a maximum of 10 fragments. The default is 5 fragments if PlaybackMode is LIVE or LIVE_REPLAY, and 1,000 if PlaybackMode is ON_DEMAND. The maximum value of 1,000 fragments corresponds to more than 16 minutes of video on streams with 1-second fragments, and more than 2 1/2 hours of video on streams with 10-second fragments.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getDASHStreamingSessionURL"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: StreamARN, var: stream_arn}, {name: PlaybackMode, var: playback_mode}, {name: DisplayFragmentTimestamp, var: display_fragment_timestamp}, {name: DisplayFragmentNumber, var: display_fragment_number}, {name: DASHFragmentSelector, var: dash_fragment_selector}, {name: Expires, var: expires}, {name: MaxManifestFragmentResults, var: max_manifest_fragment_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, stream_name: $stream_name, stream_arn: $stream_arn, playback_mode: $playback_mode, display_fragment_timestamp: $display_fragment_timestamp, display_fragment_number: $display_fragment_number, dash_fragment_selector: $dash_fragment_selector, expires: $expires, max_manifest_fragment_results: $max_manifest_fragment_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an HTTP Live Streaming (HLS) URL for the stream. You can then open the URL in a browser or media player to view the stream contents. Both the StreamName and the StreamARN parameters are optional, but you must specify either the StreamName or the StreamARN when invoking this API operation. An Amazon Kinesis video stream has the following requirements for providing data through HLS: The media must contain h.264 or h.265 encoded video and, optionally, AAC encoded audio. Specifically, the codec ID of track 1 should be V_MPEG/ISO/AVC (for h.264) or V_MPEG/ISO/HEVC (for h.265). Optionally, the codec ID of track 2 should be A_AAC. Data retention must be greater than 0. The video track of each fragment must contain codec private data in the Advanced Video Coding (AVC) for H.264 format or HEVC for H.265 format (MPEG-4 specification ISO/IEC 14496-15 (https://www.iso.org/standard/55980.html)). For information about adapting stream data to a given format, see NAL Adaptation Flags (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/producer-reference-nal.html). The audio track (if present) of each fragment must contain codec private data in the AAC format (AAC specification ISO/IEC 13818-7 (https://www.iso.org/standard/43345.html)). Kinesis Video Streams HLS sessions contain fragments in the fragmented MPEG-4 form (also called fMP4 or CMAF) or the MPEG-2 form (also called TS chunks, which the HLS specification also supports). For more information about HLS fragment types, see the HLS specification (https://tools.ietf.org/html/draft-pantos-http-live-streaming-23). The following procedure shows how to use HLS with Kinesis Video Streams: Get an endpoint using GetDataEndpoint (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/API_GetDataEndpoint.html), specifying GET_HLS_STREAMING_SESSION_URL for the APIName parameter. Retrieve the HLS URL using GetHLSStreamingSessionURL. Kinesis Video Streams creates an HLS streaming session to be used for accessing content in a stream using the HLS protocol. GetHLSStreamingSessionURL returns an authenticated URL (that includes an encrypted session token) for the session's HLS master playlist (the root resource needed for streaming with HLS). Don't share or store this token where an unauthorized entity could access it. The token provides access to the content of the stream. Safeguard the token with the same measures that you would use with your AWS credentials. The media that is made available through the playlist consists only of the requested stream, time range, and format. No other media data (such as frames outside the requested window or alternate bitrates) is made available. Provide the URL (containing the encrypted session token) for the HLS master playlist to a media player that supports the HLS protocol. Kinesis Video Streams makes the HLS media playlist, initialization fragment, and media fragments available through the master playlist URL. The initialization fragment contains the codec private data for the stream, and other data needed to set up the video or audio decoder and renderer. The media fragments contain H.264-encoded video frames or AAC-encoded audio samples. The media player receives the authenticated URL and requests stream metadata and media data normally. When the media player requests data, it calls the following actions: GetHLSMasterPlaylist: Retrieves an HLS master playlist, which contains a URL for the GetHLSMediaPlaylist action for each track, and additional metadata for the media player, including estimated bitrate and resolution. GetHLSMediaPlaylist: Retrieves an HLS media playlist, which contains a URL to access the MP4 initialization fragment with the GetMP4InitFragment action, and URLs to access the MP4 media fragments with the GetMP4MediaFragment actions. The HLS media playlist also contains metadata about the stream that the player needs to play it, such as whether the PlaybackMode is LIVE or ON_DEMAND. The HLS media playlist is typically static for sessions with a PlaybackType of ON_DEMAND. The HLS media playlist is continually updated with new fragments for sessions with a PlaybackType of LIVE. There is a distinct HLS media playlist for the video track and the audio track (if applicable) that contains MP4 media URLs for the specific track. GetMP4InitFragment: Retrieves the MP4 initialization fragment. The media player typically loads the initialization fragment before loading any media fragments. This fragment contains the "fytp" and "moov" MP4 atoms, and the child atoms that are needed to initialize the media player decoder. The initialization fragment does not correspond to a fragment in a Kinesis video stream. It contains only the codec private data for the stream and respective track, which the media player needs to decode the media frames. GetMP4MediaFragment: Retrieves MP4 media fragments. These fragments contain the "moof" and "mdat" MP4 atoms and their child atoms, containing the encoded fragment's media frames and their timestamps. After the first media fragment is made available in a streaming session, any fragments that don't contain the same codec private data cause an error to be returned when those different media fragments are loaded. Therefore, the codec private data should not change between fragments in a session. This also means that the session fails if the fragments in a stream change from having only video to having both audio and video. Data retrieved with this action is billable. See Pricing (https://aws.amazon.com/kinesis/video-streams/pricing/) for details. GetTSFragment: Retrieves MPEG TS fragments containing both initialization and media data for all tracks in the stream. If the ContainerFormat is MPEG_TS, this API is used instead of GetMP4InitFragment and GetMP4MediaFragment to retrieve stream media. Data retrieved with this action is billable. For more information, see Kinesis Video Streams pricing (https://aws.amazon.com/kinesis/video-streams/pricing/). A streaming session URL must not be shared between players. The service might throttle a session if multiple media players are sharing it. For connection limits, see Kinesis Video Streams Limits (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/limits.html). You can monitor the amount of data that the media player consumes by monitoring the GetMP4MediaFragment.OutgoingBytes Amazon CloudWatch metric. For information about using CloudWatch to monitor Kinesis Video Streams, see Monitoring Kinesis Video Streams (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/monitoring.html). For pricing information, see Amazon Kinesis Video Streams Pricing (https://aws.amazon.com/kinesis/video-streams/pricing/) and AWS Pricing (https://aws.amazon.com/pricing/). Charges for both HLS sessions and outgoing AWS data apply. For more information about HLS, see HTTP Live Streaming (https://developer.apple.com/streaming/) on the Apple Developer site (https://developer.apple.com). If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: x-amz-ErrorType HTTP header – contains a more specific error type in addition to what the HTTP status code provides. x-amz-RequestId HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id. Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again. For more information, see the Errors section at the bottom of this topic, as well as Common Errors (https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html).
#
# POST /getHLSStreamingSessionURL
# Returns: record<HLSStreamingSessionURL: string>
# operationId: GetHLSStreamingSessionURL
export def "get-hls-streaming-session-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --stream-name: string # The name of the stream for which to retrieve the HLS master playlist URL. You must specify either the StreamName or the StreamARN.
  --stream-arn: string # The Amazon Resource Name (ARN) of the stream for which to retrieve the HLS master playlist URL. You must specify either the StreamName or the StreamARN.
  --playback-mode: string@playback-mode-completer # Whether to retrieve live, live replay, or archived, on-demand data. Features of the three types of sessions include the following: LIVE : For sessions of this type, the HLS media playlist is continually updated with the latest fragments as they become available. We recommend that the media player retrieve a new playlist on a one-second interval. When this type of session is played in a media player, the user interface typically displays a "live" notification, with no scrubber control for choosing the position in the playback window to display. In LIVE mode, the newest available fragments are included in an HLS media playlist, even if there is a gap between fragments (that is, if a fragment is missing). A gap like this might cause a media player to halt or cause a jump in playback. In this mode, fragments are not added to the HLS media playlist if they are older than the newest fragment in the playlist. If the missing fragment becomes available after a subsequent fragment is added to the playlist, the older fragment is not added, and the gap is not filled. LIVE_REPLAY : For sessions of this type, the HLS media playlist is updated similarly to how it is updated for LIVE mode except that it starts by including fragments from a given start time. Instead of fragments being added as they are ingested, fragments are added as the duration of the next fragment elapses. For example, if the fragments in the session are two seconds long, then a new fragment is added to the media playlist every two seconds. This mode is useful to be able to start playback from when an event is detected and continue live streaming media that has not yet been ingested as of the time of the session creation. This mode is also useful to stream previously archived media without being limited by the 1,000 fragment limit in the ON_DEMAND mode. ON_DEMAND : For sessions of this type, the HLS media playlist contains all the fragments for the session, up to the number that is specified in MaxMediaPlaylistFragmentResults. The playlist must be retrieved only once for each session. When this type of session is played in a media player, the user interface typically displays a scrubber control for choosing the position in the playback window to display. In all playback modes, if FragmentSelectorType is PRODUCER_TIMESTAMP, and if there are multiple fragments with the same start timestamp, the fragment that has the largest fragment number (that is, the newest fragment) is included in the HLS media playlist. The other fragments are not included. Fragments that have different timestamps but have overlapping durations are still included in the HLS media playlist. This can lead to unexpected behavior in the media player. The default is LIVE.
  --hls-fragment-selector: record # Contains the range of timestamps for the requested media, and the source of the timestamps. — shape: {FragmentSelectorType?: "PRODUCER_TIMESTAMP"|"SERVER_TIMESTAMP", TimestampRange?: record}
  --container-format: string@container-format-completer # Specifies which format should be used for packaging the media. Specifying the FRAGMENTED_MP4 container format packages the media into MP4 fragments (fMP4 or CMAF). This is the recommended packaging because there is minimal packaging overhead. The other container format option is MPEG_TS. HLS has supported MPEG TS chunks since it was released and is sometimes the only supported packaging on older HLS players. MPEG TS typically has a 5-25 percent packaging overhead. This means MPEG TS typically requires 5-25 percent more bandwidth and cost than fMP4. The default is FRAGMENTED_MP4.
  --discontinuity-mode: string@discontinuity-mode-completer # Specifies when flags marking discontinuities between fragments are added to the media playlists. Media players typically build a timeline of media content to play, based on the timestamps of each fragment. This means that if there is any overlap or gap between fragments (as is typical if HLSFragmentSelector is set to SERVER_TIMESTAMP), the media player timeline will also have small gaps between fragments in some places, and will overwrite frames in other places. Gaps in the media player timeline can cause playback to stall and overlaps can cause playback to be jittery. When there are discontinuity flags between fragments, the media player is expected to reset the timeline, resulting in the next fragment being played immediately after the previous fragment. The following modes are supported: ALWAYS: a discontinuity marker is placed between every fragment in the HLS media playlist. It is recommended to use a value of ALWAYS if the fragment timestamps are not accurate. NEVER: no discontinuity markers are placed anywhere. It is recommended to use a value of NEVER to ensure the media player timeline most accurately maps to the producer timestamps. ON_DISCONTINUITY: a discontinuity marker is placed between fragments that have a gap or overlap of more than 50 milliseconds. For most playback scenarios, it is recommended to use a value of ON_DISCONTINUITY so that the media player timeline is only reset when there is a significant issue with the media timeline (e.g. a missing fragment). The default is ALWAYS when HLSFragmentSelector is set to SERVER_TIMESTAMP, and NEVER when it is set to PRODUCER_TIMESTAMP.
  --display-fragment-timestamp: string@display-fragment-timestamp-completer # Specifies when the fragment start timestamps should be included in the HLS media playlist. Typically, media players report the playhead position as a time relative to the start of the first fragment in the playback session. However, when the start timestamps are included in the HLS media playlist, some media players might report the current playhead as an absolute time based on the fragment timestamps. This can be useful for creating a playback experience that shows viewers the wall-clock time of the media. The default is NEVER. When HLSFragmentSelector is SERVER_TIMESTAMP, the timestamps will be the server start timestamps. Similarly, when HLSFragmentSelector is PRODUCER_TIMESTAMP, the timestamps will be the producer start timestamps.
  --expires: int # The time in seconds until the requested session expires. This value can be between 300 (5 minutes) and 43200 (12 hours). When a session expires, no new calls to GetHLSMasterPlaylist, GetHLSMediaPlaylist, GetMP4InitFragment, GetMP4MediaFragment, or GetTSFragment can be made for that session. The default is 300 (5 minutes).
  --max-media-playlist-fragment-results: int # The maximum number of fragments that are returned in the HLS media playlists. When the PlaybackMode is LIVE, the most recent fragments are returned up to this value. When the PlaybackMode is ON_DEMAND, the oldest fragments are returned, up to this maximum number. When there are a higher number of fragments available in a live HLS media playlist, video players often buffer content before starting playback. Increasing the buffer size increases the playback latency, but it decreases the likelihood that rebuffering will occur during playback. We recommend that a live HLS media playlist have a minimum of 3 fragments and a maximum of 10 fragments. The default is 5 fragments if PlaybackMode is LIVE or LIVE_REPLAY, and 1,000 if PlaybackMode is ON_DEMAND. The maximum value of 5,000 fragments corresponds to more than 80 minutes of video on streams with 1-second fragments, and more than 13 hours of video on streams with 10-second fragments.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getHLSStreamingSessionURL"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: StreamARN, var: stream_arn}, {name: PlaybackMode, var: playback_mode}, {name: HLSFragmentSelector, var: hls_fragment_selector}, {name: ContainerFormat, var: container_format}, {name: DiscontinuityMode, var: discontinuity_mode}, {name: DisplayFragmentTimestamp, var: display_fragment_timestamp}, {name: Expires, var: expires}, {name: MaxMediaPlaylistFragmentResults, var: max_media_playlist_fragment_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, stream_name: $stream_name, stream_arn: $stream_arn, playback_mode: $playback_mode, hls_fragment_selector: $hls_fragment_selector, container_format: $container_format, discontinuity_mode: $discontinuity_mode, display_fragment_timestamp: $display_fragment_timestamp, expires: $expires, max_media_playlist_fragment_results: $max_media_playlist_fragment_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of Images corresponding to each timestamp for a given time range, sampling interval, and image format configuration.
#
# POST /getImages
# Returns: record<Images: table<TimeStamp: string, Error: string, ImageContent: string>, NextToken: string>
# operationId: GetImages
export def "get-images" [
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
  --stream-name: string # The name of the stream from which to retrieve the images. You must specify either the StreamName or the StreamARN.
  --stream-arn: string # The Amazon Resource Name (ARN) of the stream from which to retrieve the images. You must specify either the StreamName or the StreamARN.
  image_selector_type: string@image-selector-type-completer # The origin of the Server or Producer timestamps to use to generate the images.
  start_timestamp: string # The starting point from which the images should be generated. This StartTimestamp must be within an inclusive range of timestamps for an image to be returned. (format: date-time)
  end_timestamp: string # The end timestamp for the range of images to be generated. (format: date-time)
  sampling_interval: int # The time interval in milliseconds (ms) at which the images need to be generated from the stream. The minimum value that can be provided is 3000 ms. If the timestamp range is less than the sampling interval, the Image from the startTimestamp will be returned if available. The minimum value of 3000 ms is a soft limit. If needed, a lower sampling frequency can be requested.
  format: string@format-completer # The format that will be used to encode the image.
  --format-config: record # The list of a key-value pair structure that contains extra parameters that can be applied when the image is generated. The FormatConfig key is the JPEGQuality, which indicates the JPEG quality key to be used to generate the image. The FormatConfig value accepts ints from 1 to 100. If the value is 1, the image will be generated with less quality and the best compression. If the value is 100, the image will be generated with the best quality and less compression. If no value is provided, the default value of the JPEGQuality key will be set to 80.
  --width-pixels: int # The width of the output image that is used in conjunction with the HeightPixels parameter. When both WidthPixels and HeightPixels parameters are provided, the image will be stretched to fit the specified aspect ratio. If only the WidthPixels parameter is provided or if only the HeightPixels is provided, a ValidationException will be thrown. If neither parameter is provided, the original image size from the stream will be returned.
  --height-pixels: int # The height of the output image that is used in conjunction with the WidthPixels parameter. When both HeightPixels and WidthPixels parameters are provided, the image will be stretched to fit the specified aspect ratio. If only the HeightPixels parameter is provided, its original aspect ratio will be used to calculate the WidthPixels ratio. If neither parameter is provided, the original image size will be returned.
  --body-max-results: int # The maximum number of images to be returned by the API. The default limit is 100 images per API response. The additional results will be paginated. (spec name: MaxResults)
  --body-next-token: string # A token that specifies where to start paginating the next set of Images. This is the GetImages:NextToken from a previously truncated response. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getImages"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: StreamARN, var: stream_arn}, {name: ImageSelectorType, var: image_selector_type}, {name: StartTimestamp, var: start_timestamp}, {name: EndTimestamp, var: end_timestamp}, {name: SamplingInterval, var: sampling_interval}, {name: Format, var: format}, {name: FormatConfig, var: format_config}, {name: WidthPixels, var: width_pixels}, {name: HeightPixels, var: height_pixels}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, stream_name: $stream_name, stream_arn: $stream_arn, image_selector_type: $image_selector_type, start_timestamp: $start_timestamp, end_timestamp: $end_timestamp, sampling_interval: $sampling_interval, format: $format, format_config: $format_config, width_pixels: $width_pixels, height_pixels: $height_pixels, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets media for a list of fragments (specified by fragment number) from the archived data in an Amazon Kinesis video stream. You must first call the GetDataEndpoint API to get an endpoint. Then send the GetMediaForFragmentList requests to this endpoint using the --endpoint-url parameter (https://docs.aws.amazon.com/cli/latest/reference/). For limits, see Kinesis Video Streams Limits (http://docs.aws.amazon.com/kinesisvideostreams/latest/dg/limits.html). If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: x-amz-ErrorType HTTP header – contains a more specific error type in addition to what the HTTP status code provides. x-amz-RequestId HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id. Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again. For more information, see the Errors section at the bottom of this topic, as well as Common Errors (https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html).
#
# POST /getMediaForFragmentList
# Returns: record<Payload: string>
# operationId: GetMediaForFragmentList
export def "get-media-for-fragment-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --stream-name: string # The name of the stream from which to retrieve fragment media. Specify either this parameter or the StreamARN parameter.
  --stream-arn: string # The Amazon Resource Name (ARN) of the stream from which to retrieve fragment media. Specify either this parameter or the StreamName parameter.
  fragments: list<string> # A list of the numbers of fragments for which to retrieve media. You retrieve these values with ListFragments.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getMediaForFragmentList"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: StreamARN, var: stream_arn}, {name: Fragments, var: fragments}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, stream_name: $stream_name, stream_arn: $stream_arn, fragments: $fragments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of Fragment objects from the specified stream and timestamp range within the archived data. Listing fragments is eventually consistent. This means that even if the producer receives an acknowledgment that a fragment is persisted, the result might not be returned immediately from a request to ListFragments. However, results are typically available in less than one second. You must first call the GetDataEndpoint API to get an endpoint. Then send the ListFragments requests to this endpoint using the --endpoint-url parameter (https://docs.aws.amazon.com/cli/latest/reference/). If an error is thrown after invoking a Kinesis Video Streams archived media API, in addition to the HTTP status code and the response body, it includes the following pieces of information: x-amz-ErrorType HTTP header – contains a more specific error type in addition to what the HTTP status code provides. x-amz-RequestId HTTP header – if you want to report an issue to AWS, the support team can better diagnose the problem if given the Request Id. Both the HTTP status code and the ErrorType header can be utilized to make programmatic decisions about whether errors are retry-able and under what conditions, as well as provide information on what actions the client programmer might need to take in order to successfully try again. For more information, see the Errors section at the bottom of this topic, as well as Common Errors (https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/CommonErrors.html).
#
# POST /listFragments
# Returns: record<Fragments: table<FragmentNumber: string, FragmentSizeInBytes: int, ProducerTimestamp: string, ServerTimestamp: string, FragmentLengthInMilliseconds: int>, NextToken: string>
# operationId: ListFragments
export def "list-fragments" [
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
  --stream-name: string # The name of the stream from which to retrieve a fragment list. Specify either this parameter or the StreamARN parameter.
  --stream-arn: string # The Amazon Resource Name (ARN) of the stream from which to retrieve a fragment list. Specify either this parameter or the StreamName parameter.
  --body-max-results: int # The total number of fragments to return. If the total number of fragments available is more than the value specified in max-results, then a ListFragmentsOutput$NextToken is provided in the output that you can use to resume pagination. (spec name: MaxResults)
  --body-next-token: string # A token to specify where to start paginating. This is the ListFragmentsOutput$NextToken from a previously truncated response. (spec name: NextToken)
  --fragment-selector: record # Describes the timestamp range and timestamp origin of a range of fragments. Only fragments with a start timestamp greater than or equal to the given start time and less than or equal to the end time are returned. For example, if a stream contains fragments with the following start timestamps: 00:00:00 00:00:02 00:00:04 00:00:06 A fragment selector range with a start time of 00:00:01 and end time of 00:00:04 would return the fragments with start times of 00:00:02 and 00:00:04. — shape: {FragmentSelectorType?: "PRODUCER_TIMESTAMP"|"SERVER_TIMESTAMP", TimestampRange?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/listFragments"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: StreamName, var: stream_name}, {name: StreamARN, var: stream_arn}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}, {name: FragmentSelector, var: fragment_selector}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, stream_name: $stream_name, stream_arn: $stream_arn, body_max_results: $body_max_results, body_next_token: $body_next_token, fragment_selector: $fragment_selector
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
