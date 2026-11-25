# Auto-generated client for Amazon Elastic Transcoder v2012-09-25
# Source: https://api.apis.guru/v2/specs/amazonaws.com/elastictranscoder/2012-09-25/openapi.json
# Auth: --token flag or $env.AMAZON_ELASTIC_TRANSCODER_TOKEN

const CLIENT = {
  base_url: "http://elastictranscoder.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_ELASTIC_TRANSCODER_TOKEN"
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

def base-url-completer [] { ["http://elastictranscoder.us-east-1.amazonaws.com" "http://elastictranscoder.us-east-2.amazonaws.com" "http://elastictranscoder.us-west-1.amazonaws.com" "http://elastictranscoder.us-west-2.amazonaws.com" "http://elastictranscoder.us-gov-west-1.amazonaws.com" "http://elastictranscoder.us-gov-east-1.amazonaws.com" "http://elastictranscoder.ca-central-1.amazonaws.com" "http://elastictranscoder.eu-north-1.amazonaws.com" "http://elastictranscoder.eu-west-1.amazonaws.com" "http://elastictranscoder.eu-west-2.amazonaws.com" "http://elastictranscoder.eu-west-3.amazonaws.com" "http://elastictranscoder.eu-central-1.amazonaws.com" "http://elastictranscoder.eu-south-1.amazonaws.com" "http://elastictranscoder.af-south-1.amazonaws.com" "http://elastictranscoder.ap-northeast-1.amazonaws.com" "http://elastictranscoder.ap-northeast-2.amazonaws.com" "http://elastictranscoder.ap-northeast-3.amazonaws.com" "http://elastictranscoder.ap-southeast-1.amazonaws.com" "http://elastictranscoder.ap-southeast-2.amazonaws.com" "http://elastictranscoder.ap-east-1.amazonaws.com" "http://elastictranscoder.ap-south-1.amazonaws.com" "http://elastictranscoder.sa-east-1.amazonaws.com" "http://elastictranscoder.me-south-1.amazonaws.com" "https://elastictranscoder.us-east-1.amazonaws.com" "https://elastictranscoder.us-east-2.amazonaws.com" "https://elastictranscoder.us-west-1.amazonaws.com" "https://elastictranscoder.us-west-2.amazonaws.com" "https://elastictranscoder.us-gov-west-1.amazonaws.com" "https://elastictranscoder.us-gov-east-1.amazonaws.com" "https://elastictranscoder.ca-central-1.amazonaws.com" "https://elastictranscoder.eu-north-1.amazonaws.com" "https://elastictranscoder.eu-west-1.amazonaws.com" "https://elastictranscoder.eu-west-2.amazonaws.com" "https://elastictranscoder.eu-west-3.amazonaws.com" "https://elastictranscoder.eu-central-1.amazonaws.com" "https://elastictranscoder.eu-south-1.amazonaws.com" "https://elastictranscoder.af-south-1.amazonaws.com" "https://elastictranscoder.ap-northeast-1.amazonaws.com" "https://elastictranscoder.ap-northeast-2.amazonaws.com" "https://elastictranscoder.ap-northeast-3.amazonaws.com" "https://elastictranscoder.ap-southeast-1.amazonaws.com" "https://elastictranscoder.ap-southeast-2.amazonaws.com" "https://elastictranscoder.ap-east-1.amazonaws.com" "https://elastictranscoder.ap-south-1.amazonaws.com" "https://elastictranscoder.sa-east-1.amazonaws.com" "https://elastictranscoder.me-south-1.amazonaws.com" "http://elastictranscoder.cn-north-1.amazonaws.com.cn" "http://elastictranscoder.cn-northwest-1.amazonaws.com.cn" "https://elastictranscoder.cn-north-1.amazonaws.com.cn" "https://elastictranscoder.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    cancel-job: "record"
    read-job: "record<Job: record<Id: string, Arn: string, PipelineId: string, Input: record<Key: string, FrameRate: string, Resolution: string, AspectRatio: string, Interlaced: string, Container: string, Encryption: record, TimeSpan: record, InputCaptions: record, DetectedProperties: record>, Inputs: list<record>, Output: record<Id: string, Key: string, ThumbnailPattern: string, ThumbnailEncryption: record, Rotate: string, PresetId: string, SegmentDuration: string, Status: string, StatusDetail: string, Duration: int, Width: int, Height: int, FrameRate: string, FileSize: int, DurationMillis: int, Watermarks: list, AlbumArt: record, Composition: list, Captions: record, Encryption: record, AppliedColorSpaceConversion: string>, Outputs: list<record>, OutputKeyPrefix: string, Playlists: list<record>, Status: string, UserMetadata: record, Timing: record<SubmitTimeMillis: int, StartTimeMillis: int, FinishTimeMillis: int>>>"
    create-job: "record<Job: record<Id: string, Arn: string, PipelineId: string, Input: record<Key: string, FrameRate: string, Resolution: string, AspectRatio: string, Interlaced: string, Container: string, Encryption: record, TimeSpan: record, InputCaptions: record, DetectedProperties: record>, Inputs: list<record>, Output: record<Id: string, Key: string, ThumbnailPattern: string, ThumbnailEncryption: record, Rotate: string, PresetId: string, SegmentDuration: string, Status: string, StatusDetail: string, Duration: int, Width: int, Height: int, FrameRate: string, FileSize: int, DurationMillis: int, Watermarks: list, AlbumArt: record, Composition: list, Captions: record, Encryption: record, AppliedColorSpaceConversion: string>, Outputs: list<record>, OutputKeyPrefix: string, Playlists: list<record>, Status: string, UserMetadata: record, Timing: record<SubmitTimeMillis: int, StartTimeMillis: int, FinishTimeMillis: int>>>"
    create-pipeline: "record<Pipeline: record<Id: string, Arn: string, Name: string, Status: string, InputBucket: string, OutputBucket: string, Role: string, AwsKmsKeyArn: string, Notifications: record<Progressing: string, Completed: string, Warning: string, Error: string>, ContentConfig: record<Bucket: string, StorageClass: string, Permissions: list>, ThumbnailConfig: record<Bucket: string, StorageClass: string, Permissions: list>>, Warnings: table<Code: string, Message: string>>"
    list-pipelines: "record<Pipelines: table<Id: string, Arn: string, Name: string, Status: string, InputBucket: string, OutputBucket: string, Role: string, AwsKmsKeyArn: string, Notifications: record, ContentConfig: record, ThumbnailConfig: record>, NextPageToken: string>"
    create-preset: "record<Preset: record<Id: string, Arn: string, Name: string, Description: string, Container: string, Audio: record<Codec: string, SampleRate: string, BitRate: string, Channels: string, AudioPackingMode: string, CodecOptions: record>, Video: record<Codec: string, CodecOptions: record, KeyframesMaxDist: string, FixedGOP: string, BitRate: string, FrameRate: string, MaxFrameRate: string, Resolution: string, AspectRatio: string, MaxWidth: string, MaxHeight: string, DisplayAspectRatio: string, SizingPolicy: string, PaddingPolicy: string, Watermarks: list>, Thumbnails: record<Format: string, Interval: string, Resolution: string, AspectRatio: string, MaxWidth: string, MaxHeight: string, SizingPolicy: string, PaddingPolicy: string>, Type: string>, Warning: string>"
    list-presets: "record<Presets: table<Id: string, Arn: string, Name: string, Description: string, Container: string, Audio: record, Video: record, Thumbnails: record, Type: string>, NextPageToken: string>"
    delete-pipeline: "record"
    read-pipeline: "record<Pipeline: record<Id: string, Arn: string, Name: string, Status: string, InputBucket: string, OutputBucket: string, Role: string, AwsKmsKeyArn: string, Notifications: record<Progressing: string, Completed: string, Warning: string, Error: string>, ContentConfig: record<Bucket: string, StorageClass: string, Permissions: list>, ThumbnailConfig: record<Bucket: string, StorageClass: string, Permissions: list>>, Warnings: table<Code: string, Message: string>>"
    update-pipeline: "record<Pipeline: record<Id: string, Arn: string, Name: string, Status: string, InputBucket: string, OutputBucket: string, Role: string, AwsKmsKeyArn: string, Notifications: record<Progressing: string, Completed: string, Warning: string, Error: string>, ContentConfig: record<Bucket: string, StorageClass: string, Permissions: list>, ThumbnailConfig: record<Bucket: string, StorageClass: string, Permissions: list>>, Warnings: table<Code: string, Message: string>>"
    delete-preset: "record"
    read-preset: "record<Preset: record<Id: string, Arn: string, Name: string, Description: string, Container: string, Audio: record<Codec: string, SampleRate: string, BitRate: string, Channels: string, AudioPackingMode: string, CodecOptions: record>, Video: record<Codec: string, CodecOptions: record, KeyframesMaxDist: string, FixedGOP: string, BitRate: string, FrameRate: string, MaxFrameRate: string, Resolution: string, AspectRatio: string, MaxWidth: string, MaxHeight: string, DisplayAspectRatio: string, SizingPolicy: string, PaddingPolicy: string, Watermarks: list>, Thumbnails: record<Format: string, Interval: string, Resolution: string, AspectRatio: string, MaxWidth: string, MaxHeight: string, SizingPolicy: string, PaddingPolicy: string>, Type: string>>"
    list-jobs-by-pipeline: "record<Jobs: table<Id: string, Arn: string, PipelineId: string, Input: record, Inputs: list, Output: record, Outputs: list, OutputKeyPrefix: string, Playlists: list, Status: string, UserMetadata: record, Timing: record>, NextPageToken: string>"
    list-jobs-by-status: "record<Jobs: table<Id: string, Arn: string, PipelineId: string, Input: record, Inputs: list, Output: record, Outputs: list, OutputKeyPrefix: string, Playlists: list, Status: string, UserMetadata: record, Timing: record>, NextPageToken: string>"
    test-role: "record<Success: string, Messages: list<string>>"
    update-pipeline-notifications: "record<Pipeline: record<Id: string, Arn: string, Name: string, Status: string, InputBucket: string, OutputBucket: string, Role: string, AwsKmsKeyArn: string, Notifications: record<Progressing: string, Completed: string, Warning: string, Error: string>, ContentConfig: record<Bucket: string, StorageClass: string, Permissions: list>, ThumbnailConfig: record<Bucket: string, StorageClass: string, Permissions: list>>>"
    update-pipeline-status: "record<Pipeline: record<Id: string, Arn: string, Name: string, Status: string, InputBucket: string, OutputBucket: string, Role: string, AwsKmsKeyArn: string, Notifications: record<Progressing: string, Completed: string, Warning: string, Error: string>, ContentConfig: record<Bucket: string, StorageClass: string, Permissions: list>, ThumbnailConfig: record<Bucket: string, StorageClass: string, Permissions: list>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["cancel-job" "read-job" "create-job" "create-pipeline" "list-pipelines" "create-preset" "list-presets" "delete-pipeline" "read-pipeline" "update-pipeline" "delete-preset" "read-preset" "list-jobs-by-pipeline" "list-jobs-by-status" "test-role" "update-pipeline-notifications" "update-pipeline-status" "commands"] | sort) } | get name | first)
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

# The CancelJob operation cancels an unfinished job. You can only cancel a job that has a status of Submitted. To prevent a pipeline from starting to process a job while you're getting the job identifier, use UpdatePipelineStatus to temporarily pause the pipeline.
#
# DELETE /2012-09-25/jobs/{Id}
# Returns: record
# operationId: CancelJob
export def "cancel-job" [
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
    path: "/2012-09-25/jobs/{Id}"
    path_params: [{name: Id, var: id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ReadJob operation returns detailed information about a job.
#
# GET /2012-09-25/jobs/{Id}
# Returns: record<Job: record<Id: string, Arn: string, PipelineId: string, Input: record<Key: string, FrameRate: string, Resolution: string, AspectRatio: string, Interlaced: string, Container: string, Encryption: record, TimeSpan: record, InputCaptions: record, DetectedProperties: record>, Inputs: list<record>, Output: record<Id: string, Key: string, ThumbnailPattern: string, ThumbnailEncryption: record, Rotate: string, PresetId: string, SegmentDuration: string, Status: string, StatusDetail: string, Duration: int, Width: int, Height: int, FrameRate: string, FileSize: int, DurationMillis: int, Watermarks: list, AlbumArt: record, Composition: list, Captions: record, Encryption: record, AppliedColorSpaceConversion: string>, Outputs: list<record>, OutputKeyPrefix: string, Playlists: list<record>, Status: string, UserMetadata: record, Timing: record<SubmitTimeMillis: int, StartTimeMillis: int, FinishTimeMillis: int>>>
# operationId: ReadJob
export def "read-job" [
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
    method: get
    path: "/2012-09-25/jobs/{Id}"
    path_params: [{name: Id, var: id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# When you create a job, Elastic Transcoder returns JSON data that includes the values that you specified plus information about the job that is created. If you have specified more than one output for your jobs (for example, one output for the Kindle Fire and another output for the Apple iPhone 4s), you currently must use the Elastic Transcoder API to list the jobs (as opposed to the AWS Console).
#
# POST /2012-09-25/jobs
# Returns: record<Job: record<Id: string, Arn: string, PipelineId: string, Input: record<Key: string, FrameRate: string, Resolution: string, AspectRatio: string, Interlaced: string, Container: string, Encryption: record, TimeSpan: record, InputCaptions: record, DetectedProperties: record>, Inputs: list<record>, Output: record<Id: string, Key: string, ThumbnailPattern: string, ThumbnailEncryption: record, Rotate: string, PresetId: string, SegmentDuration: string, Status: string, StatusDetail: string, Duration: int, Width: int, Height: int, FrameRate: string, FileSize: int, DurationMillis: int, Watermarks: list, AlbumArt: record, Composition: list, Captions: record, Encryption: record, AppliedColorSpaceConversion: string>, Outputs: list<record>, OutputKeyPrefix: string, Playlists: list<record>, Status: string, UserMetadata: record, Timing: record<SubmitTimeMillis: int, StartTimeMillis: int, FinishTimeMillis: int>>>
# operationId: CreateJob
export def "create-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  pipeline_id: string # The Id of the pipeline that you want Elastic Transcoder to use for transcoding. The pipeline determines several settings, including the Amazon S3 bucket from which Elastic Transcoder gets the files to transcode and the bucket into which Elastic Transcoder puts the transcoded files.
  --input: record # Information about the file that you're transcoding. — shape: {Key?: string, FrameRate?: string, Resolution?: string, AspectRatio?: string, Interlaced?: string, Container?: string, Encryption?: record, TimeSpan?: record, InputCaptions?: record, DetectedProperties?: record}
  --inputs: list # A section of the request body that provides information about the files that are being transcoded. — item shape: {Key?: string, FrameRate?: string, Resolution?: string, AspectRatio?: string, Interlaced?: string, Container?: string, Encryption?: record, TimeSpan?: record, InputCaptions?: record, DetectedProperties?: record}
  --output: record # The CreateJobOutput structure. — shape: {Key?: string, ThumbnailPattern?: string, ThumbnailEncryption?: record, Rotate?: string, PresetId?: string, SegmentDuration?: string, Watermarks?: list, AlbumArt?: record, Composition?: list, Captions?: record, Encryption?: record}
  --outputs: list # A section of the request body that provides information about the transcoded (target) files. We recommend that you use the Outputs syntax instead of the Output syntax. — item shape: {Key?: string, ThumbnailPattern?: string, ThumbnailEncryption?: record, Rotate?: string, PresetId?: string, SegmentDuration?: string, Watermarks?: list, AlbumArt?: record, Composition?: list, Captions?: record, Encryption?: record}
  --output-key-prefix: string # The value, if any, that you want Elastic Transcoder to prepend to the names of all files that this job creates, including output files, thumbnails, and playlists.
  --playlists: list # If you specify a preset in PresetId for which the value of Container is fmp4 (Fragmented MP4) or ts (MPEG-TS), Playlists contains information about the master playlists that you want Elastic Transcoder to create. The maximum number of master playlists in a job is 30. — item shape: {Name?: string, Format?: string, OutputKeys?: list<string>, HlsContentProtection?: record, PlayReadyDrm?: record}
  --user-metadata: record # User-defined metadata that you want to associate with an Elastic Transcoder job. You specify metadata in key/value pairs, and you can add up to 10 key/value pairs per job. Elastic Transcoder does not guarantee that key/value pairs are returned in the same order in which you specify them.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2012-09-25/jobs"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: PipelineId, var: pipeline_id}, {name: Input, var: input}, {name: Inputs, var: inputs}, {name: Output, var: output}, {name: Outputs, var: outputs}, {name: OutputKeyPrefix, var: output_key_prefix}, {name: Playlists, var: playlists}, {name: UserMetadata, var: user_metadata}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, pipeline_id: $pipeline_id, input: $input, inputs: $inputs, output: $output, outputs: $outputs, output_key_prefix: $output_key_prefix, playlists: $playlists, user_metadata: $user_metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The CreatePipeline operation creates a pipeline with settings that you specify.
#
# POST /2012-09-25/pipelines
# Returns: record<Pipeline: record<Id: string, Arn: string, Name: string, Status: string, InputBucket: string, OutputBucket: string, Role: string, AwsKmsKeyArn: string, Notifications: record<Progressing: string, Completed: string, Warning: string, Error: string>, ContentConfig: record<Bucket: string, StorageClass: string, Permissions: list>, ThumbnailConfig: record<Bucket: string, StorageClass: string, Permissions: list>>, Warnings: table<Code: string, Message: string>>
# operationId: CreatePipeline
export def "create-pipeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The name of the pipeline. We recommend that the name be unique within the AWS account, but uniqueness is not enforced. Constraints: Maximum 40 characters.
  input_bucket: string # The Amazon S3 bucket in which you saved the media files that you want to transcode.
  --output-bucket: string # The Amazon S3 bucket in which you want Elastic Transcoder to save the transcoded files. (Use this, or use ContentConfig:Bucket plus ThumbnailConfig:Bucket.) Specify this value when all of the following are true: You want to save transcoded files, thumbnails (if any), and playlists (if any) together in one bucket. You do not want to specify the users or groups who have access to the transcoded files, thumbnails, and playlists. You do not want to specify the permissions that Elastic Transcoder grants to the files. When Elastic Transcoder saves files in OutputBucket, it grants full control over the files only to the AWS account that owns the role that is specified by Role. You want to associate the transcoded files and thumbnails with the Amazon S3 Standard storage class. If you want to save transcoded files and playlists in one bucket and thumbnails in another bucket, specify which users can access the transcoded files or the permissions the users have, or change the Amazon S3 storage class, omit OutputBucket and specify values for ContentConfig and ThumbnailConfig instead.
  role: string # The IAM Amazon Resource Name (ARN) for the role that you want Elastic Transcoder to use to create the pipeline.
  --aws-kms-key-arn: string # The AWS Key Management Service (AWS KMS) key that you want to use with this pipeline. If you use either s3 or s3-aws-kms as your Encryption:Mode, you don't need to provide a key with your job because a default key, known as an AWS-KMS key, is created for you automatically. You need to provide an AWS-KMS key only if you want to use a non-default AWS-KMS key, or if you are using an Encryption:Mode of aes-cbc-pkcs7, aes-ctr, or aes-gcm.
  --notifications: record # The Amazon Simple Notification Service (Amazon SNS) topic or topics to notify in order to report job status. To receive notifications, you must also subscribe to the new topic in the Amazon SNS console. — shape: {Progressing?: string, Completed?: string, Warning?: string, Error?: string}
  --content-config: record # The PipelineOutputConfig structure. — shape: {Bucket?: string, StorageClass?: string, Permissions?: list}
  --thumbnail-config: record # The PipelineOutputConfig structure. — shape: {Bucket?: string, StorageClass?: string, Permissions?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2012-09-25/pipelines"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: InputBucket, var: input_bucket}, {name: OutputBucket, var: output_bucket}, {name: Role, var: role}, {name: AwsKmsKeyArn, var: aws_kms_key_arn}, {name: Notifications, var: notifications}, {name: ContentConfig, var: content_config}, {name: ThumbnailConfig, var: thumbnail_config}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, input_bucket: $input_bucket, output_bucket: $output_bucket, role: $role, aws_kms_key_arn: $aws_kms_key_arn, notifications: $notifications, content_config: $content_config, thumbnail_config: $thumbnail_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ListPipelines operation gets a list of the pipelines associated with the current AWS account.
#
# GET /2012-09-25/pipelines
# Returns: record<Pipelines: table<Id: string, Arn: string, Name: string, Status: string, InputBucket: string, OutputBucket: string, Role: string, AwsKmsKeyArn: string, Notifications: record, ContentConfig: record, ThumbnailConfig: record>, NextPageToken: string>
# operationId: ListPipelines
export def "list-pipelines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascending: string # To list pipelines in chronological order by the date and time that they were created, enter true. To list pipelines in reverse chronological order, enter false.
  --page-token: string # When Elastic Transcoder returns more than one page of results, use pageToken in subsequent GET requests to get each successive page of results.
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
    path: "/2012-09-25/pipelines"
    query: [{name: Ascending, var: ascending}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ascending: $ascending, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The CreatePreset operation creates a preset with settings that you specify. Elastic Transcoder checks the CreatePreset settings to ensure that they meet Elastic Transcoder requirements and to determine whether they comply with H.264 standards. If your settings are not valid for Elastic Transcoder, Elastic Transcoder returns an HTTP 400 response (ValidationException) and does not create the preset. If the settings are valid for Elastic Transcoder but aren't strictly compliant with the H.264 standard, Elastic Transcoder creates the preset and returns a warning message in the response. This helps you determine whether your settings comply with the H.264 standard while giving you greater flexibility with respect to the video that Elastic Transcoder produces. Elastic Transcoder uses the H.264 video-compression format. For more information, see the International Telecommunication Union publication Recommendation ITU-T H.264: Advanced video coding for generic audiovisual services.
#
# POST /2012-09-25/presets
# Returns: record<Preset: record<Id: string, Arn: string, Name: string, Description: string, Container: string, Audio: record<Codec: string, SampleRate: string, BitRate: string, Channels: string, AudioPackingMode: string, CodecOptions: record>, Video: record<Codec: string, CodecOptions: record, KeyframesMaxDist: string, FixedGOP: string, BitRate: string, FrameRate: string, MaxFrameRate: string, Resolution: string, AspectRatio: string, MaxWidth: string, MaxHeight: string, DisplayAspectRatio: string, SizingPolicy: string, PaddingPolicy: string, Watermarks: list>, Thumbnails: record<Format: string, Interval: string, Resolution: string, AspectRatio: string, MaxWidth: string, MaxHeight: string, SizingPolicy: string, PaddingPolicy: string>, Type: string>, Warning: string>
# operationId: CreatePreset
export def "create-preset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The name of the preset. We recommend that the name be unique within the AWS account, but uniqueness is not enforced.
  --description: string # A description of the preset.
  container: string # The container type for the output file. Valid values include flac, flv, fmp4, gif, mp3, mp4, mpg, mxf, oga, ogg, ts, and webm.
  --video: record # The VideoParameters structure. — shape: {Codec?: string, CodecOptions?: record, KeyframesMaxDist?: string, FixedGOP?: string, BitRate?: string, FrameRate?: string, MaxFrameRate?: string, Resolution?: string, AspectRatio?: string, MaxWidth?: string, MaxHeight?: string, DisplayAspectRatio?: string, SizingPolicy?: string, PaddingPolicy?: string, Watermarks?: list}
  --audio: record # Parameters required for transcoding audio. — shape: {Codec?: string, SampleRate?: string, BitRate?: string, Channels?: string, AudioPackingMode?: string, CodecOptions?: record}
  --thumbnails: record # Thumbnails for videos. — shape: {Format?: string, Interval?: string, Resolution?: string, AspectRatio?: string, MaxWidth?: string, MaxHeight?: string, SizingPolicy?: string, PaddingPolicy?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2012-09-25/presets"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: Container, var: container}, {name: Video, var: video}, {name: Audio, var: audio}, {name: Thumbnails, var: thumbnails}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, container: $container, video: $video, audio: $audio, thumbnails: $thumbnails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ListPresets operation gets a list of the default presets included with Elastic Transcoder and the presets that you've added in an AWS region.
#
# GET /2012-09-25/presets
# Returns: record<Presets: table<Id: string, Arn: string, Name: string, Description: string, Container: string, Audio: record, Video: record, Thumbnails: record, Type: string>, NextPageToken: string>
# operationId: ListPresets
export def "list-presets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascending: string # To list presets in chronological order by the date and time that they were created, enter true. To list presets in reverse chronological order, enter false.
  --page-token: string # When Elastic Transcoder returns more than one page of results, use pageToken in subsequent GET requests to get each successive page of results.
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
    path: "/2012-09-25/presets"
    query: [{name: Ascending, var: ascending}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ascending: $ascending, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The DeletePipeline operation removes a pipeline. You can only delete a pipeline that has never been used or that is not currently in use (doesn't contain any active jobs). If the pipeline is currently in use, DeletePipeline returns an error.
#
# DELETE /2012-09-25/pipelines/{Id}
# Returns: record
# operationId: DeletePipeline
export def "delete-pipeline" [
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
    path: "/2012-09-25/pipelines/{Id}"
    path_params: [{name: Id, var: id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ReadPipeline operation gets detailed information about a pipeline.
#
# GET /2012-09-25/pipelines/{Id}
# Returns: record<Pipeline: record<Id: string, Arn: string, Name: string, Status: string, InputBucket: string, OutputBucket: string, Role: string, AwsKmsKeyArn: string, Notifications: record<Progressing: string, Completed: string, Warning: string, Error: string>, ContentConfig: record<Bucket: string, StorageClass: string, Permissions: list>, ThumbnailConfig: record<Bucket: string, StorageClass: string, Permissions: list>>, Warnings: table<Code: string, Message: string>>
# operationId: ReadPipeline
export def "read-pipeline" [
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
    method: get
    path: "/2012-09-25/pipelines/{Id}"
    path_params: [{name: Id, var: id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use the UpdatePipeline operation to update settings for a pipeline. When you change pipeline settings, your changes take effect immediately. Jobs that you have already submitted and that Elastic Transcoder has not started to process are affected in addition to jobs that you submit after you change settings.
#
# PUT /2012-09-25/pipelines/{Id}
# Returns: record<Pipeline: record<Id: string, Arn: string, Name: string, Status: string, InputBucket: string, OutputBucket: string, Role: string, AwsKmsKeyArn: string, Notifications: record<Progressing: string, Completed: string, Warning: string, Error: string>, ContentConfig: record<Bucket: string, StorageClass: string, Permissions: list>, ThumbnailConfig: record<Bucket: string, StorageClass: string, Permissions: list>>, Warnings: table<Code: string, Message: string>>
# operationId: UpdatePipeline
export def "update-pipeline" [
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
  --name: string # The name of the pipeline. We recommend that the name be unique within the AWS account, but uniqueness is not enforced. Constraints: Maximum 40 characters
  --input-bucket: string # The Amazon S3 bucket in which you saved the media files that you want to transcode and the graphics that you want to use as watermarks.
  --role: string # The IAM Amazon Resource Name (ARN) for the role that you want Elastic Transcoder to use to transcode jobs for this pipeline.
  --aws-kms-key-arn: string # The AWS Key Management Service (AWS KMS) key that you want to use with this pipeline. If you use either s3 or s3-aws-kms as your Encryption:Mode, you don't need to provide a key with your job because a default key, known as an AWS-KMS key, is created for you automatically. You need to provide an AWS-KMS key only if you want to use a non-default AWS-KMS key, or if you are using an Encryption:Mode of aes-cbc-pkcs7, aes-ctr, or aes-gcm.
  --notifications: record # The Amazon Simple Notification Service (Amazon SNS) topic or topics to notify in order to report job status. To receive notifications, you must also subscribe to the new topic in the Amazon SNS console. — shape: {Progressing?: string, Completed?: string, Warning?: string, Error?: string}
  --content-config: record # The PipelineOutputConfig structure. — shape: {Bucket?: string, StorageClass?: string, Permissions?: list}
  --thumbnail-config: record # The PipelineOutputConfig structure. — shape: {Bucket?: string, StorageClass?: string, Permissions?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/2012-09-25/pipelines/{Id}"
    path_params: [{name: Id, var: id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: InputBucket, var: input_bucket}, {name: Role, var: role}, {name: AwsKmsKeyArn, var: aws_kms_key_arn}, {name: Notifications, var: notifications}, {name: ContentConfig, var: content_config}, {name: ThumbnailConfig, var: thumbnail_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, input_bucket: $input_bucket, role: $role, aws_kms_key_arn: $aws_kms_key_arn, notifications: $notifications, content_config: $content_config, thumbnail_config: $thumbnail_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The DeletePreset operation removes a preset that you've added in an AWS region. You can't delete the default presets that are included with Elastic Transcoder.
#
# DELETE /2012-09-25/presets/{Id}
# Returns: record
# operationId: DeletePreset
export def "delete-preset" [
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
    path: "/2012-09-25/presets/{Id}"
    path_params: [{name: Id, var: id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ReadPreset operation gets detailed information about a preset.
#
# GET /2012-09-25/presets/{Id}
# Returns: record<Preset: record<Id: string, Arn: string, Name: string, Description: string, Container: string, Audio: record<Codec: string, SampleRate: string, BitRate: string, Channels: string, AudioPackingMode: string, CodecOptions: record>, Video: record<Codec: string, CodecOptions: record, KeyframesMaxDist: string, FixedGOP: string, BitRate: string, FrameRate: string, MaxFrameRate: string, Resolution: string, AspectRatio: string, MaxWidth: string, MaxHeight: string, DisplayAspectRatio: string, SizingPolicy: string, PaddingPolicy: string, Watermarks: list>, Thumbnails: record<Format: string, Interval: string, Resolution: string, AspectRatio: string, MaxWidth: string, MaxHeight: string, SizingPolicy: string, PaddingPolicy: string>, Type: string>>
# operationId: ReadPreset
export def "read-preset" [
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
    method: get
    path: "/2012-09-25/presets/{Id}"
    path_params: [{name: Id, var: id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ListJobsByPipeline operation gets a list of the jobs currently in a pipeline. Elastic Transcoder returns all of the jobs currently in the specified pipeline. The response body contains one element for each job that satisfies the search criteria.
#
# GET /2012-09-25/jobsByPipeline/{PipelineId}
# Returns: record<Jobs: table<Id: string, Arn: string, PipelineId: string, Input: record, Inputs: list, Output: record, Outputs: list, OutputKeyPrefix: string, Playlists: list, Status: string, UserMetadata: record, Timing: record>, NextPageToken: string>
# operationId: ListJobsByPipeline
export def "list-jobs-by-pipeline" [
  pipeline_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascending: string # To list jobs in chronological order by the date and time that they were submitted, enter true. To list jobs in reverse chronological order, enter false.
  --page-token: string # When Elastic Transcoder returns more than one page of results, use pageToken in subsequent GET requests to get each successive page of results.
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
    path: "/2012-09-25/jobsByPipeline/{PipelineId}"
    path_params: [{name: PipelineId, var: pipeline_id}]
    query: [{name: Ascending, var: ascending}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pipeline_id: $pipeline_id, ascending: $ascending, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ListJobsByStatus operation gets a list of jobs that have a specified status. The response body contains one element for each job that satisfies the search criteria.
#
# GET /2012-09-25/jobsByStatus/{Status}
# Returns: record<Jobs: table<Id: string, Arn: string, PipelineId: string, Input: record, Inputs: list, Output: record, Outputs: list, OutputKeyPrefix: string, Playlists: list, Status: string, UserMetadata: record, Timing: record>, NextPageToken: string>
# operationId: ListJobsByStatus
export def "list-jobs-by-status" [
  status: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascending: string # To list jobs in chronological order by the date and time that they were submitted, enter true. To list jobs in reverse chronological order, enter false.
  --page-token: string # When Elastic Transcoder returns more than one page of results, use pageToken in subsequent GET requests to get each successive page of results.
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
    path: "/2012-09-25/jobsByStatus/{Status}"
    path_params: [{name: Status, var: status}]
    query: [{name: Ascending, var: ascending}, {name: PageToken, var: page_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status: $status, ascending: $ascending, page_token: $page_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The TestRole operation tests the IAM role used to create the pipeline. The TestRole action lets you determine whether the IAM role you are using has sufficient permissions to let Elastic Transcoder perform tasks associated with the transcoding process. The action attempts to assume the specified IAM role, checks read access to the input and output buckets, and tries to send a test notification to Amazon SNS topics that you specify.
#
# POST /2012-09-25/roleTests
# DEPRECATED
# Returns: record<Success: string, Messages: list<string>>
# operationId: TestRole
@deprecated
export def "test-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  role: string # The IAM Amazon Resource Name (ARN) for the role that you want Elastic Transcoder to test.
  input_bucket: string # The Amazon S3 bucket that contains media files to be transcoded. The action attempts to read from this bucket.
  output_bucket: string # The Amazon S3 bucket that Elastic Transcoder writes transcoded media files to. The action attempts to read from this bucket.
  topics: list<string> # The ARNs of one or more Amazon Simple Notification Service (Amazon SNS) topics that you want the action to send a test notification to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2012-09-25/roleTests"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Role, var: role}, {name: InputBucket, var: input_bucket}, {name: OutputBucket, var: output_bucket}, {name: Topics, var: topics}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, role: $role, input_bucket: $input_bucket, output_bucket: $output_bucket, topics: $topics
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# With the UpdatePipelineNotifications operation, you can update Amazon Simple Notification Service (Amazon SNS) notifications for a pipeline. When you update notifications for a pipeline, Elastic Transcoder returns the values that you specified in the request.
#
# POST /2012-09-25/pipelines/{Id}/notifications
# Returns: record<Pipeline: record<Id: string, Arn: string, Name: string, Status: string, InputBucket: string, OutputBucket: string, Role: string, AwsKmsKeyArn: string, Notifications: record<Progressing: string, Completed: string, Warning: string, Error: string>, ContentConfig: record<Bucket: string, StorageClass: string, Permissions: list>, ThumbnailConfig: record<Bucket: string, StorageClass: string, Permissions: list>>>
# operationId: UpdatePipelineNotifications
export def "update-pipeline-notifications" [
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
  notifications: record # The Amazon Simple Notification Service (Amazon SNS) topic or topics to notify in order to report job status. To receive notifications, you must also subscribe to the new topic in the Amazon SNS console. — shape: {Progressing?: string, Completed?: string, Warning?: string, Error?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2012-09-25/pipelines/{Id}/notifications"
    path_params: [{name: Id, var: id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Notifications, var: notifications}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, notifications: $notifications
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The UpdatePipelineStatus operation pauses or reactivates a pipeline, so that the pipeline stops or restarts the processing of jobs. Changing the pipeline status is useful if you want to cancel one or more jobs. You can't cancel jobs after Elastic Transcoder has started processing them; if you pause the pipeline to which you submitted the jobs, you have more time to get the job IDs for the jobs that you want to cancel, and to send a CancelJob request.
#
# POST /2012-09-25/pipelines/{Id}/status
# Returns: record<Pipeline: record<Id: string, Arn: string, Name: string, Status: string, InputBucket: string, OutputBucket: string, Role: string, AwsKmsKeyArn: string, Notifications: record<Progressing: string, Completed: string, Warning: string, Error: string>, ContentConfig: record<Bucket: string, StorageClass: string, Permissions: list>, ThumbnailConfig: record<Bucket: string, StorageClass: string, Permissions: list>>>
# operationId: UpdatePipelineStatus
export def "update-pipeline-status" [
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
  status: string # The desired status of the pipeline: Active: The pipeline is processing jobs. Paused: The pipeline is not currently processing jobs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/2012-09-25/pipelines/{Id}/status"
    path_params: [{name: Id, var: id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
