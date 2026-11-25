# Auto-generated client for AWS IoT SiteWise v2019-12-02
# Source: https://api.apis.guru/v2/specs/amazonaws.com/iotsitewise/2019-12-02/openapi.json
# Auth: --token flag or $env.AWS_IOT_SITEWISE_TOKEN

const CLIENT = {
  base_url: "http://iotsitewise.us-east-1.amazonaws.com"
  token_env_var: "AWS_IOT_SITEWISE_TOKEN"
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

def base-url-completer [] { ["http://iotsitewise.us-east-1.amazonaws.com" "http://iotsitewise.us-east-2.amazonaws.com" "http://iotsitewise.us-west-1.amazonaws.com" "http://iotsitewise.us-west-2.amazonaws.com" "http://iotsitewise.us-gov-west-1.amazonaws.com" "http://iotsitewise.us-gov-east-1.amazonaws.com" "http://iotsitewise.ca-central-1.amazonaws.com" "http://iotsitewise.eu-north-1.amazonaws.com" "http://iotsitewise.eu-west-1.amazonaws.com" "http://iotsitewise.eu-west-2.amazonaws.com" "http://iotsitewise.eu-west-3.amazonaws.com" "http://iotsitewise.eu-central-1.amazonaws.com" "http://iotsitewise.eu-south-1.amazonaws.com" "http://iotsitewise.af-south-1.amazonaws.com" "http://iotsitewise.ap-northeast-1.amazonaws.com" "http://iotsitewise.ap-northeast-2.amazonaws.com" "http://iotsitewise.ap-northeast-3.amazonaws.com" "http://iotsitewise.ap-southeast-1.amazonaws.com" "http://iotsitewise.ap-southeast-2.amazonaws.com" "http://iotsitewise.ap-east-1.amazonaws.com" "http://iotsitewise.ap-south-1.amazonaws.com" "http://iotsitewise.sa-east-1.amazonaws.com" "http://iotsitewise.me-south-1.amazonaws.com" "https://iotsitewise.us-east-1.amazonaws.com" "https://iotsitewise.us-east-2.amazonaws.com" "https://iotsitewise.us-west-1.amazonaws.com" "https://iotsitewise.us-west-2.amazonaws.com" "https://iotsitewise.us-gov-west-1.amazonaws.com" "https://iotsitewise.us-gov-east-1.amazonaws.com" "https://iotsitewise.ca-central-1.amazonaws.com" "https://iotsitewise.eu-north-1.amazonaws.com" "https://iotsitewise.eu-west-1.amazonaws.com" "https://iotsitewise.eu-west-2.amazonaws.com" "https://iotsitewise.eu-west-3.amazonaws.com" "https://iotsitewise.eu-central-1.amazonaws.com" "https://iotsitewise.eu-south-1.amazonaws.com" "https://iotsitewise.af-south-1.amazonaws.com" "https://iotsitewise.ap-northeast-1.amazonaws.com" "https://iotsitewise.ap-northeast-2.amazonaws.com" "https://iotsitewise.ap-northeast-3.amazonaws.com" "https://iotsitewise.ap-southeast-1.amazonaws.com" "https://iotsitewise.ap-southeast-2.amazonaws.com" "https://iotsitewise.ap-east-1.amazonaws.com" "https://iotsitewise.ap-south-1.amazonaws.com" "https://iotsitewise.sa-east-1.amazonaws.com" "https://iotsitewise.me-south-1.amazonaws.com" "http://iotsitewise.cn-north-1.amazonaws.com.cn" "http://iotsitewise.cn-northwest-1.amazonaws.com.cn" "https://iotsitewise.cn-north-1.amazonaws.com.cn" "https://iotsitewise.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def access-policy-permission-completer [] { ["ADMINISTRATOR" "VIEWER"] }
def identity-type-completer [] { ["GROUP" "IAM" "USER"] }
def resource-type-completer [] { ["PORTAL" "PROJECT"] }
def filter-completer [] { ["ALL" "TOP_LEVEL"] }
def filter-completer-1 [] { ["ALL" "CANCELLED" "COMPLETED" "COMPLETED_WITH_FAILURES" "FAILED" "PENDING" "RUNNING"] }
def portal-auth-mode-completer [] { ["IAM" "SSO"] }
def property-notification-state-completer [] { ["DISABLED" "ENABLED"] }
def encryption-type-completer [] { ["KMS_BASED_ENCRYPTION" "SITEWISE_DEFAULT_ENCRYPTION"] }
def storage-type-completer [] { ["MULTI_LAYER_STORAGE" "SITEWISE_DEFAULT_STORAGE"] }
def disassociated-data-storage-completer [] { ["DISABLED" "ENABLED"] }
def time-ordering-completer [] { ["ASCENDING" "DESCENDING"] }
def quality-completer [] { ["BAD" "GOOD" "UNCERTAIN"] }
def filter-completer-2 [] { ["ALL" "BASE"] }
def traversal-type-completer [] { ["PATH_TO_ROOT"] }
def traversal-direction-completer [] { ["CHILD" "PARENT"] }
def time-series-type-completer [] { ["ASSOCIATED" "DISASSOCIATED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    batch-associate-project-assets: "record<errors: table<assetId: string, code: string, message: string>>"
    batch-disassociate-project-assets: "record<errors: table<assetId: string, code: string, message: string>>"
    batch-get-asset-property-aggregates: "record<errorEntries: table<errorCode: string, errorMessage: string, entryId: string>, successEntries: table<entryId: string, aggregatedValues: list>, skippedEntries: table<entryId: string, completionStatus: string, errorInfo: record>, nextToken: string>"
    batch-get-asset-property-value: "record<errorEntries: table<errorCode: string, errorMessage: string, entryId: string>, successEntries: table<entryId: string, assetPropertyValue: record>, skippedEntries: table<entryId: string, completionStatus: string, errorInfo: record>, nextToken: string>"
    batch-get-asset-property-value-history: "record<errorEntries: table<errorCode: string, errorMessage: string, entryId: string>, successEntries: table<entryId: string, assetPropertyValueHistory: list>, skippedEntries: table<entryId: string, completionStatus: string, errorInfo: record>, nextToken: string>"
    batch-put-asset-property-value: "record<errorEntries: table<entryId: string, errors: list>>"
    create-access-policy: "record<accessPolicyId: string, accessPolicyArn: string>"
    list-access-policies: "record<accessPolicySummaries: table<id: string, identity: record, resource: record, permission: string, creationDate: string, lastUpdateDate: string>, nextToken: string>"
    create-asset: "record<assetId: string, assetArn: string, assetStatus: record<state: string, error: record<code: string, message: string, details: list>>>"
    list-assets: "record<assetSummaries: table<id: string, arn: string, name: string, assetModelId: string, creationDate: string, lastUpdateDate: string, status: record, hierarchies: list, description: string>, nextToken: string>"
    create-asset-model: "record<assetModelId: string, assetModelArn: string, assetModelStatus: record<state: string, error: record<code: string, message: string, details: list>>>"
    list-asset-models: "record<assetModelSummaries: table<id: string, arn: string, name: string, description: string, creationDate: string, lastUpdateDate: string, status: record>, nextToken: string>"
    create-bulk-import-job: "record<jobId: string, jobName: string, jobStatus: string>"
    list-bulk-import-jobs: "record<jobSummaries: table<id: string, name: string, status: string>, nextToken: string>"
    create-dashboard: "record<dashboardId: string, dashboardArn: string>"
    create-gateway: "record<gatewayId: string, gatewayArn: string>"
    list-gateways: "record<gatewaySummaries: table<gatewayId: string, gatewayName: string, gatewayPlatform: record, gatewayCapabilitySummaries: list, creationDate: string, lastUpdateDate: string>, nextToken: string>"
    create-portal: "record<portalId: string, portalArn: string, portalStartUrl: string, portalStatus: record<state: string, error: record<code: string, message: string>>, ssoApplicationId: string>"
    list-portals: "record<portalSummaries: table<id: string, name: string, description: string, startUrl: string, creationDate: string, lastUpdateDate: string, roleArn: string, status: record>, nextToken: string>"
    create-project: "record<projectId: string, projectArn: string>"
    delete-access-policy: "record"
    describe-access-policy: "record<accessPolicyId: string, accessPolicyArn: string, accessPolicyIdentity: record<user: record<id: string>, group: record<id: string>, iamUser: record<arn: string>, iamRole: record<arn: string>>, accessPolicyResource: record<portal: record<id: string>, project: record<id: string>>, accessPolicyPermission: string, accessPolicyCreationDate: string, accessPolicyLastUpdateDate: string>"
    update-access-policy: "record"
    delete-asset: "record<assetStatus: record<state: string, error: record<code: string, message: string, details: list>>>"
    describe-asset: "record<assetId: string, assetArn: string, assetName: string, assetModelId: string, assetProperties: table<id: string, name: string, alias: string, notification: record, dataType: string, dataTypeSpec: string, unit: string>, assetHierarchies: table<id: string, name: string>, assetCompositeModels: table<name: string, description: string, type: string, properties: any, id: string>, assetCreationDate: string, assetLastUpdateDate: string, assetStatus: record<state: string, error: record<code: string, message: string, details: list>>, assetDescription: string>"
    update-asset: "record<assetStatus: record<state: string, error: record<code: string, message: string, details: list>>>"
    delete-asset-model: "record<assetModelStatus: record<state: string, error: record<code: string, message: string, details: list>>>"
    describe-asset-model: "record<assetModelId: string, assetModelArn: string, assetModelName: string, assetModelDescription: string, assetModelProperties: table<id: string, name: string, dataType: string, dataTypeSpec: string, unit: string, type: record>, assetModelHierarchies: table<id: string, name: string, childAssetModelId: string>, assetModelCompositeModels: table<name: string, description: string, type: string, properties: any, id: string>, assetModelCreationDate: string, assetModelLastUpdateDate: string, assetModelStatus: record<state: string, error: record<code: string, message: string, details: list>>>"
    update-asset-model: "record<assetModelStatus: record<state: string, error: record<code: string, message: string, details: list>>>"
    delete-dashboard: "record"
    describe-dashboard: "record<dashboardId: string, dashboardArn: string, dashboardName: string, projectId: string, dashboardDescription: string, dashboardDefinition: string, dashboardCreationDate: string, dashboardLastUpdateDate: string>"
    update-dashboard: "record"
    describe-gateway: "record<gatewayId: string, gatewayName: string, gatewayArn: string, gatewayPlatform: record<greengrass: record<groupArn: string>, greengrassV2: record<coreDeviceThingName: string>>, gatewayCapabilitySummaries: table<capabilityNamespace: string, capabilitySyncStatus: string>, creationDate: string, lastUpdateDate: string>"
    delete-portal: "record<portalStatus: record<state: string, error: record<code: string, message: string>>>"
    describe-portal: "record<portalId: string, portalArn: string, portalName: string, portalDescription: string, portalClientId: string, portalStartUrl: string, portalContactEmail: string, portalStatus: record<state: string, error: record<code: string, message: string>>, portalCreationDate: string, portalLastUpdateDate: string, portalLogoImageLocation: record<id: string, url: string>, roleArn: string, portalAuthMode: string, notificationSenderEmail: string, alarms: record<alarmRoleArn: string, notificationLambdaArn: string>>"
    update-portal: "record<portalStatus: record<state: string, error: record<code: string, message: string>>>"
    delete-project: "record"
    describe-project: "record<projectId: string, projectArn: string, projectName: string, portalId: string, projectDescription: string, projectCreationDate: string, projectLastUpdateDate: string>"
    update-project: "record"
    describe-asset-property: "record<assetId: string, assetName: string, assetModelId: string, assetProperty: record<id: string, name: string, alias: string, notification: record<topic: string, state: string>, dataType: string, unit: string, type: record<attribute: record, measurement: record, transform: record, metric: record>>, compositeModel: record<name: string, type: string, assetProperty: record<id: string, name: string, alias: string, notification: record, dataType: string, unit: string, type: record>, id: string>>"
    describe-bulk-import-job: "record<jobId: string, jobName: string, jobStatus: string, jobRoleArn: string, files: table<bucket: string, key: string, versionId: string>, errorReportLocation: record<bucket: string, prefix: string>, jobConfiguration: record<fileFormat: record<csv: record>>, jobCreationDate: string, jobLastUpdateDate: string>"
    describe-default-encryption-configuration: "record<encryptionType: string, kmsKeyArn: string, configurationStatus: record<state: string, error: record<code: string, message: string>>>"
    put-default-encryption-configuration: "record<encryptionType: string, kmsKeyArn: string, configurationStatus: record<state: string, error: record<code: string, message: string>>>"
    describe-gateway-capability-configuration: "record<gatewayId: string, capabilityNamespace: string, capabilityConfiguration: string, capabilitySyncStatus: string>"
    describe-logging-options: "record<loggingOptions: record<level: string>>"
    put-logging-options: "record"
    describe-storage-configuration: "record<storageType: string, multiLayerStorage: record<customerManagedS3Storage: record<s3ResourceArn: string, roleArn: string>>, disassociatedDataStorage: string, retentionPeriod: record<numberOfDays: int, unlimited: bool>, configurationStatus: record<state: string, error: record<code: string, message: string>>, lastUpdateDate: string>"
    put-storage-configuration: "record<storageType: string, multiLayerStorage: record<customerManagedS3Storage: record<s3ResourceArn: string, roleArn: string>>, disassociatedDataStorage: string, retentionPeriod: record<numberOfDays: int, unlimited: bool>, configurationStatus: record<state: string, error: record<code: string, message: string>>>"
    describe-time-series: "record<assetId: string, propertyId: string, alias: string, timeSeriesId: string, dataType: string, dataTypeSpec: string, timeSeriesCreationDate: string, timeSeriesLastUpdateDate: string, timeSeriesArn: string>"
    get-asset-property-aggregates: "record<aggregatedValues: table<timestamp: string, quality: string, value: record>, nextToken: string>"
    get-asset-property-value: "record<propertyValue: record<value: record<stringValue: string, integerValue: int, doubleValue: float, booleanValue: bool>, timestamp: record<timeInSeconds: int, offsetInNanos: int>, quality: string>>"
    get-asset-property-value-history: "record<assetPropertyValueHistory: table<value: record, timestamp: record, quality: string>, nextToken: string>"
    get-interpolated-asset-property-values: "record<interpolatedAssetPropertyValues: table<timestamp: record, value: record>, nextToken: string>"
    list-asset-model-properties: "record<assetModelPropertySummaries: table<id: string, name: string, dataType: string, dataTypeSpec: string, unit: string, type: record, assetModelCompositeModelId: string>, nextToken: string>"
    list-asset-properties: "record<assetPropertySummaries: table<id: string, alias: string, unit: string, notification: record, assetCompositeModelId: string>, nextToken: string>"
    list-asset-relationships: "record<assetRelationshipSummaries: table<hierarchyInfo: record, relationshipType: string>, nextToken: string>"
    list-associated-assets: "record<assetSummaries: table<id: string, arn: string, name: string, assetModelId: string, creationDate: string, lastUpdateDate: string, status: record, hierarchies: list, description: string>, nextToken: string>"
    list-dashboards: "record<dashboardSummaries: table<id: string, name: string, description: string, creationDate: string, lastUpdateDate: string>, nextToken: string>"
    list-project-assets: "record<assetIds: list<string>, nextToken: string>"
    list-projects: "record<projectSummaries: table<id: string, name: string, description: string, creationDate: string, lastUpdateDate: string>, nextToken: string>"
    list-tags-for-resource: "record<tags: record>"
    tag-resource: "record"
    list-time-series: "record<TimeSeriesSummaries: table<assetId: string, propertyId: string, alias: string, timeSeriesId: string, dataType: string, dataTypeSpec: string, timeSeriesCreationDate: string, timeSeriesLastUpdateDate: string, timeSeriesArn: string>, nextToken: string>"
    untag-resource: "record"
    update-gateway-capability-configuration: "record<capabilityNamespace: string, capabilitySyncStatus: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["associate-assets" "associate-time-series-to-asset-property" "batch-associate-project-assets" "batch-disassociate-project-assets" "batch-get-asset-property-aggregates" "batch-get-asset-property-value" "batch-get-asset-property-value-history" "batch-put-asset-property-value" "create-access-policy" "list-access-policies" "create-asset" "list-assets" "create-asset-model" "list-asset-models" "create-bulk-import-job" "list-bulk-import-jobs" "create-dashboard" "create-gateway" "list-gateways" "create-portal" "list-portals" "create-project" "delete-access-policy" "describe-access-policy" "update-access-policy" "delete-asset" "describe-asset" "update-asset" "delete-asset-model" "describe-asset-model" "update-asset-model" "delete-dashboard" "describe-dashboard" "update-dashboard" "delete-gateway" "describe-gateway" "update-gateway" "delete-portal" "describe-portal" "update-portal" "delete-project" "describe-project" "update-project" "delete-time-series" "describe-asset-property" "update-asset-property" "describe-bulk-import-job" "describe-default-encryption-configuration" "put-default-encryption-configuration" "describe-gateway-capability-configuration" "describe-logging-options" "put-logging-options" "describe-storage-configuration" "put-storage-configuration" "describe-time-series" "disassociate-assets" "disassociate-time-series-from-asset-property" "get-asset-property-aggregates" "get-asset-property-value" "get-asset-property-value-history" "get-interpolated-asset-property-values" "list-asset-model-properties" "list-asset-properties" "list-asset-relationships" "list-associated-assets" "list-dashboards" "list-project-assets" "list-projects" "list-tags-for-resource" "tag-resource" "list-time-series" "untag-resource" "update-gateway-capability-configuration" "commands"] | sort) } | get name | first)
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

# Associates a child asset with the given parent asset through a hierarchy defined in the parent asset's model. For more information, see Associating assets (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/add-associated-assets.html) in the IoT SiteWise User Guide.
#
# POST /assets/{assetId}/associate
# operationId: AssociateAssets
export def "associate-assets" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  hierarchy_id: string # The ID of a hierarchy in the parent asset's model. Hierarchies allow different groupings of assets to be formed that all come from the same asset model. For more information, see Asset hierarchies (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/asset-hierarchies.html) in the IoT SiteWise User Guide.
  child_asset_id: string # The ID of the child asset to be associated.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> any {
  $in | http-request {
    method: post
    path: "/assets/{assetId}/associate"
    path_params: [{name: assetId, var: asset_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: hierarchyId, var: hierarchy_id}, {name: childAssetId, var: child_asset_id}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, hierarchy_id: $hierarchy_id, child_asset_id: $child_asset_id, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a time series (data stream) with an asset property.
#
# POST /timeseries/associate/
# operationId: AssociateTimeSeriesToAssetProperty
export def "associate-time-series-to-asset-property" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string # The alias that identifies the time series. (required)
  --asset-id: string # The ID of the asset in which the asset property was created. (required)
  --property-id: string # The ID of the asset property. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> any {
  $in | http-request {
    method: post
    path: "/timeseries/associate/"
    query: [{name: alias, var: alias, required: true}, {name: assetId, var: asset_id, required: true}, {name: propertyId, var: property_id, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alias: $alias, asset_id: $asset_id, property_id: $property_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a group (batch) of assets with an IoT SiteWise Monitor project.
#
# POST /projects/{projectId}/assets/associate
# Returns: record<errors: table<assetId: string, code: string, message: string>>
# operationId: BatchAssociateProjectAssets
export def "batch-associate-project-assets" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  asset_ids: list<string> # The IDs of the assets to be associated to the project.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/assets/associate"
    path_params: [{name: projectId, var: project_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: assetIds, var: asset_ids}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, asset_ids: $asset_ids, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates a group (batch) of assets from an IoT SiteWise Monitor project.
#
# POST /projects/{projectId}/assets/disassociate
# Returns: record<errors: table<assetId: string, code: string, message: string>>
# operationId: BatchDisassociateProjectAssets
export def "batch-disassociate-project-assets" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  asset_ids: list<string> # The IDs of the assets to be disassociated from the project.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/assets/disassociate"
    path_params: [{name: projectId, var: project_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: assetIds, var: asset_ids}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, asset_ids: $asset_ids, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets aggregated values (for example, average, minimum, and maximum) for one or more asset properties. For more information, see Querying aggregates (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/query-industrial-data.html#aggregates) in the IoT SiteWise User Guide.
#
# POST /properties/batch/aggregates
# Returns: record<errorEntries: table<errorCode: string, errorMessage: string, entryId: string>, successEntries: table<entryId: string, aggregatedValues: list>, skippedEntries: table<entryId: string, completionStatus: string, errorInfo: record>, nextToken: string>
# operationId: BatchGetAssetPropertyAggregates
export def "batch-get-asset-property-aggregates" [
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
  entries: list # The list of asset property aggregate entries for the batch get request. You can specify up to 16 entries per request. — item shape: {entryId: string, assetId?: string, propertyId?: string, propertyAlias?: string, aggregateTypes: list<string>, resolution: string, startDate: string, endDate: string, qualities?: list<string>, timeOrdering?: "ASCENDING"|"DESCENDING"}
  --body-next-token: string # The token to be used for the next set of paginated results. (spec name: nextToken)
  --body-max-results: int # The maximum number of results to return for each paginated request. A result set is returned in the two cases, whichever occurs first. The size of the result set is less than 1 MB. The number of data points in the result set is less than the value of maxResults. The maximum value of maxResults is 4000. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/properties/batch/aggregates"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, entries: $entries, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the current value for one or more asset properties. For more information, see Querying current values (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/query-industrial-data.html#current-values) in the IoT SiteWise User Guide.
#
# POST /properties/batch/latest
# Returns: record<errorEntries: table<errorCode: string, errorMessage: string, entryId: string>, successEntries: table<entryId: string, assetPropertyValue: record>, skippedEntries: table<entryId: string, completionStatus: string, errorInfo: record>, nextToken: string>
# operationId: BatchGetAssetPropertyValue
export def "batch-get-asset-property-value" [
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
  entries: list # The list of asset property value entries for the batch get request. You can specify up to 128 entries per request. — item shape: {entryId: string, assetId?: string, propertyId?: string, propertyAlias?: string}
  --body-next-token: string # The token to be used for the next set of paginated results. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/properties/batch/latest"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, entries: $entries, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the historical values for one or more asset properties. For more information, see Querying historical values (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/query-industrial-data.html#historical-values) in the IoT SiteWise User Guide.
#
# POST /properties/batch/history
# Returns: record<errorEntries: table<errorCode: string, errorMessage: string, entryId: string>, successEntries: table<entryId: string, assetPropertyValueHistory: list>, skippedEntries: table<entryId: string, completionStatus: string, errorInfo: record>, nextToken: string>
# operationId: BatchGetAssetPropertyValueHistory
export def "batch-get-asset-property-value-history" [
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
  entries: list # The list of asset property historical value entries for the batch get request. You can specify up to 16 entries per request. — item shape: {entryId: string, assetId?: string, propertyId?: string, propertyAlias?: string, startDate?: string, endDate?: string, qualities?: list<string>, timeOrdering?: "ASCENDING"|"DESCENDING"}
  --body-next-token: string # The token to be used for the next set of paginated results. (spec name: nextToken)
  --body-max-results: int # The maximum number of results to return for each paginated request. A result set is returned in the two cases, whichever occurs first. The size of the result set is less than 1 MB. The number of data points in the result set is less than the value of maxResults. The maximum value of maxResults is 4000. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/properties/batch/history"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, entries: $entries, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a list of asset property values to IoT SiteWise. Each value is a timestamp-quality-value (TQV) data point. For more information, see Ingesting data using the API (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/ingest-api.html) in the IoT SiteWise User Guide. To identify an asset property, you must specify one of the following: The assetId and propertyId of an asset property. A propertyAlias, which is a data stream alias (for example, /company/windfarm/3/turbine/7/temperature). To define an asset property's alias, see UpdateAssetProperty (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_UpdateAssetProperty.html). With respect to Unix epoch time, IoT SiteWise accepts only TQVs that have a timestamp of no more than 7 days in the past and no more than 10 minutes in the future. IoT SiteWise rejects timestamps outside of the inclusive range of [-7 days, +10 minutes] and returns a TimestampOutOfRangeException error. For each asset property, IoT SiteWise overwrites TQVs with duplicate timestamps unless the newer TQV has a different quality. For example, if you store a TQV {T1, GOOD, V1}, then storing {T1, GOOD, V2} replaces the existing TQV. IoT SiteWise authorizes access to each BatchPutAssetPropertyValue entry individually. For more information, see BatchPutAssetPropertyValue authorization (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/security_iam_service-with-iam.html#security_iam_service-with-iam-id-based-policies-batchputassetpropertyvalue-action) in the IoT SiteWise User Guide.
#
# POST /properties
# Returns: record<errorEntries: table<entryId: string, errors: list>>
# operationId: BatchPutAssetPropertyValue
export def "batch-put-asset-property-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  entries: list # The list of asset property value entries for the batch put request. You can specify up to 10 entries per request. — item shape: {entryId: string, assetId?: string, propertyId?: string, propertyAlias?: string, propertyValues: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/properties"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: entries, var: entries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, entries: $entries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an access policy that grants the specified identity (IAM Identity Center user, IAM Identity Center group, or IAM user) access to the specified IoT SiteWise Monitor portal or project resource.
#
# POST /access-policies
# Returns: record<accessPolicyId: string, accessPolicyArn: string>
# operationId: CreateAccessPolicy
export def "create-access-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  access_policy_identity: record # Contains an identity that can access an IoT SiteWise Monitor resource. Currently, you can't use Amazon Web Services APIs to retrieve IAM Identity Center identity IDs. You can find the IAM Identity Center identity IDs in the URL of user and group pages in the IAM Identity Center console (https://console.aws.amazon.com/singlesignon). — shape: {user?: record, group?: record, iamUser?: record, iamRole?: record}
  access_policy_resource: record # Contains an IoT SiteWise Monitor resource ID for a portal or project. — shape: {portal?: record, project?: record}
  access_policy_permission: string@access-policy-permission-completer # The permission level for this access policy. Note that a project ADMINISTRATOR is also known as a project owner.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --tags: record # A list of key-value pairs that contain metadata for the access policy. For more information, see Tagging your IoT SiteWise resources (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/tag-resources.html) in the IoT SiteWise User Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/access-policies"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessPolicyIdentity, var: access_policy_identity}, {name: accessPolicyResource, var: access_policy_resource}, {name: accessPolicyPermission, var: access_policy_permission}, {name: clientToken, var: client_token}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, access_policy_identity: $access_policy_identity, access_policy_resource: $access_policy_resource, access_policy_permission: $access_policy_permission, client_token: $client_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of access policies for an identity (an IAM Identity Center user, an IAM Identity Center group, or an IAM user) or an IoT SiteWise Monitor resource (a portal or project).
#
# GET /access-policies
# Returns: record<accessPolicySummaries: table<id: string, identity: record, resource: record, permission: string, creationDate: string, lastUpdateDate: string>, nextToken: string>
# operationId: ListAccessPolicies
export def "list-access-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity-type: string@identity-type-completer # The type of identity (IAM Identity Center user, IAM Identity Center group, or IAM user). This parameter is required if you specify identityId.
  --identity-id: string # The ID of the identity. This parameter is required if you specify USER or GROUP for identityType.
  --resource-type: string@resource-type-completer # The type of resource (portal or project). This parameter is required if you specify resourceId.
  --resource-id: string # The ID of the resource. This parameter is required if you specify resourceType.
  --iam-arn: string # The ARN of the IAM user. For more information, see IAM ARNs (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html) in the IAM User Guide. This parameter is required if you specify IAM for identityType.
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 50
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
    path: "/access-policies"
    query: [{name: identityType, var: identity_type}, {name: identityId, var: identity_id}, {name: resourceType, var: resource_type}, {name: resourceId, var: resource_id}, {name: iamArn, var: iam_arn}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    identity_type: $identity_type, identity_id: $identity_id, resource_type: $resource_type, resource_id: $resource_id, iam_arn: $iam_arn, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an asset from an existing asset model. For more information, see Creating assets (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/create-assets.html) in the IoT SiteWise User Guide.
#
# POST /assets
# Returns: record<assetId: string, assetArn: string, assetStatus: record<state: string, error: record<code: string, message: string, details: list>>>
# operationId: CreateAsset
export def "create-asset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  asset_name: string # A friendly name for the asset.
  asset_model_id: string # The ID of the asset model from which to create the asset.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --tags: record # A list of key-value pairs that contain metadata for the asset. For more information, see Tagging your IoT SiteWise resources (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/tag-resources.html) in the IoT SiteWise User Guide.
  --asset-description: string # A description for the asset.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: assetName, var: asset_name}, {name: assetModelId, var: asset_model_id}, {name: clientToken, var: client_token}, {name: tags, var: tags}, {name: assetDescription, var: asset_description}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, asset_name: $asset_name, asset_model_id: $asset_model_id, client_token: $client_token, tags: $tags, asset_description: $asset_description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of asset summaries. You can use this operation to do the following: List assets based on a specific asset model. List top-level assets. You can't use this operation to list all assets. To retrieve summaries for all of your assets, use ListAssetModels (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_ListAssetModels.html) to get all of your asset model IDs. Then, use ListAssets to get all assets for each asset model.
#
# GET /assets
# Returns: record<assetSummaries: table<id: string, arn: string, name: string, assetModelId: string, creationDate: string, lastUpdateDate: string, status: record, hierarchies: list, description: string>, nextToken: string>
# operationId: ListAssets
export def "list-assets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 50
  --asset-model-id: string # The ID of the asset model by which to filter the list of assets. This parameter is required if you choose ALL for filter.
  --filter: string@filter-completer # The filter for the requested list of assets. Choose one of the following options: ALL – The list includes all assets for a given asset model ID. The assetModelId parameter is required if you filter by ALL. TOP_LEVEL – The list includes only top-level assets in the asset hierarchy tree. Default: ALL
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
    path: "/assets"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: assetModelId, var: asset_model_id}, {name: filter, var: filter}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, asset_model_id: $asset_model_id, filter: $filter, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an asset model from specified property and hierarchy definitions. You create assets from asset models. With asset models, you can easily create assets of the same type that have standardized definitions. Each asset created from a model inherits the asset model's property and hierarchy definitions. For more information, see Defining asset models (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/define-models.html) in the IoT SiteWise User Guide.
#
# POST /asset-models
# Returns: record<assetModelId: string, assetModelArn: string, assetModelStatus: record<state: string, error: record<code: string, message: string, details: list>>>
# operationId: CreateAssetModel
export def "create-asset-model" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  asset_model_name: string # A unique, friendly name for the asset model.
  --asset-model-description: string # A description for the asset model.
  --asset-model-properties: list # The property definitions of the asset model. For more information, see Asset properties (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/asset-properties.html) in the IoT SiteWise User Guide. You can specify up to 200 properties per asset model. For more information, see Quotas (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/quotas.html) in the IoT SiteWise User Guide. — item shape: {name: string, dataType: "STRING"|"INTEGER"|"DOUBLE"|"BOOLEAN"|"STRUCT", dataTypeSpec?: string, unit?: string, type: record}
  --asset-model-hierarchies: list # The hierarchy definitions of the asset model. Each hierarchy specifies an asset model whose assets can be children of any other assets created from this asset model. For more information, see Asset hierarchies (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/asset-hierarchies.html) in the IoT SiteWise User Guide. You can specify up to 10 hierarchies per asset model. For more information, see Quotas (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/quotas.html) in the IoT SiteWise User Guide. — item shape: {name: string, childAssetModelId: string}
  --asset-model-composite-models: list # The composite asset models that are part of this asset model. Composite asset models are asset models that contain specific properties. Each composite model has a type that defines the properties that the composite model supports. Use composite asset models to define alarms on this asset model. — item shape: {name: string, description?: string, type: string, properties?: any}
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --tags: record # A list of key-value pairs that contain metadata for the asset model. For more information, see Tagging your IoT SiteWise resources (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/tag-resources.html) in the IoT SiteWise User Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/asset-models"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: assetModelName, var: asset_model_name}, {name: assetModelDescription, var: asset_model_description}, {name: assetModelProperties, var: asset_model_properties}, {name: assetModelHierarchies, var: asset_model_hierarchies}, {name: assetModelCompositeModels, var: asset_model_composite_models}, {name: clientToken, var: client_token}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, asset_model_name: $asset_model_name, asset_model_description: $asset_model_description, asset_model_properties: $asset_model_properties, asset_model_hierarchies: $asset_model_hierarchies, asset_model_composite_models: $asset_model_composite_models, client_token: $client_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of summaries of all asset models.
#
# GET /asset-models
# Returns: record<assetModelSummaries: table<id: string, arn: string, name: string, description: string, creationDate: string, lastUpdateDate: string, status: record>, nextToken: string>
# operationId: ListAssetModels
export def "list-asset-models" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 50
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
    path: "/asset-models"
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

# Defines a job to ingest data to IoT SiteWise from Amazon S3. For more information, see Create a bulk import job (CLI) (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/CreateBulkImportJob.html) in the Amazon Simple Storage Service User Guide. You must enable IoT SiteWise to export data to Amazon S3 before you create a bulk import job. For more information about how to configure storage settings, see PutStorageConfiguration (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_PutStorageConfiguration.html).
#
# POST /jobs
# Returns: record<jobId: string, jobName: string, jobStatus: string>
# operationId: CreateBulkImportJob
export def "create-bulk-import-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  job_name: string # The unique name that helps identify the job request.
  job_role_arn: string # The ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the IAM role that allows IoT SiteWise to read Amazon S3 data.
  files: list # The files in the specified Amazon S3 bucket that contain your data. — item shape: {bucket: string, key: string, versionId?: string}
  error_report_location: record # The Amazon S3 destination where errors associated with the job creation request are saved. — shape: {bucket?: string, prefix?: string}
  job_configuration: record # Contains the configuration information of a job, such as the file format used to save data in Amazon S3. — shape: {fileFormat?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/jobs"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: jobName, var: job_name}, {name: jobRoleArn, var: job_role_arn}, {name: files, var: files}, {name: errorReportLocation, var: error_report_location}, {name: jobConfiguration, var: job_configuration}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, job_name: $job_name, job_role_arn: $job_role_arn, files: $files, error_report_location: $error_report_location, job_configuration: $job_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of bulk import job requests. For more information, see List bulk import jobs (CLI) (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/ListBulkImportJobs.html) in the IoT SiteWise User Guide.
#
# GET /jobs
# Returns: record<jobSummaries: table<id: string, name: string, status: string>, nextToken: string>
# operationId: ListBulkImportJobs
export def "list-bulk-import-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request.
  --filter: string@filter-completer-1 # You can use a filter to select the bulk import jobs that you want to retrieve.
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
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: filter, var: filter}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, filter: $filter, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a dashboard in an IoT SiteWise Monitor project.
#
# POST /dashboards
# Returns: record<dashboardId: string, dashboardArn: string>
# operationId: CreateDashboard
export def "create-dashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  project_id: string # The ID of the project in which to create the dashboard.
  dashboard_name: string # A friendly name for the dashboard.
  --dashboard-description: string # A description for the dashboard.
  dashboard_definition: string # The dashboard definition specified in a JSON literal. For detailed information, see Creating dashboards (CLI) (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/create-dashboards-using-aws-cli.html) in the IoT SiteWise User Guide.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --tags: record # A list of key-value pairs that contain metadata for the dashboard. For more information, see Tagging your IoT SiteWise resources (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/tag-resources.html) in the IoT SiteWise User Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dashboards"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectId, var: project_id}, {name: dashboardName, var: dashboard_name}, {name: dashboardDescription, var: dashboard_description}, {name: dashboardDefinition, var: dashboard_definition}, {name: clientToken, var: client_token}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, project_id: $project_id, dashboard_name: $dashboard_name, dashboard_description: $dashboard_description, dashboard_definition: $dashboard_definition, client_token: $client_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a gateway, which is a virtual or edge device that delivers industrial data streams from local servers to IoT SiteWise. For more information, see Ingesting data using a gateway (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/gateway-connector.html) in the IoT SiteWise User Guide.
#
# POST /20200301/gateways
# Returns: record<gatewayId: string, gatewayArn: string>
# operationId: CreateGateway
export def "create-gateway" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  gateway_name: string # A unique, friendly name for the gateway.
  gateway_platform: record # Contains a gateway's platform information. — shape: {greengrass?: record, greengrassV2?: record}
  --tags: record # A list of key-value pairs that contain metadata for the gateway. For more information, see Tagging your IoT SiteWise resources (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/tag-resources.html) in the IoT SiteWise User Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/20200301/gateways"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: gatewayName, var: gateway_name}, {name: gatewayPlatform, var: gateway_platform}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, gateway_name: $gateway_name, gateway_platform: $gateway_platform, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of gateways.
#
# GET /20200301/gateways
# Returns: record<gatewaySummaries: table<gatewayId: string, gatewayName: string, gatewayPlatform: record, gatewayCapabilitySummaries: list, creationDate: string, lastUpdateDate: string>, nextToken: string>
# operationId: ListGateways
export def "list-gateways" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 50
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
    path: "/20200301/gateways"
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

# Creates a portal, which can contain projects and dashboards. IoT SiteWise Monitor uses IAM Identity Center or IAM to authenticate portal users and manage user permissions. Before you can sign in to a new portal, you must add at least one identity to that portal. For more information, see Adding or removing portal administrators (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/administer-portals.html#portal-change-admins) in the IoT SiteWise User Guide.
#
# POST /portals
# Returns: record<portalId: string, portalArn: string, portalStartUrl: string, portalStatus: record<state: string, error: record<code: string, message: string>>, ssoApplicationId: string>
# operationId: CreatePortal
export def "create-portal" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  portal_name: string # A friendly name for the portal.
  --portal-description: string # A description for the portal.
  portal_contact_email: string # The Amazon Web Services administrator's contact email address.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --portal-logo-image-file: record # Contains an image file. — shape: {data?: string, type?: "PNG"}
  role_arn: string # The ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of a service role that allows the portal's users to access your IoT SiteWise resources on your behalf. For more information, see Using service roles for IoT SiteWise Monitor (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/monitor-service-role.html) in the IoT SiteWise User Guide.
  --tags: record # A list of key-value pairs that contain metadata for the portal. For more information, see Tagging your IoT SiteWise resources (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/tag-resources.html) in the IoT SiteWise User Guide.
  --portal-auth-mode: string@portal-auth-mode-completer # The service to use to authenticate users to the portal. Choose from the following options: SSO – The portal uses IAM Identity Center (successor to Single Sign-On) to authenticate users and manage user permissions. Before you can create a portal that uses IAM Identity Center, you must enable IAM Identity Center. For more information, see Enabling IAM Identity Center (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/monitor-get-started.html#mon-gs-sso) in the IoT SiteWise User Guide. This option is only available in Amazon Web Services Regions other than the China Regions. IAM – The portal uses Identity and Access Management to authenticate users and manage user permissions. You can't change this value after you create a portal. Default: SSO
  --notification-sender-email: string # The email address that sends alarm notifications. If you use the IoT Events managed Lambda function (https://docs.aws.amazon.com/iotevents/latest/developerguide/lambda-support.html) to manage your emails, you must verify the sender email address in Amazon SES (https://docs.aws.amazon.com/ses/latest/DeveloperGuide/verify-email-addresses.html).
  --alarms: record # Contains the configuration information of an alarm created in an IoT SiteWise Monitor portal. You can use the alarm to monitor an asset property and get notified when the asset property value is outside a specified range. For more information, see Monitoring with alarms (https://docs.aws.amazon.com/iot-sitewise/latest/appguide/monitor-alarms.html) in the IoT SiteWise Application Guide. — shape: {alarmRoleArn?: string, notificationLambdaArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portals"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: portalName, var: portal_name}, {name: portalDescription, var: portal_description}, {name: portalContactEmail, var: portal_contact_email}, {name: clientToken, var: client_token}, {name: portalLogoImageFile, var: portal_logo_image_file}, {name: roleArn, var: role_arn}, {name: tags, var: tags}, {name: portalAuthMode, var: portal_auth_mode}, {name: notificationSenderEmail, var: notification_sender_email}, {name: alarms, var: alarms}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, portal_name: $portal_name, portal_description: $portal_description, portal_contact_email: $portal_contact_email, client_token: $client_token, portal_logo_image_file: $portal_logo_image_file, role_arn: $role_arn, tags: $tags, portal_auth_mode: $portal_auth_mode, notification_sender_email: $notification_sender_email, alarms: $alarms
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of IoT SiteWise Monitor portals.
#
# GET /portals
# Returns: record<portalSummaries: table<id: string, name: string, description: string, startUrl: string, creationDate: string, lastUpdateDate: string, roleArn: string, status: record>, nextToken: string>
# operationId: ListPortals
export def "list-portals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 50
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
    path: "/portals"
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

# Creates a project in the specified portal. Make sure that the project name and description don't contain confidential information.
#
# POST /projects
# Returns: record<projectId: string, projectArn: string>
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
  portal_id: string # The ID of the portal in which to create the project.
  project_name: string # A friendly name for the project.
  --project-description: string # A description for the project.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --tags: record # A list of key-value pairs that contain metadata for the project. For more information, see Tagging your IoT SiteWise resources (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/tag-resources.html) in the IoT SiteWise User Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: portalId, var: portal_id}, {name: projectName, var: project_name}, {name: projectDescription, var: project_description}, {name: clientToken, var: client_token}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, portal_id: $portal_id, project_name: $project_name, project_description: $project_description, client_token: $client_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an access policy that grants the specified identity access to the specified IoT SiteWise Monitor resource. You can use this operation to revoke access to an IoT SiteWise Monitor resource.
#
# DELETE /access-policies/{accessPolicyId}
# Returns: record
# operationId: DeleteAccessPolicy
export def "delete-access-policy" [
  access_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
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
    path: "/access-policies/{accessPolicyId}"
    path_params: [{name: accessPolicyId, var: access_policy_id}]
    query: [{name: clientToken, var: client_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    access_policy_id: $access_policy_id, client_token: $client_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an access policy, which specifies an identity's access to an IoT SiteWise Monitor portal or project.
#
# GET /access-policies/{accessPolicyId}
# Returns: record<accessPolicyId: string, accessPolicyArn: string, accessPolicyIdentity: record<user: record<id: string>, group: record<id: string>, iamUser: record<arn: string>, iamRole: record<arn: string>>, accessPolicyResource: record<portal: record<id: string>, project: record<id: string>>, accessPolicyPermission: string, accessPolicyCreationDate: string, accessPolicyLastUpdateDate: string>
# operationId: DescribeAccessPolicy
export def "describe-access-policy" [
  access_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/access-policies/{accessPolicyId}"
    path_params: [{name: accessPolicyId, var: access_policy_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    access_policy_id: $access_policy_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing access policy that specifies an identity's access to an IoT SiteWise Monitor portal or project resource.
#
# PUT /access-policies/{accessPolicyId}
# Returns: record
# operationId: UpdateAccessPolicy
export def "update-access-policy" [
  access_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  access_policy_identity: record # Contains an identity that can access an IoT SiteWise Monitor resource. Currently, you can't use Amazon Web Services APIs to retrieve IAM Identity Center identity IDs. You can find the IAM Identity Center identity IDs in the URL of user and group pages in the IAM Identity Center console (https://console.aws.amazon.com/singlesignon). — shape: {user?: record, group?: record, iamUser?: record, iamRole?: record}
  access_policy_resource: record # Contains an IoT SiteWise Monitor resource ID for a portal or project. — shape: {portal?: record, project?: record}
  access_policy_permission: string@access-policy-permission-completer # The permission level for this access policy. Note that a project ADMINISTRATOR is also known as a project owner.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/access-policies/{accessPolicyId}"
    path_params: [{name: accessPolicyId, var: access_policy_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessPolicyIdentity, var: access_policy_identity}, {name: accessPolicyResource, var: access_policy_resource}, {name: accessPolicyPermission, var: access_policy_permission}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    access_policy_id: $access_policy_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, access_policy_identity: $access_policy_identity, access_policy_resource: $access_policy_resource, access_policy_permission: $access_policy_permission, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an asset. This action can't be undone. For more information, see Deleting assets and models (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/delete-assets-and-models.html) in the IoT SiteWise User Guide. You can't delete an asset that's associated to another asset. For more information, see DisassociateAssets (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_DisassociateAssets.html).
#
# DELETE /assets/{assetId}
# Returns: record<assetStatus: record<state: string, error: record<code: string, message: string, details: list>>>
# operationId: DeleteAsset
export def "delete-asset" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
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
    path: "/assets/{assetId}"
    path_params: [{name: assetId, var: asset_id}]
    query: [{name: clientToken, var: client_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    asset_id: $asset_id, client_token: $client_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about an asset.
#
# GET /assets/{assetId}
# Returns: record<assetId: string, assetArn: string, assetName: string, assetModelId: string, assetProperties: table<id: string, name: string, alias: string, notification: record, dataType: string, dataTypeSpec: string, unit: string>, assetHierarchies: table<id: string, name: string>, assetCompositeModels: table<name: string, description: string, type: string, properties: any, id: string>, assetCreationDate: string, assetLastUpdateDate: string, assetStatus: record<state: string, error: record<code: string, message: string, details: list>>, assetDescription: string>
# operationId: DescribeAsset
export def "describe-asset" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclude-properties: oneof<nothing, bool> # Whether or not to exclude asset properties from the response.
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
    path: "/assets/{assetId}"
    path_params: [{name: assetId, var: asset_id}]
    query: [{name: excludeProperties, var: exclude_properties}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id, exclude_properties: $exclude_properties, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an asset's name. For more information, see Updating assets and models (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/update-assets-and-models.html) in the IoT SiteWise User Guide.
#
# PUT /assets/{assetId}
# Returns: record<assetStatus: record<state: string, error: record<code: string, message: string, details: list>>>
# operationId: UpdateAsset
export def "update-asset" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  asset_name: string # A friendly name for the asset.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --asset-description: string # A description for the asset.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/assets/{assetId}"
    path_params: [{name: assetId, var: asset_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: assetName, var: asset_name}, {name: clientToken, var: client_token}, {name: assetDescription, var: asset_description}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    asset_id: $asset_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, asset_name: $asset_name, client_token: $client_token, asset_description: $asset_description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an asset model. This action can't be undone. You must delete all assets created from an asset model before you can delete the model. Also, you can't delete an asset model if a parent asset model exists that contains a property formula expression that depends on the asset model that you want to delete. For more information, see Deleting assets and models (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/delete-assets-and-models.html) in the IoT SiteWise User Guide.
#
# DELETE /asset-models/{assetModelId}
# Returns: record<assetModelStatus: record<state: string, error: record<code: string, message: string, details: list>>>
# operationId: DeleteAssetModel
export def "delete-asset-model" [
  asset_model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
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
    path: "/asset-models/{assetModelId}"
    path_params: [{name: assetModelId, var: asset_model_id}]
    query: [{name: clientToken, var: client_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    asset_model_id: $asset_model_id, client_token: $client_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about an asset model.
#
# GET /asset-models/{assetModelId}
# Returns: record<assetModelId: string, assetModelArn: string, assetModelName: string, assetModelDescription: string, assetModelProperties: table<id: string, name: string, dataType: string, dataTypeSpec: string, unit: string, type: record>, assetModelHierarchies: table<id: string, name: string, childAssetModelId: string>, assetModelCompositeModels: table<name: string, description: string, type: string, properties: any, id: string>, assetModelCreationDate: string, assetModelLastUpdateDate: string, assetModelStatus: record<state: string, error: record<code: string, message: string, details: list>>>
# operationId: DescribeAssetModel
export def "describe-asset-model" [
  asset_model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclude-properties: oneof<nothing, bool> # Whether or not to exclude asset model properties from the response.
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
    path: "/asset-models/{assetModelId}"
    path_params: [{name: assetModelId, var: asset_model_id}]
    query: [{name: excludeProperties, var: exclude_properties}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_model_id: $asset_model_id, exclude_properties: $exclude_properties, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an asset model and all of the assets that were created from the model. Each asset created from the model inherits the updated asset model's property and hierarchy definitions. For more information, see Updating assets and models (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/update-assets-and-models.html) in the IoT SiteWise User Guide. This operation overwrites the existing model with the provided model. To avoid deleting your asset model's properties or hierarchies, you must include their IDs and definitions in the updated asset model payload. For more information, see DescribeAssetModel (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_DescribeAssetModel.html). If you remove a property from an asset model, IoT SiteWise deletes all previous data for that property. If you remove a hierarchy definition from an asset model, IoT SiteWise disassociates every asset associated with that hierarchy. You can't change the type or data type of an existing property.
#
# PUT /asset-models/{assetModelId}
# Returns: record<assetModelStatus: record<state: string, error: record<code: string, message: string, details: list>>>
# operationId: UpdateAssetModel
export def "update-asset-model" [
  asset_model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  asset_model_name: string # A unique, friendly name for the asset model.
  --asset-model-description: string # A description for the asset model.
  --asset-model-properties: list # The updated property definitions of the asset model. For more information, see Asset properties (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/asset-properties.html) in the IoT SiteWise User Guide. You can specify up to 200 properties per asset model. For more information, see Quotas (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/quotas.html) in the IoT SiteWise User Guide. — item shape: {id?: string, name: string, dataType: "STRING"|"INTEGER"|"DOUBLE"|"BOOLEAN"|"STRUCT", dataTypeSpec?: string, unit?: string, type: record}
  --asset-model-hierarchies: list # The updated hierarchy definitions of the asset model. Each hierarchy specifies an asset model whose assets can be children of any other assets created from this asset model. For more information, see Asset hierarchies (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/asset-hierarchies.html) in the IoT SiteWise User Guide. You can specify up to 10 hierarchies per asset model. For more information, see Quotas (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/quotas.html) in the IoT SiteWise User Guide. — item shape: {id?: string, name: string, childAssetModelId: string}
  --asset-model-composite-models: list # The composite asset models that are part of this asset model. Composite asset models are asset models that contain specific properties. Each composite model has a type that defines the properties that the composite model supports. Use composite asset models to define alarms on this asset model. — item shape: {name: string, description?: string, type: string, properties?: any, id?: string}
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/asset-models/{assetModelId}"
    path_params: [{name: assetModelId, var: asset_model_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: assetModelName, var: asset_model_name}, {name: assetModelDescription, var: asset_model_description}, {name: assetModelProperties, var: asset_model_properties}, {name: assetModelHierarchies, var: asset_model_hierarchies}, {name: assetModelCompositeModels, var: asset_model_composite_models}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    asset_model_id: $asset_model_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, asset_model_name: $asset_model_name, asset_model_description: $asset_model_description, asset_model_properties: $asset_model_properties, asset_model_hierarchies: $asset_model_hierarchies, asset_model_composite_models: $asset_model_composite_models, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a dashboard from IoT SiteWise Monitor.
#
# DELETE /dashboards/{dashboardId}
# Returns: record
# operationId: DeleteDashboard
export def "delete-dashboard" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
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
    path: "/dashboards/{dashboardId}"
    path_params: [{name: dashboardId, var: dashboard_id}]
    query: [{name: clientToken, var: client_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    dashboard_id: $dashboard_id, client_token: $client_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a dashboard.
#
# GET /dashboards/{dashboardId}
# Returns: record<dashboardId: string, dashboardArn: string, dashboardName: string, projectId: string, dashboardDescription: string, dashboardDefinition: string, dashboardCreationDate: string, dashboardLastUpdateDate: string>
# operationId: DescribeDashboard
export def "describe-dashboard" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/dashboards/{dashboardId}"
    path_params: [{name: dashboardId, var: dashboard_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dashboard_id: $dashboard_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an IoT SiteWise Monitor dashboard.
#
# PUT /dashboards/{dashboardId}
# Returns: record
# operationId: UpdateDashboard
export def "update-dashboard" [
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  dashboard_name: string # A new friendly name for the dashboard.
  --dashboard-description: string # A new description for the dashboard.
  dashboard_definition: string # The new dashboard definition, as specified in a JSON literal. For detailed information, see Creating dashboards (CLI) (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/create-dashboards-using-aws-cli.html) in the IoT SiteWise User Guide.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/dashboards/{dashboardId}"
    path_params: [{name: dashboardId, var: dashboard_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: dashboardName, var: dashboard_name}, {name: dashboardDescription, var: dashboard_description}, {name: dashboardDefinition, var: dashboard_definition}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dashboard_id: $dashboard_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, dashboard_name: $dashboard_name, dashboard_description: $dashboard_description, dashboard_definition: $dashboard_definition, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a gateway from IoT SiteWise. When you delete a gateway, some of the gateway's files remain in your gateway's file system.
#
# DELETE /20200301/gateways/{gatewayId}
# operationId: DeleteGateway
export def "delete-gateway" [
  gateway_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/20200301/gateways/{gatewayId}"
    path_params: [{name: gatewayId, var: gateway_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    gateway_id: $gateway_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a gateway.
#
# GET /20200301/gateways/{gatewayId}
# Returns: record<gatewayId: string, gatewayName: string, gatewayArn: string, gatewayPlatform: record<greengrass: record<groupArn: string>, greengrassV2: record<coreDeviceThingName: string>>, gatewayCapabilitySummaries: table<capabilityNamespace: string, capabilitySyncStatus: string>, creationDate: string, lastUpdateDate: string>
# operationId: DescribeGateway
export def "describe-gateway" [
  gateway_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/20200301/gateways/{gatewayId}"
    path_params: [{name: gatewayId, var: gateway_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    gateway_id: $gateway_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a gateway's name.
#
# PUT /20200301/gateways/{gatewayId}
# operationId: UpdateGateway
export def "update-gateway" [
  gateway_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  gateway_name: string # A unique, friendly name for the gateway.
]: any -> any {
  $in | http-request {
    method: put
    path: "/20200301/gateways/{gatewayId}"
    path_params: [{name: gatewayId, var: gateway_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: gatewayName, var: gateway_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    gateway_id: $gateway_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, gateway_name: $gateway_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a portal from IoT SiteWise Monitor.
#
# DELETE /portals/{portalId}
# Returns: record<portalStatus: record<state: string, error: record<code: string, message: string>>>
# operationId: DeletePortal
export def "delete-portal" [
  portal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
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
    path: "/portals/{portalId}"
    path_params: [{name: portalId, var: portal_id}]
    query: [{name: clientToken, var: client_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    portal_id: $portal_id, client_token: $client_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a portal.
#
# GET /portals/{portalId}
# Returns: record<portalId: string, portalArn: string, portalName: string, portalDescription: string, portalClientId: string, portalStartUrl: string, portalContactEmail: string, portalStatus: record<state: string, error: record<code: string, message: string>>, portalCreationDate: string, portalLastUpdateDate: string, portalLogoImageLocation: record<id: string, url: string>, roleArn: string, portalAuthMode: string, notificationSenderEmail: string, alarms: record<alarmRoleArn: string, notificationLambdaArn: string>>
# operationId: DescribePortal
export def "describe-portal" [
  portal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/portals/{portalId}"
    path_params: [{name: portalId, var: portal_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    portal_id: $portal_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an IoT SiteWise Monitor portal.
#
# PUT /portals/{portalId}
# Returns: record<portalStatus: record<state: string, error: record<code: string, message: string>>>
# operationId: UpdatePortal
export def "update-portal" [
  portal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  portal_name: string # A new friendly name for the portal.
  --portal-description: string # A new description for the portal.
  portal_contact_email: string # The Amazon Web Services administrator's contact email address.
  --portal-logo-image: record # Contains an image that is one of the following: An image file. Choose this option to upload a new image. The ID of an existing image. Choose this option to keep an existing image. — shape: {id?: string, file?: record}
  role_arn: string # The ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of a service role that allows the portal's users to access your IoT SiteWise resources on your behalf. For more information, see Using service roles for IoT SiteWise Monitor (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/monitor-service-role.html) in the IoT SiteWise User Guide.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --notification-sender-email: string # The email address that sends alarm notifications.
  --alarms: record # Contains the configuration information of an alarm created in an IoT SiteWise Monitor portal. You can use the alarm to monitor an asset property and get notified when the asset property value is outside a specified range. For more information, see Monitoring with alarms (https://docs.aws.amazon.com/iot-sitewise/latest/appguide/monitor-alarms.html) in the IoT SiteWise Application Guide. — shape: {alarmRoleArn?: string, notificationLambdaArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/portals/{portalId}"
    path_params: [{name: portalId, var: portal_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: portalName, var: portal_name}, {name: portalDescription, var: portal_description}, {name: portalContactEmail, var: portal_contact_email}, {name: portalLogoImage, var: portal_logo_image}, {name: roleArn, var: role_arn}, {name: clientToken, var: client_token}, {name: notificationSenderEmail, var: notification_sender_email}, {name: alarms, var: alarms}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    portal_id: $portal_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, portal_name: $portal_name, portal_description: $portal_description, portal_contact_email: $portal_contact_email, portal_logo_image: $portal_logo_image, role_arn: $role_arn, client_token: $client_token, notification_sender_email: $notification_sender_email, alarms: $alarms
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a project from IoT SiteWise Monitor.
#
# DELETE /projects/{projectId}
# Returns: record
# operationId: DeleteProject
export def "delete-project" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
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
    path: "/projects/{projectId}"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: clientToken, var: client_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_id: $project_id, client_token: $client_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a project.
#
# GET /projects/{projectId}
# Returns: record<projectId: string, projectArn: string, projectName: string, portalId: string, projectDescription: string, projectCreationDate: string, projectLastUpdateDate: string>
# operationId: DescribeProject
export def "describe-project" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/projects/{projectId}"
    path_params: [{name: projectId, var: project_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an IoT SiteWise Monitor project.
#
# PUT /projects/{projectId}
# Returns: record
# operationId: UpdateProject
export def "update-project" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  project_name: string # A new friendly name for the project.
  --project-description: string # A new description for the project.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{projectId}"
    path_params: [{name: projectId, var: project_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectName, var: project_name}, {name: projectDescription, var: project_description}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, project_name: $project_name, project_description: $project_description, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a time series (data stream). If you delete a time series that's associated with an asset property, the asset property still exists, but the time series will no longer be associated with this asset property. To identify a time series, do one of the following: If the time series isn't associated with an asset property, specify the alias of the time series. If the time series is associated with an asset property, specify one of the following: The alias of the time series. The assetId and propertyId that identifies the asset property.
#
# POST /timeseries/delete/
# operationId: DeleteTimeSeries
export def "delete-time-series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string # The alias that identifies the time series.
  --asset-id: string # The ID of the asset in which the asset property was created.
  --property-id: string # The ID of the asset property.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> any {
  $in | http-request {
    method: post
    path: "/timeseries/delete/"
    query: [{name: alias, var: alias}, {name: assetId, var: asset_id}, {name: propertyId, var: property_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alias: $alias, asset_id: $asset_id, property_id: $property_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about an asset property. When you call this operation for an attribute property, this response includes the default attribute value that you define in the asset model. If you update the default value in the model, this operation's response includes the new default value. This operation doesn't return the value of the asset property. To get the value of an asset property, use GetAssetPropertyValue (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_GetAssetPropertyValue.html).
#
# GET /assets/{assetId}/properties/{propertyId}
# Returns: record<assetId: string, assetName: string, assetModelId: string, assetProperty: record<id: string, name: string, alias: string, notification: record<topic: string, state: string>, dataType: string, unit: string, type: record<attribute: record, measurement: record, transform: record, metric: record>>, compositeModel: record<name: string, type: string, assetProperty: record<id: string, name: string, alias: string, notification: record, dataType: string, unit: string, type: record>, id: string>>
# operationId: DescribeAssetProperty
export def "describe-asset-property" [
  asset_id: string
  property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/assets/{assetId}/properties/{propertyId}"
    path_params: [{name: assetId, var: asset_id}, {name: propertyId, var: property_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id, property_id: $property_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an asset property's alias and notification state. This operation overwrites the property's existing alias and notification state. To keep your existing property's alias or notification state, you must include the existing values in the UpdateAssetProperty request. For more information, see DescribeAssetProperty (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_DescribeAssetProperty.html).
#
# PUT /assets/{assetId}/properties/{propertyId}
# operationId: UpdateAssetProperty
export def "update-asset-property" [
  asset_id: string
  property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --property-alias: string # The alias that identifies the property, such as an OPC-UA server data stream path (for example, /company/windfarm/3/turbine/7/temperature). For more information, see Mapping industrial data streams to asset properties (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/connect-data-streams.html) in the IoT SiteWise User Guide. If you omit this parameter, the alias is removed from the property.
  --property-notification-state: string@property-notification-state-completer # The MQTT notification state (enabled or disabled) for this asset property. When the notification state is enabled, IoT SiteWise publishes property value updates to a unique MQTT topic. For more information, see Interacting with other services (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/interact-with-other-services.html) in the IoT SiteWise User Guide. If you omit this parameter, the notification state is set to DISABLED.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
  --property-unit: string # The unit of measure (such as Newtons or RPM) of the asset property. If you don't specify a value for this parameter, the service uses the value of the assetModelProperty in the asset model.
]: any -> any {
  $in | http-request {
    method: put
    path: "/assets/{assetId}/properties/{propertyId}"
    path_params: [{name: assetId, var: asset_id}, {name: propertyId, var: property_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: propertyAlias, var: property_alias}, {name: propertyNotificationState, var: property_notification_state}, {name: clientToken, var: client_token}, {name: propertyUnit, var: property_unit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id, property_id: $property_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, property_alias: $property_alias, property_notification_state: $property_notification_state, client_token: $client_token, property_unit: $property_unit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a bulk import job request. For more information, see Describe a bulk import job (CLI) (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/DescribeBulkImportJob.html) in the Amazon Simple Storage Service User Guide.
#
# GET /jobs/{jobId}
# Returns: record<jobId: string, jobName: string, jobStatus: string, jobRoleArn: string, files: table<bucket: string, key: string, versionId: string>, errorReportLocation: record<bucket: string, prefix: string>, jobConfiguration: record<fileFormat: record<csv: record>>, jobCreationDate: string, jobLastUpdateDate: string>
# operationId: DescribeBulkImportJob
export def "describe-bulk-import-job" [
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

# Retrieves information about the default encryption configuration for the Amazon Web Services account in the default or specified Region. For more information, see Key management (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/key-management.html) in the IoT SiteWise User Guide.
#
# GET /configuration/account/encryption
# Returns: record<encryptionType: string, kmsKeyArn: string, configurationStatus: record<state: string, error: record<code: string, message: string>>>
# operationId: DescribeDefaultEncryptionConfiguration
export def "describe-default-encryption-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/configuration/account/encryption"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the default encryption configuration for the Amazon Web Services account. For more information, see Key management (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/key-management.html) in the IoT SiteWise User Guide.
#
# POST /configuration/account/encryption
# Returns: record<encryptionType: string, kmsKeyArn: string, configurationStatus: record<state: string, error: record<code: string, message: string>>>
# operationId: PutDefaultEncryptionConfiguration
export def "put-default-encryption-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  encryption_type: string@encryption-type-completer # The type of encryption used for the encryption configuration.
  --kms-key-id: string # The Key ID of the customer managed key used for KMS encryption. This is required if you use KMS_BASED_ENCRYPTION.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/configuration/account/encryption"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: encryptionType, var: encryption_type}, {name: kmsKeyId, var: kms_key_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, encryption_type: $encryption_type, kms_key_id: $kms_key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a gateway capability configuration. Each gateway capability defines data sources for a gateway. A capability configuration can contain multiple data source configurations. If you define OPC-UA sources for a gateway in the IoT SiteWise console, all of your OPC-UA sources are stored in one capability configuration. To list all capability configurations for a gateway, use DescribeGateway (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_DescribeGateway.html).
#
# GET /20200301/gateways/{gatewayId}/capability/{capabilityNamespace}
# Returns: record<gatewayId: string, capabilityNamespace: string, capabilityConfiguration: string, capabilitySyncStatus: string>
# operationId: DescribeGatewayCapabilityConfiguration
export def "describe-gateway-capability-configuration" [
  gateway_id: string
  capability_namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/20200301/gateways/{gatewayId}/capability/{capabilityNamespace}"
    path_params: [{name: gatewayId, var: gateway_id}, {name: capabilityNamespace, var: capability_namespace}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    gateway_id: $gateway_id, capability_namespace: $capability_namespace, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the current IoT SiteWise logging options.
#
# GET /logging
# Returns: record<loggingOptions: record<level: string>>
# operationId: DescribeLoggingOptions
export def "describe-logging-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/logging"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets logging options for IoT SiteWise.
#
# PUT /logging
# Returns: record
# operationId: PutLoggingOptions
export def "put-logging-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  logging_options: record # Contains logging options. — shape: {level?: "ERROR"|"INFO"|"OFF"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/logging"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: loggingOptions, var: logging_options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, logging_options: $logging_options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the storage configuration for IoT SiteWise.
#
# GET /configuration/account/storage
# Returns: record<storageType: string, multiLayerStorage: record<customerManagedS3Storage: record<s3ResourceArn: string, roleArn: string>>, disassociatedDataStorage: string, retentionPeriod: record<numberOfDays: int, unlimited: bool>, configurationStatus: record<state: string, error: record<code: string, message: string>>, lastUpdateDate: string>
# operationId: DescribeStorageConfiguration
export def "describe-storage-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/configuration/account/storage"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configures storage settings for IoT SiteWise.
#
# POST /configuration/account/storage
# Returns: record<storageType: string, multiLayerStorage: record<customerManagedS3Storage: record<s3ResourceArn: string, roleArn: string>>, disassociatedDataStorage: string, retentionPeriod: record<numberOfDays: int, unlimited: bool>, configurationStatus: record<state: string, error: record<code: string, message: string>>>
# operationId: PutStorageConfiguration
export def "put-storage-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  storage_type: string@storage-type-completer # The storage tier that you specified for your data. The storageType parameter can be one of the following values: SITEWISE_DEFAULT_STORAGE – IoT SiteWise saves your data into the hot tier. The hot tier is a service-managed database. MULTI_LAYER_STORAGE – IoT SiteWise saves your data in both the cold tier and the hot tier. The cold tier is a customer-managed Amazon S3 bucket.
  --multi-layer-storage: record # Contains information about the storage destination. — shape: {customerManagedS3Storage?: record}
  --disassociated-data-storage: string@disassociated-data-storage-completer # Contains the storage configuration for time series (data streams) that aren't associated with asset properties. The disassociatedDataStorage can be one of the following values: ENABLED – IoT SiteWise accepts time series that aren't associated with asset properties. After the disassociatedDataStorage is enabled, you can't disable it. DISABLED – IoT SiteWise doesn't accept time series (data streams) that aren't associated with asset properties. For more information, see Data streams (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/data-streams.html) in the IoT SiteWise User Guide.
  --retention-period: record # How many days your data is kept in the hot tier. By default, your data is kept indefinitely in the hot tier. — shape: {numberOfDays?: int, unlimited?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/configuration/account/storage"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: storageType, var: storage_type}, {name: multiLayerStorage, var: multi_layer_storage}, {name: disassociatedDataStorage, var: disassociated_data_storage}, {name: retentionPeriod, var: retention_period}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, storage_type: $storage_type, multi_layer_storage: $multi_layer_storage, disassociated_data_storage: $disassociated_data_storage, retention_period: $retention_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a time series (data stream). To identify a time series, do one of the following: If the time series isn't associated with an asset property, specify the alias of the time series. If the time series is associated with an asset property, specify one of the following: The alias of the time series. The assetId and propertyId that identifies the asset property.
#
# GET /timeseries/describe/
# Returns: record<assetId: string, propertyId: string, alias: string, timeSeriesId: string, dataType: string, dataTypeSpec: string, timeSeriesCreationDate: string, timeSeriesLastUpdateDate: string, timeSeriesArn: string>
# operationId: DescribeTimeSeries
export def "describe-time-series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string # The alias that identifies the time series.
  --asset-id: string # The ID of the asset in which the asset property was created.
  --property-id: string # The ID of the asset property.
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
    path: "/timeseries/describe/"
    query: [{name: alias, var: alias}, {name: assetId, var: asset_id}, {name: propertyId, var: property_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alias: $alias, asset_id: $asset_id, property_id: $property_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates a child asset from the given parent asset through a hierarchy defined in the parent asset's model.
#
# POST /assets/{assetId}/disassociate
# operationId: DisassociateAssets
export def "disassociate-assets" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  hierarchy_id: string # The ID of a hierarchy in the parent asset's model. Hierarchies allow different groupings of assets to be formed that all come from the same asset model. You can use the hierarchy ID to identify the correct asset to disassociate. For more information, see Asset hierarchies (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/asset-hierarchies.html) in the IoT SiteWise User Guide.
  child_asset_id: string # The ID of the child asset to disassociate.
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> any {
  $in | http-request {
    method: post
    path: "/assets/{assetId}/disassociate"
    path_params: [{name: assetId, var: asset_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: hierarchyId, var: hierarchy_id}, {name: childAssetId, var: child_asset_id}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, hierarchy_id: $hierarchy_id, child_asset_id: $child_asset_id, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates a time series (data stream) from an asset property.
#
# POST /timeseries/disassociate/
# operationId: DisassociateTimeSeriesFromAssetProperty
export def "disassociate-time-series-from-asset-property" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string # The alias that identifies the time series. (required)
  --asset-id: string # The ID of the asset in which the asset property was created. (required)
  --property-id: string # The ID of the asset property. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # A unique case-sensitive identifier that you can provide to ensure the idempotency of the request. Don't reuse this client token if a new idempotent request is required.
]: any -> any {
  $in | http-request {
    method: post
    path: "/timeseries/disassociate/"
    query: [{name: alias, var: alias, required: true}, {name: assetId, var: asset_id, required: true}, {name: propertyId, var: property_id, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alias: $alias, asset_id: $asset_id, property_id: $property_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets aggregated values for an asset property. For more information, see Querying aggregates (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/query-industrial-data.html#aggregates) in the IoT SiteWise User Guide. To identify an asset property, you must specify one of the following: The assetId and propertyId of an asset property. A propertyAlias, which is a data stream alias (for example, /company/windfarm/3/turbine/7/temperature). To define an asset property's alias, see UpdateAssetProperty (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_UpdateAssetProperty.html).
#
# GET /properties/aggregates
# Returns: record<aggregatedValues: table<timestamp: string, quality: string, value: record>, nextToken: string>
# operationId: GetAssetPropertyAggregates
export def "get-asset-property-aggregates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-id: string # The ID of the asset.
  --property-id: string # The ID of the asset property.
  --property-alias: string # The alias that identifies the property, such as an OPC-UA server data stream path (for example, /company/windfarm/3/turbine/7/temperature). For more information, see Mapping industrial data streams to asset properties (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/connect-data-streams.html) in the IoT SiteWise User Guide.
  --aggregate-types: list<string> # The data aggregating function. (required)
  --resolution: string # The time interval over which to aggregate data. (required)
  --qualities: list<string> # The quality by which to filter asset data.
  --start-date: string # The exclusive start of the range from which to query historical data, expressed in seconds in Unix epoch time. (required, format: date-time)
  --end-date: string # The inclusive end of the range from which to query historical data, expressed in seconds in Unix epoch time. (required, format: date-time)
  --time-ordering: string@time-ordering-completer # The chronological sorting order of the requested information. Default: ASCENDING
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 100
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
    path: "/properties/aggregates"
    query: [{name: assetId, var: asset_id}, {name: propertyId, var: property_id}, {name: propertyAlias, var: property_alias}, {name: aggregateTypes, var: aggregate_types, style: multi, required: true}, {name: resolution, var: resolution, required: true}, {name: qualities, var: qualities, style: multi}, {name: startDate, var: start_date, required: true}, {name: endDate, var: end_date, required: true}, {name: timeOrdering, var: time_ordering}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id, property_id: $property_id, property_alias: $property_alias, aggregate_types: $aggregate_types, resolution: $resolution, qualities: $qualities, start_date: $start_date, end_date: $end_date, time_ordering: $time_ordering, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an asset property's current value. For more information, see Querying current values (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/query-industrial-data.html#current-values) in the IoT SiteWise User Guide. To identify an asset property, you must specify one of the following: The assetId and propertyId of an asset property. A propertyAlias, which is a data stream alias (for example, /company/windfarm/3/turbine/7/temperature). To define an asset property's alias, see UpdateAssetProperty (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_UpdateAssetProperty.html).
#
# GET /properties/latest
# Returns: record<propertyValue: record<value: record<stringValue: string, integerValue: int, doubleValue: float, booleanValue: bool>, timestamp: record<timeInSeconds: int, offsetInNanos: int>, quality: string>>
# operationId: GetAssetPropertyValue
export def "get-asset-property-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-id: string # The ID of the asset.
  --property-id: string # The ID of the asset property.
  --property-alias: string # The alias that identifies the property, such as an OPC-UA server data stream path (for example, /company/windfarm/3/turbine/7/temperature). For more information, see Mapping industrial data streams to asset properties (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/connect-data-streams.html) in the IoT SiteWise User Guide.
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
    path: "/properties/latest"
    query: [{name: assetId, var: asset_id}, {name: propertyId, var: property_id}, {name: propertyAlias, var: property_alias}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id, property_id: $property_id, property_alias: $property_alias, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the history of an asset property's values. For more information, see Querying historical values (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/query-industrial-data.html#historical-values) in the IoT SiteWise User Guide. To identify an asset property, you must specify one of the following: The assetId and propertyId of an asset property. A propertyAlias, which is a data stream alias (for example, /company/windfarm/3/turbine/7/temperature). To define an asset property's alias, see UpdateAssetProperty (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_UpdateAssetProperty.html).
#
# GET /properties/history
# Returns: record<assetPropertyValueHistory: table<value: record, timestamp: record, quality: string>, nextToken: string>
# operationId: GetAssetPropertyValueHistory
export def "get-asset-property-value-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-id: string # The ID of the asset.
  --property-id: string # The ID of the asset property.
  --property-alias: string # The alias that identifies the property, such as an OPC-UA server data stream path (for example, /company/windfarm/3/turbine/7/temperature). For more information, see Mapping industrial data streams to asset properties (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/connect-data-streams.html) in the IoT SiteWise User Guide.
  --start-date: string # The exclusive start of the range from which to query historical data, expressed in seconds in Unix epoch time. (format: date-time)
  --end-date: string # The inclusive end of the range from which to query historical data, expressed in seconds in Unix epoch time. (format: date-time)
  --qualities: list<string> # The quality by which to filter asset data.
  --time-ordering: string@time-ordering-completer # The chronological sorting order of the requested information. Default: ASCENDING
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 100
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
    path: "/properties/history"
    query: [{name: assetId, var: asset_id}, {name: propertyId, var: property_id}, {name: propertyAlias, var: property_alias}, {name: startDate, var: start_date}, {name: endDate, var: end_date}, {name: qualities, var: qualities, style: multi}, {name: timeOrdering, var: time_ordering}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id, property_id: $property_id, property_alias: $property_alias, start_date: $start_date, end_date: $end_date, qualities: $qualities, time_ordering: $time_ordering, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get interpolated values for an asset property for a specified time interval, during a period of time. If your time series is missing data points during the specified time interval, you can use interpolation to estimate the missing data. For example, you can use this operation to return the interpolated temperature values for a wind turbine every 24 hours over a duration of 7 days. To identify an asset property, you must specify one of the following: The assetId and propertyId of an asset property. A propertyAlias, which is a data stream alias (for example, /company/windfarm/3/turbine/7/temperature). To define an asset property's alias, see UpdateAssetProperty (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_UpdateAssetProperty.html).
#
# GET /properties/interpolated
# Returns: record<interpolatedAssetPropertyValues: table<timestamp: record, value: record>, nextToken: string>
# operationId: GetInterpolatedAssetPropertyValues
export def "get-interpolated-asset-property-values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-id: string # The ID of the asset.
  --property-id: string # The ID of the asset property.
  --property-alias: string # The alias that identifies the property, such as an OPC-UA server data stream path (for example, /company/windfarm/3/turbine/7/temperature). For more information, see Mapping industrial data streams to asset properties (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/connect-data-streams.html) in the IoT SiteWise User Guide.
  --start-time-in-seconds: int # The exclusive start of the range from which to interpolate data, expressed in seconds in Unix epoch time. (required)
  --start-time-offset-in-nanos: int # The nanosecond offset converted from startTimeInSeconds.
  --end-time-in-seconds: int # The inclusive end of the range from which to interpolate data, expressed in seconds in Unix epoch time. (required)
  --end-time-offset-in-nanos: int # The nanosecond offset converted from endTimeInSeconds.
  --quality: string@quality-completer # The quality of the asset property value. You can use this parameter as a filter to choose only the asset property values that have a specific quality. (required)
  --interval-in-seconds: int # The time interval in seconds over which to interpolate data. Each interval starts when the previous one ends. (required)
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. If not specified, the default value is 10.
  --type: string # The interpolation type. Valid values: LINEAR_INTERPOLATION | LOCF_INTERPOLATION LINEAR_INTERPOLATION – Estimates missing data using linear interpolation (https://en.wikipedia.org/wiki/Linear_interpolation). For example, you can use this operation to return the interpolated temperature values for a wind turbine every 24 hours over a duration of 7 days. If the interpolation starts July 1, 2021, at 9 AM, IoT SiteWise returns the first interpolated value on July 2, 2021, at 9 AM, the second interpolated value on July 3, 2021, at 9 AM, and so on. LOCF_INTERPOLATION – Estimates missing data using last observation carried forward interpolation If no data point is found for an interval, IoT SiteWise returns the last observed data point for the previous interval and carries forward this interpolated value until a new data point is found. For example, you can get the state of an on-off valve every 24 hours over a duration of 7 days. If the interpolation starts July 1, 2021, at 9 AM, IoT SiteWise returns the last observed data point between July 1, 2021, at 9 AM and July 2, 2021, at 9 AM as the first interpolated value. If a data point isn't found after 9 AM on July 2, 2021, IoT SiteWise uses the same interpolated value for the rest of the days. (required)
  --interval-window-in-seconds: int # The query interval for the window, in seconds. IoT SiteWise computes each interpolated value by using data points from the timestamp of each interval, minus the window to the timestamp of each interval plus the window. If not specified, the window ranges between the start time minus the interval and the end time plus the interval. If you specify a value for the intervalWindowInSeconds parameter, the value for the type parameter must be LINEAR_INTERPOLATION. If a data point isn't found during the specified query window, IoT SiteWise won't return an interpolated value for the interval. This indicates that there's a gap in the ingested data points. For example, you can get the interpolated temperature values for a wind turbine every 24 hours over a duration of 7 days. If the interpolation starts on July 1, 2021, at 9 AM with a window of 2 hours, IoT SiteWise uses the data points from 7 AM (9 AM minus 2 hours) to 11 AM (9 AM plus 2 hours) on July 2, 2021 to compute the first interpolated value. Next, IoT SiteWise uses the data points from 7 AM (9 AM minus 2 hours) to 11 AM (9 AM plus 2 hours) on July 3, 2021 to compute the second interpolated value, and so on.
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
    path: "/properties/interpolated"
    query: [{name: assetId, var: asset_id}, {name: propertyId, var: property_id}, {name: propertyAlias, var: property_alias}, {name: startTimeInSeconds, var: start_time_in_seconds, required: true}, {name: startTimeOffsetInNanos, var: start_time_offset_in_nanos}, {name: endTimeInSeconds, var: end_time_in_seconds, required: true}, {name: endTimeOffsetInNanos, var: end_time_offset_in_nanos}, {name: quality, var: quality, required: true}, {name: intervalInSeconds, var: interval_in_seconds, required: true}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: type, var: type, required: true}, {name: intervalWindowInSeconds, var: interval_window_in_seconds}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id, property_id: $property_id, property_alias: $property_alias, start_time_in_seconds: $start_time_in_seconds, start_time_offset_in_nanos: $start_time_offset_in_nanos, end_time_in_seconds: $end_time_in_seconds, end_time_offset_in_nanos: $end_time_offset_in_nanos, quality: $quality, interval_in_seconds: $interval_in_seconds, next_token: $next_token, max_results: $max_results, type: $type, interval_window_in_seconds: $interval_window_in_seconds, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of properties associated with an asset model. If you update properties associated with the model before you finish listing all the properties, you need to start all over again.
#
# GET /asset-models/{assetModelId}/properties
# Returns: record<assetModelPropertySummaries: table<id: string, name: string, dataType: string, dataTypeSpec: string, unit: string, type: record, assetModelCompositeModelId: string>, nextToken: string>
# operationId: ListAssetModelProperties
export def "list-asset-model-properties" [
  asset_model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. If not specified, the default value is 50.
  --filter: string@filter-completer-2 # Filters the requested list of asset model properties. You can choose one of the following options: ALL – The list includes all asset model properties for a given asset model ID. BASE – The list includes only base asset model properties for a given asset model ID. Default: BASE
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
    path: "/asset-models/{assetModelId}/properties"
    path_params: [{name: assetModelId, var: asset_model_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: filter, var: filter}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_model_id: $asset_model_id, next_token: $next_token, max_results: $max_results, filter: $filter, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of properties associated with an asset. If you update properties associated with the model before you finish listing all the properties, you need to start all over again.
#
# GET /assets/{assetId}/properties
# Returns: record<assetPropertySummaries: table<id: string, alias: string, unit: string, notification: record, assetCompositeModelId: string>, nextToken: string>
# operationId: ListAssetProperties
export def "list-asset-properties" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. If not specified, the default value is 50.
  --filter: string@filter-completer-2 # Filters the requested list of asset properties. You can choose one of the following options: ALL – The list includes all asset properties for a given asset model ID. BASE – The list includes only base asset properties for a given asset model ID. Default: BASE
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
    path: "/assets/{assetId}/properties"
    path_params: [{name: assetId, var: asset_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: filter, var: filter}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id, next_token: $next_token, max_results: $max_results, filter: $filter, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of asset relationships for an asset. You can use this operation to identify an asset's root asset and all associated assets between that asset and its root.
#
# GET /assets/{assetId}/assetRelationships
# Returns: record<assetRelationshipSummaries: table<hierarchyInfo: record, relationshipType: string>, nextToken: string>
# operationId: ListAssetRelationships
export def "list-asset-relationships" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --traversal-type: string@traversal-type-completer # The type of traversal to use to identify asset relationships. Choose the following option: PATH_TO_ROOT – Identify the asset's parent assets up to the root asset. The asset that you specify in assetId is the first result in the list of assetRelationshipSummaries, and the root asset is the last result. (required)
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request.
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
    path: "/assets/{assetId}/assetRelationships"
    path_params: [{name: assetId, var: asset_id}]
    query: [{name: traversalType, var: traversal_type, required: true, default: PATH_TO_ROOT}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id, traversal_type: $traversal_type, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of associated assets. You can use this operation to do the following: List child assets associated to a parent asset by a hierarchy that you specify. List an asset's parent asset.
#
# GET /assets/{assetId}/hierarchies
# Returns: record<assetSummaries: table<id: string, arn: string, name: string, assetModelId: string, creationDate: string, lastUpdateDate: string, status: record, hierarchies: list, description: string>, nextToken: string>
# operationId: ListAssociatedAssets
export def "list-associated-assets" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hierarchy-id: string # The ID of the hierarchy by which child assets are associated to the asset. To find a hierarchy ID, use the DescribeAsset (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_DescribeAsset.html) or DescribeAssetModel (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_DescribeAssetModel.html) operations. This parameter is required if you choose CHILD for traversalDirection. For more information, see Asset hierarchies (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/asset-hierarchies.html) in the IoT SiteWise User Guide.
  --traversal-direction: string@traversal-direction-completer # The direction to list associated assets. Choose one of the following options: CHILD – The list includes all child assets associated to the asset. The hierarchyId parameter is required if you choose CHILD. PARENT – The list includes the asset's parent asset. Default: CHILD
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 50
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
    path: "/assets/{assetId}/hierarchies"
    path_params: [{name: assetId, var: asset_id}]
    query: [{name: hierarchyId, var: hierarchy_id}, {name: traversalDirection, var: traversal_direction}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id, hierarchy_id: $hierarchy_id, traversal_direction: $traversal_direction, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of dashboards for an IoT SiteWise Monitor project.
#
# GET /dashboards
# Returns: record<dashboardSummaries: table<id: string, name: string, description: string, creationDate: string, lastUpdateDate: string>, nextToken: string>
# operationId: ListDashboards
export def "list-dashboards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string # The ID of the project. (required)
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 50
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
    path: "/dashboards"
    query: [{name: projectId, var: project_id, required: true}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of assets associated with an IoT SiteWise Monitor project.
#
# GET /projects/{projectId}/assets
# Returns: record<assetIds: list<string>, nextToken: string>
# operationId: ListProjectAssets
export def "list-project-assets" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 50
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
    path: "/projects/{projectId}/assets"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of projects for an IoT SiteWise Monitor portal.
#
# GET /projects
# Returns: record<projectSummaries: table<id: string, name: string, description: string, creationDate: string, lastUpdateDate: string>, nextToken: string>
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
  --portal-id: string # The ID of the portal. (required)
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request. Default: 50
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
    path: "/projects"
    query: [{name: portalId, var: portal_id, required: true}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    portal_id: $portal_id, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the list of tags for an IoT SiteWise resource.
#
# GET /tags
# Returns: record<tags: record>
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
  --resource-arn: string # The ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resource. (required)
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
    query: [{name: resourceArn, var: resource_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds tags to an IoT SiteWise resource. If a tag already exists for the resource, this operation updates the tag's value.
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
  --resource-arn: string # The ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resource to tag. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: record # A list of key-value pairs that contain metadata for the resource. For more information, see Tagging your IoT SiteWise resources (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/tag-resources.html) in the IoT SiteWise User Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags"
    query: [{name: resourceArn, var: resource_arn, required: true}]
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

# Retrieves a paginated list of time series (data streams).
#
# GET /timeseries/
# Returns: record<TimeSeriesSummaries: table<assetId: string, propertyId: string, alias: string, timeSeriesId: string, dataType: string, dataTypeSpec: string, timeSeriesCreationDate: string, timeSeriesLastUpdateDate: string, timeSeriesArn: string>, nextToken: string>
# operationId: ListTimeSeries
export def "list-time-series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to be used for the next set of paginated results.
  --max-results: int # The maximum number of results to return for each paginated request.
  --asset-id: string # The ID of the asset in which the asset property was created.
  --alias-prefix: string # The alias prefix of the time series.
  --time-series-type: string@time-series-type-completer # The type of the time series. The time series type can be one of the following values: ASSOCIATED – The time series is associated with an asset property. DISASSOCIATED – The time series isn't associated with any asset property.
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
    path: "/timeseries/"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: assetId, var: asset_id}, {name: aliasPrefix, var: alias_prefix}, {name: timeSeriesType, var: time_series_type}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, asset_id: $asset_id, alias_prefix: $alias_prefix, time_series_type: $time_series_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a tag from an IoT SiteWise resource.
#
# DELETE /tags
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
  --resource-arn: string # The ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resource to untag. (required)
  --tag-keys: list<string> # A list of keys for tags to remove from the resource. (required)
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
    path: "/tags"
    query: [{name: resourceArn, var: resource_arn, required: true}, {name: tagKeys, var: tag_keys, style: multi, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, tag_keys: $tag_keys, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a gateway capability configuration or defines a new capability configuration. Each gateway capability defines data sources for a gateway. A capability configuration can contain multiple data source configurations. If you define OPC-UA sources for a gateway in the IoT SiteWise console, all of your OPC-UA sources are stored in one capability configuration. To list all capability configurations for a gateway, use DescribeGateway (https://docs.aws.amazon.com/iot-sitewise/latest/APIReference/API_DescribeGateway.html).
#
# POST /20200301/gateways/{gatewayId}/capability
# Returns: record<capabilityNamespace: string, capabilitySyncStatus: string>
# operationId: UpdateGatewayCapabilityConfiguration
export def "update-gateway-capability-configuration" [
  gateway_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  capability_namespace: string # The namespace of the gateway capability configuration to be updated. For example, if you configure OPC-UA sources from the IoT SiteWise console, your OPC-UA capability configuration has the namespace iotsitewise:opcuacollector:version, where version is a number such as 1.
  capability_configuration: string # The JSON document that defines the configuration for the gateway capability. For more information, see Configuring data sources (CLI) (https://docs.aws.amazon.com/iot-sitewise/latest/userguide/configure-sources.html#configure-source-cli) in the IoT SiteWise User Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/20200301/gateways/{gatewayId}/capability"
    path_params: [{name: gatewayId, var: gateway_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: capabilityNamespace, var: capability_namespace}, {name: capabilityConfiguration, var: capability_configuration}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    gateway_id: $gateway_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, capability_namespace: $capability_namespace, capability_configuration: $capability_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
