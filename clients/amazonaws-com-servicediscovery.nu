# Auto-generated client for AWS Cloud Map v2017-03-14
# Source: https://api.apis.guru/v2/specs/amazonaws.com/servicediscovery/2017-03-14/openapi.json
# Auth: --token flag or $env.AWS_CLOUD_MAP_TOKEN

const CLIENT = {
  base_url: "http://servicediscovery.us-east-1.amazonaws.com"
  token_env_var: "AWS_CLOUD_MAP_TOKEN"
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

def base-url-completer [] { ["http://servicediscovery.us-east-1.amazonaws.com" "http://servicediscovery.us-east-2.amazonaws.com" "http://servicediscovery.us-west-1.amazonaws.com" "http://servicediscovery.us-west-2.amazonaws.com" "http://servicediscovery.us-gov-west-1.amazonaws.com" "http://servicediscovery.us-gov-east-1.amazonaws.com" "http://servicediscovery.ca-central-1.amazonaws.com" "http://servicediscovery.eu-north-1.amazonaws.com" "http://servicediscovery.eu-west-1.amazonaws.com" "http://servicediscovery.eu-west-2.amazonaws.com" "http://servicediscovery.eu-west-3.amazonaws.com" "http://servicediscovery.eu-central-1.amazonaws.com" "http://servicediscovery.eu-south-1.amazonaws.com" "http://servicediscovery.af-south-1.amazonaws.com" "http://servicediscovery.ap-northeast-1.amazonaws.com" "http://servicediscovery.ap-northeast-2.amazonaws.com" "http://servicediscovery.ap-northeast-3.amazonaws.com" "http://servicediscovery.ap-southeast-1.amazonaws.com" "http://servicediscovery.ap-southeast-2.amazonaws.com" "http://servicediscovery.ap-east-1.amazonaws.com" "http://servicediscovery.ap-south-1.amazonaws.com" "http://servicediscovery.sa-east-1.amazonaws.com" "http://servicediscovery.me-south-1.amazonaws.com" "https://servicediscovery.us-east-1.amazonaws.com" "https://servicediscovery.us-east-2.amazonaws.com" "https://servicediscovery.us-west-1.amazonaws.com" "https://servicediscovery.us-west-2.amazonaws.com" "https://servicediscovery.us-gov-west-1.amazonaws.com" "https://servicediscovery.us-gov-east-1.amazonaws.com" "https://servicediscovery.ca-central-1.amazonaws.com" "https://servicediscovery.eu-north-1.amazonaws.com" "https://servicediscovery.eu-west-1.amazonaws.com" "https://servicediscovery.eu-west-2.amazonaws.com" "https://servicediscovery.eu-west-3.amazonaws.com" "https://servicediscovery.eu-central-1.amazonaws.com" "https://servicediscovery.eu-south-1.amazonaws.com" "https://servicediscovery.af-south-1.amazonaws.com" "https://servicediscovery.ap-northeast-1.amazonaws.com" "https://servicediscovery.ap-northeast-2.amazonaws.com" "https://servicediscovery.ap-northeast-3.amazonaws.com" "https://servicediscovery.ap-southeast-1.amazonaws.com" "https://servicediscovery.ap-southeast-2.amazonaws.com" "https://servicediscovery.ap-east-1.amazonaws.com" "https://servicediscovery.ap-south-1.amazonaws.com" "https://servicediscovery.sa-east-1.amazonaws.com" "https://servicediscovery.me-south-1.amazonaws.com" "http://servicediscovery.cn-north-1.amazonaws.com.cn" "http://servicediscovery.cn-northwest-1.amazonaws.com.cn" "https://servicediscovery.cn-north-1.amazonaws.com.cn" "https://servicediscovery.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["Route53AutoNaming_v20170314.CreateHttpNamespace"] }
def x-amz-target-completer-1 [] { ["Route53AutoNaming_v20170314.CreatePrivateDnsNamespace"] }
def x-amz-target-completer-2 [] { ["Route53AutoNaming_v20170314.CreatePublicDnsNamespace"] }
def type-completer [] { ["HTTP"] }
def x-amz-target-completer-3 [] { ["Route53AutoNaming_v20170314.CreateService"] }
def x-amz-target-completer-4 [] { ["Route53AutoNaming_v20170314.DeleteNamespace"] }
def x-amz-target-completer-5 [] { ["Route53AutoNaming_v20170314.DeleteService"] }
def x-amz-target-completer-6 [] { ["Route53AutoNaming_v20170314.DeregisterInstance"] }
def health-status-completer [] { ["ALL" "HEALTHY" "HEALTHY_OR_ELSE_ALL" "UNHEALTHY"] }
def x-amz-target-completer-7 [] { ["Route53AutoNaming_v20170314.DiscoverInstances"] }
def x-amz-target-completer-8 [] { ["Route53AutoNaming_v20170314.GetInstance"] }
def x-amz-target-completer-9 [] { ["Route53AutoNaming_v20170314.GetInstancesHealthStatus"] }
def x-amz-target-completer-10 [] { ["Route53AutoNaming_v20170314.GetNamespace"] }
def x-amz-target-completer-11 [] { ["Route53AutoNaming_v20170314.GetOperation"] }
def x-amz-target-completer-12 [] { ["Route53AutoNaming_v20170314.GetService"] }
def x-amz-target-completer-13 [] { ["Route53AutoNaming_v20170314.ListInstances"] }
def x-amz-target-completer-14 [] { ["Route53AutoNaming_v20170314.ListNamespaces"] }
def x-amz-target-completer-15 [] { ["Route53AutoNaming_v20170314.ListOperations"] }
def x-amz-target-completer-16 [] { ["Route53AutoNaming_v20170314.ListServices"] }
def x-amz-target-completer-17 [] { ["Route53AutoNaming_v20170314.ListTagsForResource"] }
def x-amz-target-completer-18 [] { ["Route53AutoNaming_v20170314.RegisterInstance"] }
def x-amz-target-completer-19 [] { ["Route53AutoNaming_v20170314.TagResource"] }
def x-amz-target-completer-20 [] { ["Route53AutoNaming_v20170314.UntagResource"] }
def x-amz-target-completer-21 [] { ["Route53AutoNaming_v20170314.UpdateHttpNamespace"] }
def status-completer [] { ["HEALTHY" "UNHEALTHY"] }
def x-amz-target-completer-22 [] { ["Route53AutoNaming_v20170314.UpdateInstanceCustomHealthStatus"] }
def x-amz-target-completer-23 [] { ["Route53AutoNaming_v20170314.UpdatePrivateDnsNamespace"] }
def x-amz-target-completer-24 [] { ["Route53AutoNaming_v20170314.UpdatePublicDnsNamespace"] }
def x-amz-target-completer-25 [] { ["Route53AutoNaming_v20170314.UpdateService"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-http-namespace: "record<OperationId: string>"
    create-private-dns-namespace: "record<OperationId: string>"
    create-public-dns-namespace: "record<OperationId: string>"
    create-service: "record<Service: record<Id: string, Arn: string, Name: string, NamespaceId: string, Description: string, InstanceCount: int, DnsConfig: record<NamespaceId: string, RoutingPolicy: string, DnsRecords: list>, Type: string, HealthCheckConfig: record<Type: string, ResourcePath: string, FailureThreshold: int>, HealthCheckCustomConfig: record<FailureThreshold: int>, CreateDate: string, CreatorRequestId: string>>"
    delete-namespace: "record<OperationId: string>"
    delete-service: "record"
    deregister-instance: "record<OperationId: string>"
    discover-instances: "record<Instances: table<InstanceId: string, NamespaceName: string, ServiceName: string, HealthStatus: string, Attributes: record>>"
    get-instance: "record<Instance: record<Id: string, CreatorRequestId: string, Attributes: record>>"
    get-instances-health-status: "record<Status: record, NextToken: string>"
    get-namespace: "record<Namespace: record<Id: string, Arn: string, Name: string, Type: string, Description: string, ServiceCount: int, Properties: record<DnsProperties: record, HttpProperties: record>, CreateDate: string, CreatorRequestId: string>>"
    get-operation: "record<Operation: record<Id: string, Type: string, Status: string, ErrorMessage: string, ErrorCode: string, CreateDate: string, UpdateDate: string, Targets: record>>"
    get-service: "record<Service: record<Id: string, Arn: string, Name: string, NamespaceId: string, Description: string, InstanceCount: int, DnsConfig: record<NamespaceId: string, RoutingPolicy: string, DnsRecords: list>, Type: string, HealthCheckConfig: record<Type: string, ResourcePath: string, FailureThreshold: int>, HealthCheckCustomConfig: record<FailureThreshold: int>, CreateDate: string, CreatorRequestId: string>>"
    list-instances: "record<Instances: table<Id: string, Attributes: record>, NextToken: string>"
    list-namespaces: "record<Namespaces: table<Id: string, Arn: string, Name: string, Type: string, Description: string, ServiceCount: int, Properties: record, CreateDate: string>, NextToken: string>"
    list-operations: "record<Operations: table<Id: string, Status: string>, NextToken: string>"
    list-services: "record<Services: table<Id: string, Arn: string, Name: string, Type: string, Description: string, InstanceCount: int, DnsConfig: record, HealthCheckConfig: record, HealthCheckCustomConfig: record, CreateDate: string>, NextToken: string>"
    list-tags-for-resource: "record<Tags: table<Key: string, Value: string>>"
    register-instance: "record<OperationId: string>"
    tag-resource: "record"
    untag-resource: "record"
    update-http-namespace: "record<OperationId: string>"
    update-private-dns-namespace: "record<OperationId: string>"
    update-public-dns-namespace: "record<OperationId: string>"
    update-service: "record<OperationId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-http-namespace" "create-private-dns-namespace" "create-public-dns-namespace" "create-service" "delete-namespace" "delete-service" "deregister-instance" "discover-instances" "get-instance" "get-instances-health-status" "get-namespace" "get-operation" "get-service" "list-instances" "list-namespaces" "list-operations" "list-services" "list-tags-for-resource" "register-instance" "tag-resource" "untag-resource" "update-http-namespace" "update-instance-custom-health-status" "update-private-dns-namespace" "update-public-dns-namespace" "update-service" "commands"] | sort) } | get name | first)
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

# Creates an HTTP namespace. Service instances registered using an HTTP namespace can be discovered using a DiscoverInstances request but can't be discovered using DNS. For the current quota on the number of namespaces that you can create using the same Amazon Web Services account, see Cloud Map quotas (https://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html) in the Cloud Map Developer Guide.
#
# POST /
# Returns: record<OperationId: string>
# operationId: CreateHttpNamespace
export def "create-http-namespace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name that you want to assign to this namespace.
  --creator-request-id: string # A unique string that identifies the request and that allows failed CreateHttpNamespace requests to be retried without the risk of running the operation twice. CreatorRequestId can be any unique string (for example, a date/time stamp).
  --description: string # A description for the namespace.
  --tags: list # The tags to add to the namespace. Each tag consists of a key and an optional value that you define. Tags keys can be up to 128 characters in length, and tag values can be up to 256 characters in length. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.CreateHttpNamespace"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: CreatorRequestId, var: creator_request_id}, {name: Description, var: description}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, creator_request_id: $creator_request_id, description: $description, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a private namespace based on DNS, which is visible only inside a specified Amazon VPC. The namespace defines your service naming scheme. For example, if you name your namespace example.com and name your service backend, the resulting DNS name for the service is backend.example.com. Service instances that are registered using a private DNS namespace can be discovered using either a DiscoverInstances request or using DNS. For the current quota on the number of namespaces that you can create using the same Amazon Web Services account, see Cloud Map quotas (https://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html) in the Cloud Map Developer Guide.
#
# POST /
# Returns: record<OperationId: string>
# operationId: CreatePrivateDnsNamespace
export def "create-private-dns-namespace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name that you want to assign to this namespace. When you create a private DNS namespace, Cloud Map automatically creates an Amazon Route 53 private hosted zone that has the same name as the namespace.
  --creator-request-id: string # A unique string that identifies the request and that allows failed CreatePrivateDnsNamespace requests to be retried without the risk of running the operation twice. CreatorRequestId can be any unique string (for example, a date/timestamp).
  --description: string # A description for the namespace.
  vpc: string # The ID of the Amazon VPC that you want to associate the namespace with.
  --tags: list # The tags to add to the namespace. Each tag consists of a key and an optional value that you define. Tags keys can be up to 128 characters in length, and tag values can be up to 256 characters in length. — item shape: {Key: string, Value: string}
  --properties: record # DNS properties for the private DNS namespace. — shape: {DnsProperties: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.CreatePrivateDnsNamespace"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: CreatorRequestId, var: creator_request_id}, {name: Description, var: description}, {name: Vpc, var: vpc}, {name: Tags, var: tags}, {name: Properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, creator_request_id: $creator_request_id, description: $description, vpc: $vpc, tags: $tags, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a public namespace based on DNS, which is visible on the internet. The namespace defines your service naming scheme. For example, if you name your namespace example.com and name your service backend, the resulting DNS name for the service is backend.example.com. You can discover instances that were registered with a public DNS namespace by using either a DiscoverInstances request or using DNS. For the current quota on the number of namespaces that you can create using the same Amazon Web Services account, see Cloud Map quotas (https://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html) in the Cloud Map Developer Guide. The CreatePublicDnsNamespace API operation is not supported in the Amazon Web Services GovCloud (US) Regions.
#
# POST /
# Returns: record<OperationId: string>
# operationId: CreatePublicDnsNamespace
export def "create-public-dns-namespace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name that you want to assign to this namespace. Do not include sensitive information in the name. The name is publicly available using DNS queries.
  --creator-request-id: string # A unique string that identifies the request and that allows failed CreatePublicDnsNamespace requests to be retried without the risk of running the operation twice. CreatorRequestId can be any unique string (for example, a date/timestamp).
  --description: string # A description for the namespace.
  --tags: list # The tags to add to the namespace. Each tag consists of a key and an optional value that you define. Tags keys can be up to 128 characters in length, and tag values can be up to 256 characters in length. — item shape: {Key: string, Value: string}
  --properties: record # DNS properties for the public DNS namespace. — shape: {DnsProperties: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.CreatePublicDnsNamespace"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: CreatorRequestId, var: creator_request_id}, {name: Description, var: description}, {name: Tags, var: tags}, {name: Properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, creator_request_id: $creator_request_id, description: $description, tags: $tags, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a service. This action defines the configuration for the following entities: For public and private DNS namespaces, one of the following combinations of DNS records in Amazon Route 53: A AAAA A and AAAA SRV CNAME Optionally, a health check After you create the service, you can submit a RegisterInstance (https://docs.aws.amazon.com/cloud-map/latest/api/API_RegisterInstance.html) request, and Cloud Map uses the values in the configuration to create the specified entities. For the current quota on the number of instances that you can register using the same namespace and using the same service, see Cloud Map quotas (https://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html) in the Cloud Map Developer Guide.
#
# POST /
# Returns: record<Service: record<Id: string, Arn: string, Name: string, NamespaceId: string, Description: string, InstanceCount: int, DnsConfig: record<NamespaceId: string, RoutingPolicy: string, DnsRecords: list>, Type: string, HealthCheckConfig: record<Type: string, ResourcePath: string, FailureThreshold: int>, HealthCheckCustomConfig: record<FailureThreshold: int>, CreateDate: string, CreatorRequestId: string>>
# operationId: CreateService
export def "create-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name that you want to assign to the service. Do not include sensitive information in the name if the namespace is discoverable by public DNS queries. If you want Cloud Map to create an SRV record when you register an instance and you're using a system that requires a specific SRV format, such as HAProxy (http://www.haproxy.org/), specify the following for Name: Start the name with an underscore (_), such as _exampleservice. End the name with ._protocol, such as ._tcp. When you register an instance, Cloud Map creates an SRV record and assigns a name to the record by concatenating the service name and the namespace name (for example, _exampleservice._tcp.example.com). For services that are accessible by DNS queries, you can't create multiple services with names that differ only by case (such as EXAMPLE and example). Otherwise, these services have the same DNS name and can't be distinguished. However, if you use a namespace that's only accessible by API calls, then you can create services that with names that differ only by case.
  --namespace-id: string # The ID of the namespace that you want to use to create the service. The namespace ID must be specified, but it can be specified either here or in the DnsConfig object.
  --creator-request-id: string # A unique string that identifies the request and that allows failed CreateService requests to be retried without the risk of running the operation twice. CreatorRequestId can be any unique string (for example, a date/timestamp).
  --description: string # A description for the service.
  --dns-config: record # A complex type that contains information about the Amazon Route 53 DNS records that you want Cloud Map to create when you register an instance. The record types of a service can only be changed by deleting the service and recreating it with a new Dnsconfig. — shape: {NamespaceId?: string, RoutingPolicy?: "MULTIVALUE"|"WEIGHTED", DnsRecords: list}
  --health-check-config: record # Public DNS and HTTP namespaces only. A complex type that contains settings for an optional health check. If you specify settings for a health check, Cloud Map associates the health check with the records that you specify in DnsConfig. If you specify a health check configuration, you can specify either HealthCheckCustomConfig or HealthCheckConfig but not both. Health checks are basic Route 53 health checks that monitor an Amazon Web Services endpoint. For information about pricing for health checks, see Amazon Route 53 Pricing (http://aws.amazon.com/route53/pricing/). Note the following about configuring health checks. A and AAAA records If DnsConfig includes configurations for both A and AAAA records, Cloud Map creates a health check that uses the IPv4 address to check the health of the resource. If the endpoint tthat's specified by the IPv4 address is unhealthy, Route 53 considers both the A and AAAA records to be unhealthy. CNAME records You can't specify settings for HealthCheckConfig when the DNSConfig includes CNAME for the value of Type. If you do, the CreateService request will fail with an InvalidInput error. Request interval A Route 53 health checker in each health-checking Amazon Web Services Region sends a health check request to an endpoint every 30 seconds. On average, your endpoint receives a health check request about every two seconds. However, health checkers don't coordinate with one another. Therefore, you might sometimes see several requests in one second that's followed by a few seconds with no health checks at all. Health checking regions Health checkers perform checks from all Route 53 health-checking Regions. For a list of the current Regions, see Regions (https://docs.aws.amazon.com/Route53/latest/APIReference/API_HealthCheckConfig.html#Route53-Type-HealthCheckConfig-Regions). Alias records When you register an instance, if you include the AWS_ALIAS_DNS_NAME attribute, Cloud Map creates a Route 53 alias record. Note the following: Route 53 automatically sets EvaluateTargetHealth to true for alias records. When EvaluateTargetHealth is true, the alias record inherits the health of the referenced Amazon Web Services resource. such as an ELB load balancer. For more information, see EvaluateTargetHealth (https://docs.aws.amazon.com/Route53/latest/APIReference/API_AliasTarget.html#Route53-Type-AliasTarget-EvaluateTargetHealth). If you include HealthCheckConfig and then use the service to register an instance that creates an alias record, Route 53 doesn't create the health check. Charges for health checks Health checks are basic Route 53 health checks that monitor an Amazon Web Services endpoint. For information about pricing for health checks, see Amazon Route 53 Pricing (http://aws.amazon.com/route53/pricing/). — shape: {Type: "HTTP"|"HTTPS"|"TCP", ResourcePath?: string, FailureThreshold?: int}
  --health-check-custom-config: record # A complex type that contains information about an optional custom health check. A custom health check, which requires that you use a third-party health checker to evaluate the health of your resources, is useful in the following circumstances: You can't use a health check that's defined by HealthCheckConfig because the resource isn't available over the internet. For example, you can use a custom health check when the instance is in an Amazon VPC. (To check the health of resources in a VPC, the health checker must also be in the VPC.) You want to use a third-party health checker regardless of where your resources are located. If you specify a health check configuration, you can specify either HealthCheckCustomConfig or HealthCheckConfig but not both. To change the status of a custom health check, submit an UpdateInstanceCustomHealthStatus request. Cloud Map doesn't monitor the status of the resource, it just keeps a record of the status specified in the most recent UpdateInstanceCustomHealthStatus request. Here's how custom health checks work: You create a service. You register an instance. You configure a third-party health checker to monitor the resource that's associated with the new instance. Cloud Map doesn't check the health of the resource directly. The third-party health-checker determines that the resource is unhealthy and notifies your application. Your application submits an UpdateInstanceCustomHealthStatus request. Cloud Map waits for 30 seconds. If another UpdateInstanceCustomHealthStatus request doesn't arrive during that time to change the status back to healthy, Cloud Map stops routing traffic to the resource. — shape: {FailureThreshold?: int}
  --tags: list # The tags to add to the service. Each tag consists of a key and an optional value that you define. Tags keys can be up to 128 characters in length, and tag values can be up to 256 characters in length. — item shape: {Key: string, Value: string}
  --type: string@type-completer # If present, specifies that the service instances are only discoverable using the DiscoverInstances API operation. No DNS records is registered for the service instances. The only valid value is HTTP.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.CreateService"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: NamespaceId, var: namespace_id}, {name: CreatorRequestId, var: creator_request_id}, {name: Description, var: description}, {name: DnsConfig, var: dns_config}, {name: HealthCheckConfig, var: health_check_config}, {name: HealthCheckCustomConfig, var: health_check_custom_config}, {name: Tags, var: tags}, {name: Type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, namespace_id: $namespace_id, creator_request_id: $creator_request_id, description: $description, dns_config: $dns_config, health_check_config: $health_check_config, health_check_custom_config: $health_check_custom_config, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a namespace from the current account. If the namespace still contains one or more services, the request fails.
#
# POST /
# Returns: record<OperationId: string>
# operationId: DeleteNamespace
export def "delete-namespace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The ID of the namespace that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.DeleteNamespace"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specified service. If the service still contains one or more registered instances, the request fails.
#
# POST /
# Returns: record
# operationId: DeleteService
export def "delete-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The ID of the service that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.DeleteService"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the Amazon Route 53 DNS records and health check, if any, that Cloud Map created for the specified instance.
#
# POST /
# Returns: record<OperationId: string>
# operationId: DeregisterInstance
export def "deregister-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  service_id: string # The ID of the service that the instance is associated with.
  instance_id: string # The value that you specified for Id in the RegisterInstance (https://docs.aws.amazon.com/cloud-map/latest/api/API_RegisterInstance.html) request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.DeregisterInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceId, var: service_id}, {name: InstanceId, var: instance_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_id: $service_id, instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Discovers registered instances for a specified namespace and service. You can use DiscoverInstances to discover instances for any type of namespace. For public and private DNS namespaces, you can also use DNS queries to discover instances.
#
# POST /
# Returns: record<Instances: table<InstanceId: string, NamespaceName: string, ServiceName: string, HealthStatus: string, Attributes: record>>
# operationId: DiscoverInstances
export def "discover-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  namespace_name: string # The HttpName name of the namespace. It's found in the HttpProperties member of the Properties member of the namespace.
  service_name: string # The name of the service that you specified when you registered the instance.
  --max-results: int # The maximum number of instances that you want Cloud Map to return in the response to a DiscoverInstances request. If you don't specify a value for MaxResults, Cloud Map returns up to 100 instances.
  --query-parameters: record # Filters to scope the results based on custom attributes for the instance (for example, {version=v1, az=1a}). Only instances that match all the specified key-value pairs are returned.
  --optional-parameters: record # Opportunistic filters to scope the results based on custom attributes. If there are instances that match both the filters specified in both the QueryParameters parameter and this parameter, all of these instances are returned. Otherwise, the filters are ignored, and only instances that match the filters that are specified in the QueryParameters parameter are returned.
  --health-status: string@health-status-completer # The health status of the instances that you want to discover. This parameter is ignored for services that don't have a health check configured, and all instances are returned. HEALTHY Returns healthy instances. UNHEALTHY Returns unhealthy instances. ALL Returns all instances. HEALTHY_OR_ELSE_ALL Returns healthy instances, unless none are reporting a healthy state. In that case, return all instances. This is also called failing open.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.DiscoverInstances"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NamespaceName, var: namespace_name}, {name: ServiceName, var: service_name}, {name: MaxResults, var: max_results}, {name: QueryParameters, var: query_parameters}, {name: OptionalParameters, var: optional_parameters}, {name: HealthStatus, var: health_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, namespace_name: $namespace_name, service_name: $service_name, max_results: $max_results, query_parameters: $query_parameters, optional_parameters: $optional_parameters, health_status: $health_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a specified instance.
#
# POST /
# Returns: record<Instance: record<Id: string, CreatorRequestId: string, Attributes: record>>
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
  --x-amz-target: string@x-amz-target-completer-8 # required
  service_id: string # The ID of the service that the instance is associated with.
  instance_id: string # The ID of the instance that you want to get information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.GetInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceId, var: service_id}, {name: InstanceId, var: instance_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_id: $service_id, instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the current health status (Healthy, Unhealthy, or Unknown) of one or more instances that are associated with a specified service. There's a brief delay between when you register an instance and when the health status for the instance is available.
#
# POST /
# Returns: record<Status: record, NextToken: string>
# operationId: GetInstancesHealthStatus
export def "get-instances-health-status" [
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
  --x-amz-target: string@x-amz-target-completer-9 # required
  service_id: string # The ID of the service that the instance is associated with.
  --instances: list<string> # An array that contains the IDs of all the instances that you want to get the health status for. If you omit Instances, Cloud Map returns the health status for all the instances that are associated with the specified service. To get the IDs for the instances that you've registered by using a specified service, submit a ListInstances (https://docs.aws.amazon.com/cloud-map/latest/api/API_ListInstances.html) request.
  --body-max-results: int # The maximum number of instances that you want Cloud Map to return in the response to a GetInstancesHealthStatus request. If you don't specify a value for MaxResults, Cloud Map returns up to 100 instances. (spec name: MaxResults)
  --body-next-token: string # For the first GetInstancesHealthStatus request, omit this value. If more than MaxResults instances match the specified criteria, you can submit another GetInstancesHealthStatus request to get the next group of results. Specify the value of NextToken from the previous response in the next request. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.GetInstancesHealthStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceId, var: service_id}, {name: Instances, var: instances}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_id: $service_id, instances: $instances, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a namespace.
#
# POST /
# Returns: record<Namespace: record<Id: string, Arn: string, Name: string, Type: string, Description: string, ServiceCount: int, Properties: record<DnsProperties: record, HttpProperties: record>, CreateDate: string, CreatorRequestId: string>>
# operationId: GetNamespace
export def "get-namespace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The ID of the namespace that you want to get information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.GetNamespace"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about any operation that returns an operation ID in the response, such as a CreateService request. To get a list of operations that match specified criteria, see ListOperations (https://docs.aws.amazon.com/cloud-map/latest/api/API_ListOperations.html).
#
# POST /
# Returns: record<Operation: record<Id: string, Type: string, Status: string, ErrorMessage: string, ErrorCode: string, CreateDate: string, UpdateDate: string, Targets: record>>
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
  --x-amz-target: string@x-amz-target-completer-11 # required
  operation_id: string # The ID of the operation that you want to get more information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.GetOperation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: OperationId, var: operation_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, operation_id: $operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the settings for a specified service.
#
# POST /
# Returns: record<Service: record<Id: string, Arn: string, Name: string, NamespaceId: string, Description: string, InstanceCount: int, DnsConfig: record<NamespaceId: string, RoutingPolicy: string, DnsRecords: list>, Type: string, HealthCheckConfig: record<Type: string, ResourcePath: string, FailureThreshold: int>, HealthCheckCustomConfig: record<FailureThreshold: int>, CreateDate: string, CreatorRequestId: string>>
# operationId: GetService
export def "get-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The ID of the service that you want to get settings for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.GetService"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists summary information about the instances that you registered by using a specified service.
#
# POST /
# Returns: record<Instances: table<Id: string, Attributes: record>, NextToken: string>
# operationId: ListInstances
export def "list-instances" [
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
  --x-amz-target: string@x-amz-target-completer-13 # required
  service_id: string # The ID of the service that you want to list instances for.
  --body-next-token: string # For the first ListInstances request, omit this value. If more than MaxResults instances match the specified criteria, you can submit another ListInstances request to get the next group of results. Specify the value of NextToken from the previous response in the next request. (spec name: NextToken)
  --body-max-results: int # The maximum number of instances that you want Cloud Map to return in the response to a ListInstances request. If you don't specify a value for MaxResults, Cloud Map returns up to 100 instances. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.ListInstances"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceId, var: service_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_id: $service_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists summary information about the namespaces that were created by the current Amazon Web Services account.
#
# POST /
# Returns: record<Namespaces: table<Id: string, Arn: string, Name: string, Type: string, Description: string, ServiceCount: int, Properties: record, CreateDate: string>, NextToken: string>
# operationId: ListNamespaces
export def "list-namespaces" [
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
  --x-amz-target: string@x-amz-target-completer-14 # required
  --body-next-token: string # For the first ListNamespaces request, omit this value. If the response contains NextToken, submit another ListNamespaces request to get the next group of results. Specify the value of NextToken from the previous response in the next request. Cloud Map gets MaxResults namespaces and then filters them based on the specified criteria. It's possible that no namespaces in the first MaxResults namespaces matched the specified criteria but that subsequent groups of MaxResults namespaces do contain namespaces that match the criteria. (spec name: NextToken)
  --body-max-results: int # The maximum number of namespaces that you want Cloud Map to return in the response to a ListNamespaces request. If you don't specify a value for MaxResults, Cloud Map returns up to 100 namespaces. (spec name: MaxResults)
  --filters: list # A complex type that contains specifications for the namespaces that you want to list. If you specify more than one filter, a namespace must match all filters to be returned by ListNamespaces. — item shape: {Name: "TYPE"|"NAME"|"HTTP_NAME", Values: list<string>, Condition?: "EQ"|"IN"|"BETWEEN"|"BEGINS_WITH"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.ListNamespaces"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists operations that match the criteria that you specify.
#
# POST /
# Returns: record<Operations: table<Id: string, Status: string>, NextToken: string>
# operationId: ListOperations
export def "list-operations" [
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  --body-next-token: string # For the first ListOperations request, omit this value. If the response contains NextToken, submit another ListOperations request to get the next group of results. Specify the value of NextToken from the previous response in the next request. Cloud Map gets MaxResults operations and then filters them based on the specified criteria. It's possible that no operations in the first MaxResults operations matched the specified criteria but that subsequent groups of MaxResults operations do contain operations that match the criteria. (spec name: NextToken)
  --body-max-results: int # The maximum number of items that you want Cloud Map to return in the response to a ListOperations request. If you don't specify a value for MaxResults, Cloud Map returns up to 100 operations. (spec name: MaxResults)
  --filters: list # A complex type that contains specifications for the operations that you want to list, for example, operations that you started between a specified start date and end date. If you specify more than one filter, an operation must match all filters to be returned by ListOperations. — item shape: {Name: "NAMESPACE_ID"|"SERVICE_ID"|"STATUS"|"TYPE"|"UPDATE_DATE", Values: list<string>, Condition?: "EQ"|"IN"|"BETWEEN"|"BEGINS_WITH"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.ListOperations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists summary information for all the services that are associated with one or more specified namespaces.
#
# POST /
# Returns: record<Services: table<Id: string, Arn: string, Name: string, Type: string, Description: string, InstanceCount: int, DnsConfig: record, HealthCheckConfig: record, HealthCheckCustomConfig: record, CreateDate: string>, NextToken: string>
# operationId: ListServices
export def "list-services" [
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
  --body-next-token: string # For the first ListServices request, omit this value. If the response contains NextToken, submit another ListServices request to get the next group of results. Specify the value of NextToken from the previous response in the next request. Cloud Map gets MaxResults services and then filters them based on the specified criteria. It's possible that no services in the first MaxResults services matched the specified criteria but that subsequent groups of MaxResults services do contain services that match the criteria. (spec name: NextToken)
  --body-max-results: int # The maximum number of services that you want Cloud Map to return in the response to a ListServices request. If you don't specify a value for MaxResults, Cloud Map returns up to 100 services. (spec name: MaxResults)
  --filters: list # A complex type that contains specifications for the namespaces that you want to list services for. If you specify more than one filter, an operation must match all filters to be returned by ListServices. — item shape: {Name: "NAMESPACE_ID", Values: list<string>, Condition?: "EQ"|"IN"|"BETWEEN"|"BEGINS_WITH"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.ListServices"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists tags for the specified resource.
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource that you want to retrieve tags for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceARN, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates one or more records and, optionally, creates a health check based on the settings in a specified service. When you submit a RegisterInstance request, the following occurs: For each DNS record that you define in the service that's specified by ServiceId, a record is created or updated in the hosted zone that's associated with the corresponding namespace. If the service includes HealthCheckConfig, a health check is created based on the settings in the health check configuration. The health check, if any, is associated with each of the new or updated records. One RegisterInstance request must complete before you can submit another request and specify the same service ID and instance ID. For more information, see CreateService (https://docs.aws.amazon.com/cloud-map/latest/api/API_CreateService.html). When Cloud Map receives a DNS query for the specified DNS name, it returns the applicable value: If the health check is healthy: returns all the records If the health check is unhealthy: returns the applicable value for the last healthy instance If you didn't specify a health check configuration: returns all the records For the current quota on the number of instances that you can register using the same namespace and using the same service, see Cloud Map quotas (https://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html) in the Cloud Map Developer Guide.
#
# POST /
# Returns: record<OperationId: string>
# operationId: RegisterInstance
export def "register-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  service_id: string # The ID of the service that you want to use for settings for the instance.
  instance_id: string # An identifier that you want to associate with the instance. Note the following: If the service that's specified by ServiceId includes settings for an SRV record, the value of InstanceId is automatically included as part of the value for the SRV record. For more information, see DnsRecord > Type (https://docs.aws.amazon.com/cloud-map/latest/api/API_DnsRecord.html#cloudmap-Type-DnsRecord-Type). You can use this value to update an existing instance. To register a new instance, you must specify a value that's unique among instances that you register by using the same service. If you specify an existing InstanceId and ServiceId, Cloud Map updates the existing DNS records, if any. If there's also an existing health check, Cloud Map deletes the old health check and creates a new one. The health check isn't deleted immediately, so it will still appear for a while if you submit a ListHealthChecks request, for example. Do not include sensitive information in InstanceId if the namespace is discoverable by public DNS queries and any Type member of DnsRecord for the service contains SRV because the InstanceId is discoverable by public DNS queries.
  --creator-request-id: string # A unique string that identifies the request and that allows failed RegisterInstance requests to be retried without the risk of executing the operation twice. You must use a unique CreatorRequestId string every time you submit a RegisterInstance request if you're registering additional instances for the same namespace and service. CreatorRequestId can be any unique string (for example, a date/time stamp).
  attributes: record # A string map that contains the following information for the service that you specify in ServiceId: The attributes that apply to the records that are defined in the service. For each attribute, the applicable value. Do not include sensitive information in the attributes if the namespace is discoverable by public DNS queries. Supported attribute keys include the following: AWS_ALIAS_DNS_NAME If you want Cloud Map to create an Amazon Route 53 alias record that routes traffic to an Elastic Load Balancing load balancer, specify the DNS name that's associated with the load balancer. For information about how to get the DNS name, see "DNSName" in the topic AliasTarget (https://docs.aws.amazon.com/Route53/latest/APIReference/API_AliasTarget.html) in the Route 53 API Reference. Note the following: The configuration for the service that's specified by ServiceId must include settings for an A record, an AAAA record, or both. In the service that's specified by ServiceId, the value of RoutingPolicy must be WEIGHTED. If the service that's specified by ServiceId includes HealthCheckConfig settings, Cloud Map will create the Route 53 health check, but it doesn't associate the health check with the alias record. Auto naming currently doesn't support creating alias records that route traffic to Amazon Web Services resources other than Elastic Load Balancing load balancers. If you specify a value for AWS_ALIAS_DNS_NAME, don't specify values for any of the AWS_INSTANCE attributes. AWS_EC2_INSTANCE_ID HTTP namespaces only. The Amazon EC2 instance ID for the instance. If the AWS_EC2_INSTANCE_ID attribute is specified, then the only other attribute that can be specified is AWS_INIT_HEALTH_STATUS. When the AWS_EC2_INSTANCE_ID attribute is specified, then the AWS_INSTANCE_IPV4 attribute will be filled out with the primary private IPv4 address. AWS_INIT_HEALTH_STATUS If the service configuration includes HealthCheckCustomConfig, you can optionally use AWS_INIT_HEALTH_STATUS to specify the initial status of the custom health check, HEALTHY or UNHEALTHY. If you don't specify a value for AWS_INIT_HEALTH_STATUS, the initial status is HEALTHY. AWS_INSTANCE_CNAME If the service configuration includes a CNAME record, the domain name that you want Route 53 to return in response to DNS queries (for example, example.com). This value is required if the service specified by ServiceId includes settings for an CNAME record. AWS_INSTANCE_IPV4 If the service configuration includes an A record, the IPv4 address that you want Route 53 to return in response to DNS queries (for example, 192.0.2.44). This value is required if the service specified by ServiceId includes settings for an A record. If the service includes settings for an SRV record, you must specify a value for AWS_INSTANCE_IPV4, AWS_INSTANCE_IPV6, or both. AWS_INSTANCE_IPV6 If the service configuration includes an AAAA record, the IPv6 address that you want Route 53 to return in response to DNS queries (for example, 2001:0db8:85a3:0000:0000:abcd:0001:2345). This value is required if the service specified by ServiceId includes settings for an AAAA record. If the service includes settings for an SRV record, you must specify a value for AWS_INSTANCE_IPV4, AWS_INSTANCE_IPV6, or both. AWS_INSTANCE_PORT If the service includes an SRV record, the value that you want Route 53 to return for the port. If the service includes HealthCheckConfig, the port on the endpoint that you want Route 53 to send requests to. This value is required if you specified settings for an SRV record or a Route 53 health check when you created the service. Custom attributes You can add up to 30 custom attributes. For each key-value pair, the maximum length of the attribute name is 255 characters, and the maximum length of the attribute value is 1,024 characters. The total size of all provided attributes (sum of all keys and values) must not exceed 5,000 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.RegisterInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceId, var: service_id}, {name: InstanceId, var: instance_id}, {name: CreatorRequestId, var: creator_request_id}, {name: Attributes, var: attributes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_id: $service_id, instance_id: $instance_id, creator_request_id: $creator_request_id, attributes: $attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds one or more tags to the specified resource.
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource that you want to retrieve tags for.
  tags: list # The tags to add to the specified resource. Specifying the tag key is required. You can set the value of a tag to an empty string, but you can't set the value of a tag to null. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceARN, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes one or more tags from the specified resource.
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource that you want to retrieve tags for.
  tag_keys: list<string> # The tag keys to remove from the specified resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceARN, var: resource_arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an HTTP namespace.
#
# POST /
# Returns: record<OperationId: string>
# operationId: UpdateHttpNamespace
export def "update-http-namespace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The ID of the namespace that you want to update.
  --updater-request-id: string # A unique string that identifies the request and that allows failed UpdateHttpNamespace requests to be retried without the risk of running the operation twice. UpdaterRequestId can be any unique string (for example, a date/timestamp).
  namespace: record # Updated properties for the HTTP namespace. — shape: {Description: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.UpdateHttpNamespace"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: UpdaterRequestId, var: updater_request_id}, {name: Namespace, var: namespace}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, updater_request_id: $updater_request_id, namespace: $namespace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submits a request to change the health status of a custom health check to healthy or unhealthy. You can use UpdateInstanceCustomHealthStatus to change the status only for custom health checks, which you define using HealthCheckCustomConfig when you create a service. You can't use it to change the status for Route 53 health checks, which you define using HealthCheckConfig. For more information, see HealthCheckCustomConfig (https://docs.aws.amazon.com/cloud-map/latest/api/API_HealthCheckCustomConfig.html).
#
# POST /
# operationId: UpdateInstanceCustomHealthStatus
export def "update-instance-custom-health-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  service_id: string # The ID of the service that includes the configuration for the custom health check that you want to change the status for.
  instance_id: string # The ID of the instance that you want to change the health status for.
  status: string@status-completer # The new status of the instance, HEALTHY or UNHEALTHY.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.UpdateInstanceCustomHealthStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceId, var: service_id}, {name: InstanceId, var: instance_id}, {name: Status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_id: $service_id, instance_id: $instance_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a private DNS namespace.
#
# POST /
# Returns: record<OperationId: string>
# operationId: UpdatePrivateDnsNamespace
export def "update-private-dns-namespace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The ID of the namespace that you want to update.
  --updater-request-id: string # A unique string that identifies the request and that allows failed UpdatePrivateDnsNamespace requests to be retried without the risk of running the operation twice. UpdaterRequestId can be any unique string (for example, a date/timestamp).
  namespace: record # Updated properties for the private DNS namespace. — shape: {Description?: string, Properties?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.UpdatePrivateDnsNamespace"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: UpdaterRequestId, var: updater_request_id}, {name: Namespace, var: namespace}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, updater_request_id: $updater_request_id, namespace: $namespace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a public DNS namespace.
#
# POST /
# Returns: record<OperationId: string>
# operationId: UpdatePublicDnsNamespace
export def "update-public-dns-namespace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The ID of the namespace being updated.
  --updater-request-id: string # A unique string that identifies the request and that allows failed UpdatePublicDnsNamespace requests to be retried without the risk of running the operation twice. UpdaterRequestId can be any unique string (for example, a date/timestamp).
  namespace: record # Updated properties for the public DNS namespace. — shape: {Description?: string, Properties?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.UpdatePublicDnsNamespace"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: UpdaterRequestId, var: updater_request_id}, {name: Namespace, var: namespace}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, updater_request_id: $updater_request_id, namespace: $namespace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submits a request to perform the following operations: Update the TTL setting for existing DnsRecords configurations Add, update, or delete HealthCheckConfig for a specified service You can't add, update, or delete a HealthCheckCustomConfig configuration. For public and private DNS namespaces, note the following: If you omit any existing DnsRecords or HealthCheckConfig configurations from an UpdateService request, the configurations are deleted from the service. If you omit an existing HealthCheckCustomConfig configuration from an UpdateService request, the configuration isn't deleted from the service. When you update settings for a service, Cloud Map also updates the corresponding settings in all the records and health checks that were created by using the specified service.
#
# POST /
# Returns: record<OperationId: string>
# operationId: UpdateService
export def "update-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The ID of the service that you want to update.
  service: record # A complex type that contains changes to an existing service. — shape: {Description?: string, DnsConfig?: record, HealthCheckConfig?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53AutoNaming_v20170314.UpdateService"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: Service, var: service}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, service: $service
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
