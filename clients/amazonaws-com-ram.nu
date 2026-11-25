# Auto-generated client for AWS Resource Access Manager v2018-01-04
# Source: https://api.apis.guru/v2/specs/amazonaws.com/ram/2018-01-04/openapi.json
# Auth: --token flag or $env.AWS_RESOURCE_ACCESS_MANAGER_TOKEN

const CLIENT = {
  base_url: "http://ram.us-east-1.amazonaws.com"
  token_env_var: "AWS_RESOURCE_ACCESS_MANAGER_TOKEN"
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

def base-url-completer [] { ["http://ram.us-east-1.amazonaws.com" "http://ram.us-east-2.amazonaws.com" "http://ram.us-west-1.amazonaws.com" "http://ram.us-west-2.amazonaws.com" "http://ram.us-gov-west-1.amazonaws.com" "http://ram.us-gov-east-1.amazonaws.com" "http://ram.ca-central-1.amazonaws.com" "http://ram.eu-north-1.amazonaws.com" "http://ram.eu-west-1.amazonaws.com" "http://ram.eu-west-2.amazonaws.com" "http://ram.eu-west-3.amazonaws.com" "http://ram.eu-central-1.amazonaws.com" "http://ram.eu-south-1.amazonaws.com" "http://ram.af-south-1.amazonaws.com" "http://ram.ap-northeast-1.amazonaws.com" "http://ram.ap-northeast-2.amazonaws.com" "http://ram.ap-northeast-3.amazonaws.com" "http://ram.ap-southeast-1.amazonaws.com" "http://ram.ap-southeast-2.amazonaws.com" "http://ram.ap-east-1.amazonaws.com" "http://ram.ap-south-1.amazonaws.com" "http://ram.sa-east-1.amazonaws.com" "http://ram.me-south-1.amazonaws.com" "https://ram.us-east-1.amazonaws.com" "https://ram.us-east-2.amazonaws.com" "https://ram.us-west-1.amazonaws.com" "https://ram.us-west-2.amazonaws.com" "https://ram.us-gov-west-1.amazonaws.com" "https://ram.us-gov-east-1.amazonaws.com" "https://ram.ca-central-1.amazonaws.com" "https://ram.eu-north-1.amazonaws.com" "https://ram.eu-west-1.amazonaws.com" "https://ram.eu-west-2.amazonaws.com" "https://ram.eu-west-3.amazonaws.com" "https://ram.eu-central-1.amazonaws.com" "https://ram.eu-south-1.amazonaws.com" "https://ram.af-south-1.amazonaws.com" "https://ram.ap-northeast-1.amazonaws.com" "https://ram.ap-northeast-2.amazonaws.com" "https://ram.ap-northeast-3.amazonaws.com" "https://ram.ap-southeast-1.amazonaws.com" "https://ram.ap-southeast-2.amazonaws.com" "https://ram.ap-east-1.amazonaws.com" "https://ram.ap-south-1.amazonaws.com" "https://ram.sa-east-1.amazonaws.com" "https://ram.me-south-1.amazonaws.com" "http://ram.cn-north-1.amazonaws.com.cn" "http://ram.cn-northwest-1.amazonaws.com.cn" "https://ram.cn-north-1.amazonaws.com.cn" "https://ram.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def association-type-completer [] { ["PRINCIPAL" "RESOURCE"] }
def association-status-completer [] { ["ASSOCIATED" "ASSOCIATING" "DISASSOCIATED" "DISASSOCIATING" "FAILED"] }
def resource-share-status-completer [] { ["ACTIVE" "DELETED" "DELETING" "FAILED" "PENDING"] }
def resource-owner-completer [] { ["OTHER-ACCOUNTS" "SELF"] }
def resource-region-scope-completer [] { ["ALL" "GLOBAL" "REGIONAL"] }
def feature-set-completer [] { ["CREATED_FROM_POLICY" "PROMOTING_TO_STANDARD" "STANDARD"] }
def permission-type-completer [] { ["ALL" "AWS_MANAGED" "CUSTOMER_MANAGED"] }
def status-completer [] { ["COMPLETED" "FAILED" "IN_PROGRESS"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    accept-resource-share-invitation: "record<resourceShareInvitation: record<resourceShareInvitationArn: string, resourceShareName: string, resourceShareArn: string, senderAccountId: string, receiverAccountId: string, invitationTimestamp: string, status: string, resourceShareAssociations: list<record>, receiverArn: string>, clientToken: string>"
    associate-resource-share: "record<resourceShareAssociations: table<resourceShareArn: string, resourceShareName: string, associatedEntity: string, associationType: string, status: string, statusMessage: string, creationTime: string, lastUpdatedTime: string, external: bool>, clientToken: string>"
    associate-resource-share-permission: "record<returnValue: bool, clientToken: string>"
    create-permission: "record<permission: record<arn: string, version: string, defaultVersion: bool, name: string, resourceType: string, status: string, creationTime: string, lastUpdatedTime: string, isResourceTypeDefault: bool, permissionType: string, featureSet: string, tags: list<record>>, clientToken: string>"
    create-permission-version: "record<permission: record<arn: string, version: string, defaultVersion: bool, name: string, resourceType: string, permission: string, creationTime: string, lastUpdatedTime: string, isResourceTypeDefault: bool, permissionType: string, featureSet: string, status: string, tags: list<record>>, clientToken: string>"
    create-resource-share: "record<resourceShare: record<resourceShareArn: string, name: string, owningAccountId: string, allowExternalPrincipals: bool, status: string, statusMessage: string, tags: list<record>, creationTime: string, lastUpdatedTime: string, featureSet: string>, clientToken: string>"
    delete-permission: "record<returnValue: bool, clientToken: string, permissionStatus: string>"
    delete-permission-version: "record<returnValue: bool, clientToken: string, permissionStatus: string>"
    delete-resource-share: "record<returnValue: bool, clientToken: string>"
    disassociate-resource-share: "record<resourceShareAssociations: table<resourceShareArn: string, resourceShareName: string, associatedEntity: string, associationType: string, status: string, statusMessage: string, creationTime: string, lastUpdatedTime: string, external: bool>, clientToken: string>"
    disassociate-resource-share-permission: "record<returnValue: bool, clientToken: string>"
    enable-sharing-with-aws-organization: "record<returnValue: bool>"
    get-permission: "record<permission: record<arn: string, version: string, defaultVersion: bool, name: string, resourceType: string, permission: string, creationTime: string, lastUpdatedTime: string, isResourceTypeDefault: bool, permissionType: string, featureSet: string, status: string, tags: list<record>>>"
    get-resource-policies: "record<policies: list<string>, nextToken: string>"
    get-resource-share-associations: "record<resourceShareAssociations: table<resourceShareArn: string, resourceShareName: string, associatedEntity: string, associationType: string, status: string, statusMessage: string, creationTime: string, lastUpdatedTime: string, external: bool>, nextToken: string>"
    get-resource-share-invitations: "record<resourceShareInvitations: table<resourceShareInvitationArn: string, resourceShareName: string, resourceShareArn: string, senderAccountId: string, receiverAccountId: string, invitationTimestamp: string, status: string, resourceShareAssociations: list, receiverArn: string>, nextToken: string>"
    get-resource-shares: "record<resourceShares: table<resourceShareArn: string, name: string, owningAccountId: string, allowExternalPrincipals: bool, status: string, statusMessage: string, tags: list, creationTime: string, lastUpdatedTime: string, featureSet: string>, nextToken: string>"
    list-pending-invitation-resources: "record<resources: table<arn: string, type: string, resourceShareArn: string, resourceGroupArn: string, status: string, statusMessage: string, creationTime: string, lastUpdatedTime: string, resourceRegionScope: string>, nextToken: string>"
    list-permission-associations: "record<permissions: table<arn: string, permissionVersion: string, defaultVersion: bool, resourceType: string, status: string, featureSet: string, lastUpdatedTime: string, resourceShareArn: string>, nextToken: string>"
    list-permission-versions: "record<permissions: table<arn: string, version: string, defaultVersion: bool, name: string, resourceType: string, status: string, creationTime: string, lastUpdatedTime: string, isResourceTypeDefault: bool, permissionType: string, featureSet: string, tags: list>, nextToken: string>"
    list-permissions: "record<permissions: table<arn: string, version: string, defaultVersion: bool, name: string, resourceType: string, status: string, creationTime: string, lastUpdatedTime: string, isResourceTypeDefault: bool, permissionType: string, featureSet: string, tags: list>, nextToken: string>"
    list-principals: "record<principals: table<id: string, resourceShareArn: string, creationTime: string, lastUpdatedTime: string, external: bool>, nextToken: string>"
    list-replace-permission-associations-work: "record<replacePermissionAssociationsWorks: table<id: string, fromPermissionArn: string, fromPermissionVersion: string, toPermissionArn: string, toPermissionVersion: string, status: string, statusMessage: string, creationTime: string, lastUpdatedTime: string>, nextToken: string>"
    list-resource-share-permissions: "record<permissions: table<arn: string, version: string, defaultVersion: bool, name: string, resourceType: string, status: string, creationTime: string, lastUpdatedTime: string, isResourceTypeDefault: bool, permissionType: string, featureSet: string, tags: list>, nextToken: string>"
    list-resource-types: "record<resourceTypes: table<resourceType: string, serviceName: string, resourceRegionScope: string>, nextToken: string>"
    list-resources: "record<resources: table<arn: string, type: string, resourceShareArn: string, resourceGroupArn: string, status: string, statusMessage: string, creationTime: string, lastUpdatedTime: string, resourceRegionScope: string>, nextToken: string>"
    promote-permission-created-from-policy: "record<permission: record<arn: string, version: string, defaultVersion: bool, name: string, resourceType: string, status: string, creationTime: string, lastUpdatedTime: string, isResourceTypeDefault: bool, permissionType: string, featureSet: string, tags: list<record>>, clientToken: string>"
    promote-resource-share-created-from-policy: "record<returnValue: bool>"
    reject-resource-share-invitation: "record<resourceShareInvitation: record<resourceShareInvitationArn: string, resourceShareName: string, resourceShareArn: string, senderAccountId: string, receiverAccountId: string, invitationTimestamp: string, status: string, resourceShareAssociations: list<record>, receiverArn: string>, clientToken: string>"
    replace-permission-associations: "record<replacePermissionAssociationsWork: record<id: string, fromPermissionArn: string, fromPermissionVersion: string, toPermissionArn: string, toPermissionVersion: string, status: string, statusMessage: string, creationTime: string, lastUpdatedTime: string>, clientToken: string>"
    set-default-permission-version: "record<returnValue: bool, clientToken: string>"
    tag-resource: "record"
    untag-resource: "record"
    update-resource-share: "record<resourceShare: record<resourceShareArn: string, name: string, owningAccountId: string, allowExternalPrincipals: bool, status: string, statusMessage: string, tags: list<record>, creationTime: string, lastUpdatedTime: string, featureSet: string>, clientToken: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accept-resource-share-invitation" "associate-resource-share" "associate-resource-share-permission" "create-permission" "create-permission-version" "create-resource-share" "delete-permission" "delete-permission-version" "delete-resource-share" "disassociate-resource-share" "disassociate-resource-share-permission" "enable-sharing-with-aws-organization" "get-permission" "get-resource-policies" "get-resource-share-associations" "get-resource-share-invitations" "get-resource-shares" "list-pending-invitation-resources" "list-permission-associations" "list-permission-versions" "list-permissions" "list-principals" "list-replace-permission-associations-work" "list-resource-share-permissions" "list-resource-types" "list-resources" "promote-permission-created-from-policy" "promote-resource-share-created-from-policy" "reject-resource-share-invitation" "replace-permission-associations" "set-default-permission-version" "tag-resource" "untag-resource" "update-resource-share" "commands"] | sort) } | get name | first)
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

# Accepts an invitation to a resource share from another Amazon Web Services account. After you accept the invitation, the resources included in the resource share are available to interact with in the relevant Amazon Web Services Management Consoles and tools.
#
# POST /acceptresourceshareinvitation
# Returns: record<resourceShareInvitation: record<resourceShareInvitationArn: string, resourceShareName: string, resourceShareArn: string, senderAccountId: string, receiverAccountId: string, invitationTimestamp: string, status: string, resourceShareAssociations: list<record>, receiverArn: string>, clientToken: string>
# operationId: AcceptResourceShareInvitation
export def "accept-resource-share-invitation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  resource_share_invitation_arn: string # The Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the invitation that you want to accept.
  --client-token: string # Specifies a unique, case-sensitive identifier that you provide to ensure the idempotency of the request. This lets you safely retry the request without accidentally performing the same operation a second time. Passing the same value to a later call to an operation requires that you also pass the same value for all other parameters. We recommend that you use a UUID type of value. (https://wikipedia.org/wiki/Universally_unique_identifier). If you don't provide this value, then Amazon Web Services generates a random one for you. If you retry the operation with the same ClientToken, but with different parameters, the retry fails with an IdempotentParameterMismatch error.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/acceptresourceshareinvitation"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceShareInvitationArn, var: resource_share_invitation_arn}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_share_invitation_arn: $resource_share_invitation_arn, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds the specified list of principals and list of resources to a resource share. Principals that already have access to this resource share immediately receive access to the added resources. Newly added principals immediately receive access to the resources shared in this resource share.
#
# POST /associateresourceshare
# Returns: record<resourceShareAssociations: table<resourceShareArn: string, resourceShareName: string, associatedEntity: string, associationType: string, status: string, statusMessage: string, creationTime: string, lastUpdatedTime: string, external: bool>, clientToken: string>
# operationId: AssociateResourceShare
export def "associate-resource-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  resource_share_arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resource share that you want to add principals or resources to.
  --resource-arns: list<string> # Specifies a list of Amazon Resource Names (ARNs) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resources that you want to share. This can be null if you want to add only principals.
  --principals: list<string> # Specifies a list of principals to whom you want to the resource share. This can be null if you want to add only resources. What the principals can do with the resources in the share is determined by the RAM permissions that you associate with the resource share. See AssociateResourceSharePermission. You can include the following values: An Amazon Web Services account ID, for example: 123456789012 An Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of an organization in Organizations, for example: organizations::123456789012:organization/o-exampleorgid An ARN of an organizational unit (OU) in Organizations, for example: organizations::123456789012:ou/o-exampleorgid/ou-examplerootid-exampleouid123 An ARN of an IAM role, for example: iam::123456789012:role/rolename An ARN of an IAM user, for example: iam::123456789012user/username Not all resource types can be shared with IAM roles and users. For more information, see Sharing with IAM roles and users (https://docs.aws.amazon.com/ram/latest/userguide/permissions.html#permissions-rbp-supported-resource-types) in the Resource Access Manager User Guide.
  --client-token: string # Specifies a unique, case-sensitive identifier that you provide to ensure the idempotency of the request. This lets you safely retry the request without accidentally performing the same operation a second time. Passing the same value to a later call to an operation requires that you also pass the same value for all other parameters. We recommend that you use a UUID type of value. (https://wikipedia.org/wiki/Universally_unique_identifier). If you don't provide this value, then Amazon Web Services generates a random one for you. If you retry the operation with the same ClientToken, but with different parameters, the retry fails with an IdempotentParameterMismatch error.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/associateresourceshare"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceShareArn, var: resource_share_arn}, {name: resourceArns, var: resource_arns}, {name: principals, var: principals}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_share_arn: $resource_share_arn, resource_arns: $resource_arns, principals: $principals, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds or replaces the RAM permission for a resource type included in a resource share. You can have exactly one permission associated with each resource type in the resource share. You can add a new RAM permission only if there are currently no resources of that resource type currently in the resource share.
#
# POST /associateresourcesharepermission
# Returns: record<returnValue: bool, clientToken: string>
# operationId: AssociateResourceSharePermission
export def "associate-resource-share-permission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  resource_share_arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resource share to which you want to add or replace permissions.
  permission_arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the RAM permission to associate with the resource share. To find the ARN for a permission, use either the ListPermissions operation or go to the Permissions library (https://console.aws.amazon.com/ram/home#Permissions:) page in the RAM console and then choose the name of the permission. The ARN is displayed on the detail page.
  --replace: oneof<nothing, bool> # Specifies whether the specified permission should replace the existing permission associated with the resource share. Use true to replace the current permissions. Use false to add the permission to a resource share that currently doesn't have a permission. The default value is false. A resource share can have only one permission per resource type. If a resource share already has a permission for the specified resource type and you don't set replace to true then the operation returns an error. This helps prevent accidental overwriting of a permission.
  --client-token: string # Specifies a unique, case-sensitive identifier that you provide to ensure the idempotency of the request. This lets you safely retry the request without accidentally performing the same operation a second time. Passing the same value to a later call to an operation requires that you also pass the same value for all other parameters. We recommend that you use a UUID type of value. (https://wikipedia.org/wiki/Universally_unique_identifier). If you don't provide this value, then Amazon Web Services generates a random one for you. If you retry the operation with the same ClientToken, but with different parameters, the retry fails with an IdempotentParameterMismatch error.
  --permission-version: int # Specifies the version of the RAM permission to associate with the resource share. You can specify only the version that is currently set as the default version for the permission. If you also set the replace pararameter to true, then this operation updates an outdated version of the permission to the current default version. You don't need to specify this parameter because the default behavior is to use the version that is currently set as the default version for the permission. This parameter is supported for backwards compatibility.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/associateresourcesharepermission"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceShareArn, var: resource_share_arn}, {name: permissionArn, var: permission_arn}, {name: replace, var: replace}, {name: clientToken, var: client_token}, {name: permissionVersion, var: permission_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_share_arn: $resource_share_arn, permission_arn: $permission_arn, replace: $replace, client_token: $client_token, permission_version: $permission_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a customer managed permission for a specified resource type that you can attach to resource shares. It is created in the Amazon Web Services Region in which you call the operation.
#
# POST /createpermission
# Returns: record<permission: record<arn: string, version: string, defaultVersion: bool, name: string, resourceType: string, status: string, creationTime: string, lastUpdatedTime: string, isResourceTypeDefault: bool, permissionType: string, featureSet: string, tags: list<record>>, clientToken: string>
# operationId: CreatePermission
export def "create-permission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # Specifies the name of the customer managed permission. The name must be unique within the Amazon Web Services Region.
  resource_type: string # Specifies the name of the resource type that this customer managed permission applies to. The format is <service-code>:<resource-type> and is not case sensitive. For example, to specify an Amazon EC2 Subnet, you can use the string ec2:subnet. To see the list of valid values for this parameter, query the ListResourceTypes operation.
  policy_template: string # A string in JSON format string that contains the following elements of a resource-based policy: Effect: must be set to ALLOW. Action: specifies the actions that are allowed by this customer managed permission. The list must contain only actions that are supported by the specified resource type. For a list of all actions supported by each resource type, see Actions, resources, and condition keys for Amazon Web Services services (https://docs.aws.amazon.com/service-authorization/latest/reference/reference_policies_actions-resources-contextkeys.html) in the Identity and Access Management User Guide. Condition: (optional) specifies conditional parameters that must evaluate to true when a user attempts an action for that action to be allowed. For more information about the Condition element, see IAM policies: Condition element (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition.html) in the Identity and Access Management User Guide. This template can't include either the Resource or Principal elements. Those are both filled in by RAM when it instantiates the resource-based policy on each resource shared using this managed permission. The Resource comes from the ARN of the specific resource that you are sharing. The Principal comes from the list of identities added to the resource share.
  --client-token: string # Specifies a unique, case-sensitive identifier that you provide to ensure the idempotency of the request. This lets you safely retry the request without accidentally performing the same operation a second time. Passing the same value to a later call to an operation requires that you also pass the same value for all other parameters. We recommend that you use a UUID type of value. (https://wikipedia.org/wiki/Universally_unique_identifier). If you don't provide this value, then Amazon Web Services generates a random one for you. If you retry the operation with the same ClientToken, but with different parameters, the retry fails with an IdempotentParameterMismatch error.
  --tags: list # Specifies a list of one or more tag key and value pairs to attach to the permission. — item shape: {key?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/createpermission"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: resourceType, var: resource_type}, {name: policyTemplate, var: policy_template}, {name: clientToken, var: client_token}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, resource_type: $resource_type, policy_template: $policy_template, client_token: $client_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new version of the specified customer managed permission. The new version is automatically set as the default version of the customer managed permission. New resource shares automatically use the default permission. Existing resource shares continue to use their original permission versions, but you can use ReplacePermissionAssociations to update them. If the specified customer managed permission already has the maximum of 5 versions, then you must delete one of the existing versions before you can create a new one.
#
# POST /createpermissionversion
# Returns: record<permission: record<arn: string, version: string, defaultVersion: bool, name: string, resourceType: string, permission: string, creationTime: string, lastUpdatedTime: string, isResourceTypeDefault: bool, permissionType: string, featureSet: string, status: string, tags: list<record>>, clientToken: string>
# operationId: CreatePermissionVersion
export def "create-permission-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  permission_arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the customer managed permission you're creating a new version for.
  policy_template: string # A string in JSON format string that contains the following elements of a resource-based policy: Effect: must be set to ALLOW. Action: specifies the actions that are allowed by this customer managed permission. The list must contain only actions that are supported by the specified resource type. For a list of all actions supported by each resource type, see Actions, resources, and condition keys for Amazon Web Services services (https://docs.aws.amazon.com/service-authorization/latest/reference/reference_policies_actions-resources-contextkeys.html) in the Identity and Access Management User Guide. Condition: (optional) specifies conditional parameters that must evaluate to true when a user attempts an action for that action to be allowed. For more information about the Condition element, see IAM policies: Condition element (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition.html) in the Identity and Access Management User Guide. This template can't include either the Resource or Principal elements. Those are both filled in by RAM when it instantiates the resource-based policy on each resource shared using this managed permission. The Resource comes from the ARN of the specific resource that you are sharing. The Principal comes from the list of identities added to the resource share.
  --client-token: string # Specifies a unique, case-sensitive identifier that you provide to ensure the idempotency of the request. This lets you safely retry the request without accidentally performing the same operation a second time. Passing the same value to a later call to an operation requires that you also pass the same value for all other parameters. We recommend that you use a UUID type of value. (https://wikipedia.org/wiki/Universally_unique_identifier). If you don't provide this value, then Amazon Web Services generates a random one for you. If you retry the operation with the same ClientToken, but with different parameters, the retry fails with an IdempotentParameterMismatch error.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/createpermissionversion"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: permissionArn, var: permission_arn}, {name: policyTemplate, var: policy_template}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, permission_arn: $permission_arn, policy_template: $policy_template, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a resource share. You can provide a list of the Amazon Resource Names (ARNs) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) for the resources that you want to share, a list of principals you want to share the resources with, and the permissions to grant those principals. Sharing a resource makes it available for use by principals outside of the Amazon Web Services account that created the resource. Sharing doesn't change any permissions or quotas that apply to the resource in the account that created it.
#
# POST /createresourceshare
# Returns: record<resourceShare: record<resourceShareArn: string, name: string, owningAccountId: string, allowExternalPrincipals: bool, status: string, statusMessage: string, tags: list<record>, creationTime: string, lastUpdatedTime: string, featureSet: string>, clientToken: string>
# operationId: CreateResourceShare
export def "create-resource-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # Specifies the name of the resource share.
  --resource-arns: list<string> # Specifies a list of one or more ARNs of the resources to associate with the resource share.
  --principals: list<string> # Specifies a list of one or more principals to associate with the resource share. You can include the following values: An Amazon Web Services account ID, for example: 123456789012 An Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of an organization in Organizations, for example: organizations::123456789012:organization/o-exampleorgid An ARN of an organizational unit (OU) in Organizations, for example: organizations::123456789012:ou/o-exampleorgid/ou-examplerootid-exampleouid123 An ARN of an IAM role, for example: iam::123456789012:role/rolename An ARN of an IAM user, for example: iam::123456789012user/username Not all resource types can be shared with IAM roles and users. For more information, see Sharing with IAM roles and users (https://docs.aws.amazon.com/ram/latest/userguide/permissions.html#permissions-rbp-supported-resource-types) in the Resource Access Manager User Guide.
  --tags: list # Specifies one or more tags to attach to the resource share itself. It doesn't attach the tags to the resources associated with the resource share. — item shape: {key?: string, value?: string}
  --allow-external-principals: oneof<nothing, bool> # Specifies whether principals outside your organization in Organizations can be associated with a resource share. A value of true lets you share with individual Amazon Web Services accounts that are not in your organization. A value of false only has meaning if your account is a member of an Amazon Web Services Organization. The default value is true.
  --client-token: string # Specifies a unique, case-sensitive identifier that you provide to ensure the idempotency of the request. This lets you safely retry the request without accidentally performing the same operation a second time. Passing the same value to a later call to an operation requires that you also pass the same value for all other parameters. We recommend that you use a UUID type of value. (https://wikipedia.org/wiki/Universally_unique_identifier). If you don't provide this value, then Amazon Web Services generates a random one for you. If you retry the operation with the same ClientToken, but with different parameters, the retry fails with an IdempotentParameterMismatch error.
  --permission-arns: list<string> # Specifies the Amazon Resource Names (ARNs) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the RAM permission to associate with the resource share. If you do not specify an ARN for the permission, RAM automatically attaches the default version of the permission for each resource type. You can associate only one permission with each resource type included in the resource share.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/createresourceshare"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: resourceArns, var: resource_arns}, {name: principals, var: principals}, {name: tags, var: tags}, {name: allowExternalPrincipals, var: allow_external_principals}, {name: clientToken, var: client_token}, {name: permissionArns, var: permission_arns}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, resource_arns: $resource_arns, principals: $principals, tags: $tags, allow_external_principals: $allow_external_principals, client_token: $client_token, permission_arns: $permission_arns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified customer managed permission in the Amazon Web Services Region in which you call this operation. You can delete a customer managed permission only if it isn't attached to any resource share. The operation deletes all versions associated with the customer managed permission.
#
# DELETE /deletepermission
# Returns: record<returnValue: bool, clientToken: string, permissionStatus: string>
# operationId: DeletePermission
export def "delete-permission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --permission-arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the customer managed permission that you want to delete. (required)
  --client-token: string # Specifies a unique, case-sensitive identifier that you provide to ensure the idempotency of the request. This lets you safely retry the request without accidentally performing the same operation a second time. Passing the same value to a later call to an operation requires that you also pass the same value for all other parameters. We recommend that you use a UUID type of value. (https://wikipedia.org/wiki/Universally_unique_identifier). If you don't provide this value, then Amazon Web Services generates a random one for you. If you retry the operation with the same ClientToken, but with different parameters, the retry fails with an IdempotentParameterMismatch error.
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
    path: "/deletepermission"
    query: [{name: permissionArn, var: permission_arn, required: true}, {name: clientToken, var: client_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    permission_arn: $permission_arn, client_token: $client_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes one version of a customer managed permission. The version you specify must not be attached to any resource share and must not be the default version for the permission. If a customer managed permission has the maximum of 5 versions, then you must delete at least one version before you can create another.
#
# DELETE /deletepermissionversion
# Returns: record<returnValue: bool, clientToken: string, permissionStatus: string>
# operationId: DeletePermissionVersion
export def "delete-permission-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --permission-arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the permission with the version you want to delete. (required)
  --permission-version: int # Specifies the version number to delete. You can't delete the default version for a customer managed permission. You can't delete a version if it's the only version of the permission. You must either first create another version, or delete the permission completely. You can't delete a version if it is attached to any resource shares. If the version is the default, you must first use SetDefaultPermissionVersion to set a different version as the default for the customer managed permission, and then use AssociateResourceSharePermission to update your resource shares to use the new default version. (required)
  --client-token: string # Specifies a unique, case-sensitive identifier that you provide to ensure the idempotency of the request. This lets you safely retry the request without accidentally performing the same operation a second time. Passing the same value to a later call to an operation requires that you also pass the same value for all other parameters. We recommend that you use a UUID type of value. (https://wikipedia.org/wiki/Universally_unique_identifier). If you don't provide this value, then Amazon Web Services generates a random one for you. If you retry the operation with the same ClientToken, but with different parameters, the retry fails with an IdempotentParameterMismatch error.
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
    path: "/deletepermissionversion"
    query: [{name: permissionArn, var: permission_arn, required: true}, {name: permissionVersion, var: permission_version, required: true}, {name: clientToken, var: client_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    permission_arn: $permission_arn, permission_version: $permission_version, client_token: $client_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified resource share. This doesn't delete any of the resources that were associated with the resource share; it only stops the sharing of those resources through this resource share.
#
# DELETE /deleteresourceshare
# Returns: record<returnValue: bool, clientToken: string>
# operationId: DeleteResourceShare
export def "delete-resource-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-share-arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resource share to delete. (required)
  --client-token: string # Specifies a unique, case-sensitive identifier that you provide to ensure the idempotency of the request. This lets you safely retry the request without accidentally performing the same operation a second time. Passing the same value to a later call to an operation requires that you also pass the same value for all other parameters. We recommend that you use a UUID type of value. (https://wikipedia.org/wiki/Universally_unique_identifier). If you don't provide this value, then Amazon Web Services generates a random one for you. If you retry the operation with the same ClientToken, but with different parameters, the retry fails with an IdempotentParameterMismatch error.
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
    path: "/deleteresourceshare"
    query: [{name: resourceShareArn, var: resource_share_arn, required: true}, {name: clientToken, var: client_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_share_arn: $resource_share_arn, client_token: $client_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the specified principals or resources from participating in the specified resource share.
#
# POST /disassociateresourceshare
# Returns: record<resourceShareAssociations: table<resourceShareArn: string, resourceShareName: string, associatedEntity: string, associationType: string, status: string, statusMessage: string, creationTime: string, lastUpdatedTime: string, external: bool>, clientToken: string>
# operationId: DisassociateResourceShare
export def "disassociate-resource-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  resource_share_arn: string # Specifies Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resource share that you want to remove resources or principals from.
  --resource-arns: list<string> # Specifies a list of Amazon Resource Names (ARNs) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) for one or more resources that you want to remove from the resource share. After the operation runs, these resources are no longer shared with principals associated with the resource share.
  --principals: list<string> # Specifies a list of one or more principals that no longer are to have access to the resources in this resource share. You can include the following values: An Amazon Web Services account ID, for example: 123456789012 An Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of an organization in Organizations, for example: organizations::123456789012:organization/o-exampleorgid An ARN of an organizational unit (OU) in Organizations, for example: organizations::123456789012:ou/o-exampleorgid/ou-examplerootid-exampleouid123 An ARN of an IAM role, for example: iam::123456789012:role/rolename An ARN of an IAM user, for example: iam::123456789012user/username Not all resource types can be shared with IAM roles and users. For more information, see Sharing with IAM roles and users (https://docs.aws.amazon.com/ram/latest/userguide/permissions.html#permissions-rbp-supported-resource-types) in the Resource Access Manager User Guide.
  --client-token: string # Specifies a unique, case-sensitive identifier that you provide to ensure the idempotency of the request. This lets you safely retry the request without accidentally performing the same operation a second time. Passing the same value to a later call to an operation requires that you also pass the same value for all other parameters. We recommend that you use a UUID type of value. (https://wikipedia.org/wiki/Universally_unique_identifier). If you don't provide this value, then Amazon Web Services generates a random one for you. If you retry the operation with the same ClientToken, but with different parameters, the retry fails with an IdempotentParameterMismatch error.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/disassociateresourceshare"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceShareArn, var: resource_share_arn}, {name: resourceArns, var: resource_arns}, {name: principals, var: principals}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_share_arn: $resource_share_arn, resource_arns: $resource_arns, principals: $principals, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a managed permission from a resource share. Permission changes take effect immediately. You can remove a managed permission from a resource share only if there are currently no resources of the relevant resource type currently attached to the resource share.
#
# POST /disassociateresourcesharepermission
# Returns: record<returnValue: bool, clientToken: string>
# operationId: DisassociateResourceSharePermission
export def "disassociate-resource-share-permission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  resource_share_arn: string # The Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resource share that you want to remove the managed permission from.
  permission_arn: string # The Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the managed permission to disassociate from the resource share. Changes to permissions take effect immediately.
  --client-token: string # Specifies a unique, case-sensitive identifier that you provide to ensure the idempotency of the request. This lets you safely retry the request without accidentally performing the same operation a second time. Passing the same value to a later call to an operation requires that you also pass the same value for all other parameters. We recommend that you use a UUID type of value. (https://wikipedia.org/wiki/Universally_unique_identifier). If you don't provide this value, then Amazon Web Services generates a random one for you. If you retry the operation with the same ClientToken, but with different parameters, the retry fails with an IdempotentParameterMismatch error.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/disassociateresourcesharepermission"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceShareArn, var: resource_share_arn}, {name: permissionArn, var: permission_arn}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_share_arn: $resource_share_arn, permission_arn: $permission_arn, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables resource sharing within your organization in Organizations. This operation creates a service-linked role called AWSServiceRoleForResourceAccessManager that has the IAM managed policy named AWSResourceAccessManagerServiceRolePolicy attached. This role permits RAM to retrieve information about the organization and its structure. This lets you share resources with all of the accounts in the calling account's organization by specifying the organization ID, or all of the accounts in an organizational unit (OU) by specifying the OU ID. Until you enable sharing within the organization, you can specify only individual Amazon Web Services accounts, or for supported resource types, IAM roles and users. You must call this operation from an IAM role or user in the organization's management account.
#
# POST /enablesharingwithawsorganization
# Returns: record<returnValue: bool>
# operationId: EnableSharingWithAwsOrganization
export def "enable-sharing-with-aws-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    method: post
    path: "/enablesharingwithawsorganization"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the contents of a managed permission in JSON format.
#
# POST /getpermission
# Returns: record<permission: record<arn: string, version: string, defaultVersion: bool, name: string, resourceType: string, permission: string, creationTime: string, lastUpdatedTime: string, isResourceTypeDefault: bool, permissionType: string, featureSet: string, status: string, tags: list<record>>>
# operationId: GetPermission
export def "get-permission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  permission_arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the permission whose contents you want to retrieve. To find the ARN for a permission, use either the ListPermissions operation or go to the Permissions library (https://console.aws.amazon.com/ram/home#Permissions:) page in the RAM console and then choose the name of the permission. The ARN is displayed on the detail page.
  --permission-version: int # Specifies the version number of the RAM permission to retrieve. If you don't specify this parameter, the operation retrieves the default version. To see the list of available versions, use ListPermissionVersions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getpermission"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: permissionArn, var: permission_arn}, {name: permissionVersion, var: permission_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, permission_arn: $permission_arn, permission_version: $permission_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the resource policies for the specified resources that you own and have shared.
#
# POST /getresourcepolicies
# Returns: record<policies: list<string>, nextToken: string>
# operationId: GetResourcePolicies
export def "get-resource-policies" [
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
  resource_arns: list<string> # Specifies the Amazon Resource Names (ARNs) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resources whose policies you want to retrieve.
  --principal: string # Specifies the principal.
  --body-next-token: string # Specifies that you want to receive the next page of results. Valid only if you received a NextToken response in the previous request. If you did, it indicates that more output is available. Set this parameter to the value provided by the previous call's NextToken response to request the next page of results. (spec name: nextToken)
  --body-max-results: int # Specifies the total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the number you specify, the NextToken response element is returned with a value (not null). Include the specified value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that the service might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getresourcepolicies"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceArns, var: resource_arns}, {name: principal, var: principal}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_arns: $resource_arns, principal: $principal, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the lists of resources and principals that associated for resource shares that you own.
#
# POST /getresourceshareassociations
# Returns: record<resourceShareAssociations: table<resourceShareArn: string, resourceShareName: string, associatedEntity: string, associationType: string, status: string, statusMessage: string, creationTime: string, lastUpdatedTime: string, external: bool>, nextToken: string>
# operationId: GetResourceShareAssociations
export def "get-resource-share-associations" [
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
  association_type: string@association-type-completer # Specifies whether you want to retrieve the associations that involve a specified resource or principal. PRINCIPAL – list the principals whose associations you want to see. RESOURCE – list the resources whose associations you want to see.
  --resource-share-arns: list<string> # Specifies a list of Amazon Resource Names (ARNs) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resource share whose associations you want to retrieve.
  --resource-arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of a resource whose resource shares you want to retrieve. You cannot specify this parameter if the association type is PRINCIPAL.
  --principal: string # Specifies the ID of the principal whose resource shares you want to retrieve. This can be an Amazon Web Services account ID, an organization ID, an organizational unit ID, or the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of an individual IAM user or role. You cannot specify this parameter if the association type is RESOURCE.
  --association-status: string@association-status-completer # Specifies that you want to retrieve only associations that have this status.
  --body-next-token: string # Specifies that you want to receive the next page of results. Valid only if you received a NextToken response in the previous request. If you did, it indicates that more output is available. Set this parameter to the value provided by the previous call's NextToken response to request the next page of results. (spec name: nextToken)
  --body-max-results: int # Specifies the total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the number you specify, the NextToken response element is returned with a value (not null). Include the specified value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that the service might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getresourceshareassociations"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: associationType, var: association_type}, {name: resourceShareArns, var: resource_share_arns}, {name: resourceArn, var: resource_arn}, {name: principal, var: principal}, {name: associationStatus, var: association_status}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, association_type: $association_type, resource_share_arns: $resource_share_arns, resource_arn: $resource_arn, principal: $principal, association_status: $association_status, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves details about invitations that you have received for resource shares.
#
# POST /getresourceshareinvitations
# Returns: record<resourceShareInvitations: table<resourceShareInvitationArn: string, resourceShareName: string, resourceShareArn: string, senderAccountId: string, receiverAccountId: string, invitationTimestamp: string, status: string, resourceShareAssociations: list, receiverArn: string>, nextToken: string>
# operationId: GetResourceShareInvitations
export def "get-resource-share-invitations" [
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
  --resource-share-invitation-arns: list<string> # Specifies the Amazon Resource Names (ARNs) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resource share invitations you want information about.
  --resource-share-arns: list<string> # Specifies that you want details about invitations only for the resource shares described by this list of Amazon Resource Names (ARNs) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html)
  --body-next-token: string # Specifies that you want to receive the next page of results. Valid only if you received a NextToken response in the previous request. If you did, it indicates that more output is available. Set this parameter to the value provided by the previous call's NextToken response to request the next page of results. (spec name: nextToken)
  --body-max-results: int # Specifies the total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the number you specify, the NextToken response element is returned with a value (not null). Include the specified value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that the service might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getresourceshareinvitations"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceShareInvitationArns, var: resource_share_invitation_arns}, {name: resourceShareArns, var: resource_share_arns}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_share_invitation_arns: $resource_share_invitation_arns, resource_share_arns: $resource_share_arns, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves details about the resource shares that you own or that are shared with you.
#
# POST /getresourceshares
# Returns: record<resourceShares: table<resourceShareArn: string, name: string, owningAccountId: string, allowExternalPrincipals: bool, status: string, statusMessage: string, tags: list, creationTime: string, lastUpdatedTime: string, featureSet: string>, nextToken: string>
# operationId: GetResourceShares
export def "get-resource-shares" [
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
  --resource-share-arns: list<string> # Specifies the Amazon Resource Names (ARNs) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of individual resource shares that you want information about.
  --resource-share-status: string@resource-share-status-completer # Specifies that you want to retrieve details of only those resource shares that have this status.
  resource_owner: string@resource-owner-completer # Specifies that you want to retrieve details of only those resource shares that match the following: SELF – resource shares that your account shares with other accounts OTHER-ACCOUNTS – resource shares that other accounts share with your account
  --name: string # Specifies the name of an individual resource share that you want to retrieve details about.
  --tag-filters: list # Specifies that you want to retrieve details of only those resource shares that match the specified tag keys and values. — item shape: {tagKey?: string, tagValues?: list<string>}
  --body-next-token: string # Specifies that you want to receive the next page of results. Valid only if you received a NextToken response in the previous request. If you did, it indicates that more output is available. Set this parameter to the value provided by the previous call's NextToken response to request the next page of results. (spec name: nextToken)
  --body-max-results: int # Specifies the total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the number you specify, the NextToken response element is returned with a value (not null). Include the specified value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that the service might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: maxResults)
  --permission-arn: string # Specifies that you want to retrieve details of only those resource shares that use the managed permission with this Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html).
  --permission-version: int # Specifies that you want to retrieve details for only those resource shares that use the specified version of the managed permission.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getresourceshares"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceShareArns, var: resource_share_arns}, {name: resourceShareStatus, var: resource_share_status}, {name: resourceOwner, var: resource_owner}, {name: name, var: name}, {name: tagFilters, var: tag_filters}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}, {name: permissionArn, var: permission_arn}, {name: permissionVersion, var: permission_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_share_arns: $resource_share_arns, resource_share_status: $resource_share_status, resource_owner: $resource_owner, name: $name, tag_filters: $tag_filters, body_next_token: $body_next_token, body_max_results: $body_max_results, permission_arn: $permission_arn, permission_version: $permission_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the resources in a resource share that is shared with you but for which the invitation is still PENDING. That means that you haven't accepted or rejected the invitation and the invitation hasn't expired.
#
# POST /listpendinginvitationresources
# Returns: record<resources: table<arn: string, type: string, resourceShareArn: string, resourceGroupArn: string, status: string, statusMessage: string, creationTime: string, lastUpdatedTime: string, resourceRegionScope: string>, nextToken: string>
# operationId: ListPendingInvitationResources
export def "list-pending-invitation-resources" [
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
  resource_share_invitation_arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the invitation. You can use GetResourceShareInvitations to find the ARN of the invitation.
  --body-next-token: string # Specifies that you want to receive the next page of results. Valid only if you received a NextToken response in the previous request. If you did, it indicates that more output is available. Set this parameter to the value provided by the previous call's NextToken response to request the next page of results. (spec name: nextToken)
  --body-max-results: int # Specifies the total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the number you specify, the NextToken response element is returned with a value (not null). Include the specified value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that the service might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: maxResults)
  --resource-region-scope: string@resource-region-scope-completer # Specifies that you want the results to include only resources that have the specified scope. ALL – the results include both global and regional resources or resource types. GLOBAL – the results include only global resources or resource types. REGIONAL – the results include only regional resources or resource types. The default value is ALL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/listpendinginvitationresources"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceShareInvitationArn, var: resource_share_invitation_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}, {name: resourceRegionScope, var: resource_region_scope}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_share_invitation_arn: $resource_share_invitation_arn, body_next_token: $body_next_token, body_max_results: $body_max_results, resource_region_scope: $resource_region_scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists information about the managed permission and its associations to any resource shares that use this managed permission. This lets you see which resource shares use which versions of the specified managed permission.
#
# POST /listpermissionassociations
# Returns: record<permissions: table<arn: string, permissionVersion: string, defaultVersion: bool, resourceType: string, status: string, featureSet: string, lastUpdatedTime: string, resourceShareArn: string>, nextToken: string>
# operationId: ListPermissionAssociations
export def "list-permission-associations" [
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
  --permission-arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the managed permission.
  --permission-version: int # Specifies that you want to list only those associations with resource shares that use this version of the managed permission. If you don't provide a value for this parameter, then the operation returns information about associations with resource shares that use any version of the managed permission.
  --association-status: string@association-status-completer # Specifies that you want to list only those associations with resource shares that match this status.
  --resource-type: string # Specifies that you want to list only those associations with resource shares that include at least one resource of this resource type.
  --feature-set: string@feature-set-completer # Specifies that you want to list only those associations with resource shares that have a featureSet with this value.
  --default-version: oneof<nothing, bool> # When true, specifies that you want to list only those associations with resource shares that use the default version of the specified managed permission. When false (the default value), lists associations with resource shares that use any version of the specified managed permission.
  --body-next-token: string # Specifies that you want to receive the next page of results. Valid only if you received a NextToken response in the previous request. If you did, it indicates that more output is available. Set this parameter to the value provided by the previous call's NextToken response to request the next page of results. (spec name: nextToken)
  --body-max-results: int # Specifies the total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the number you specify, the NextToken response element is returned with a value (not null). Include the specified value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that the service might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/listpermissionassociations"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: permissionArn, var: permission_arn}, {name: permissionVersion, var: permission_version}, {name: associationStatus, var: association_status}, {name: resourceType, var: resource_type}, {name: featureSet, var: feature_set}, {name: defaultVersion, var: default_version}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, permission_arn: $permission_arn, permission_version: $permission_version, association_status: $association_status, resource_type: $resource_type, feature_set: $feature_set, default_version: $default_version, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the available versions of the specified RAM permission.
#
# POST /listpermissionversions
# Returns: record<permissions: table<arn: string, version: string, defaultVersion: bool, name: string, resourceType: string, status: string, creationTime: string, lastUpdatedTime: string, isResourceTypeDefault: bool, permissionType: string, featureSet: string, tags: list>, nextToken: string>
# operationId: ListPermissionVersions
export def "list-permission-versions" [
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
  permission_arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the RAM permission whose versions you want to list. You can use the permissionVersion parameter on the AssociateResourceSharePermission operation to specify a non-default version to attach.
  --body-next-token: string # Specifies that you want to receive the next page of results. Valid only if you received a NextToken response in the previous request. If you did, it indicates that more output is available. Set this parameter to the value provided by the previous call's NextToken response to request the next page of results. (spec name: nextToken)
  --body-max-results: int # Specifies the total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the number you specify, the NextToken response element is returned with a value (not null). Include the specified value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that the service might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/listpermissionversions"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: permissionArn, var: permission_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, permission_arn: $permission_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of available RAM permissions that you can use for the supported resource types.
#
# POST /listpermissions
# Returns: record<permissions: table<arn: string, version: string, defaultVersion: bool, name: string, resourceType: string, status: string, creationTime: string, lastUpdatedTime: string, isResourceTypeDefault: bool, permissionType: string, featureSet: string, tags: list>, nextToken: string>
# operationId: ListPermissions
export def "list-permissions" [
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
  --resource-type: string # Specifies that you want to list only those permissions that apply to the specified resource type. This parameter is not case sensitive. For example, to list only permissions that apply to Amazon EC2 subnets, specify ec2:subnet. You can use the ListResourceTypes operation to get the specific string required.
  --body-next-token: string # Specifies that you want to receive the next page of results. Valid only if you received a NextToken response in the previous request. If you did, it indicates that more output is available. Set this parameter to the value provided by the previous call's NextToken response to request the next page of results. (spec name: nextToken)
  --body-max-results: int # Specifies the total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the number you specify, the NextToken response element is returned with a value (not null). Include the specified value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that the service might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: maxResults)
  --permission-type: string@permission-type-completer # Specifies that you want to list only permissions of this type: AWS – returns only Amazon Web Services managed permissions. LOCAL – returns only customer managed permissions ALL – returns both Amazon Web Services managed permissions and customer managed permissions. If you don't specify this parameter, the default is All.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/listpermissions"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceType, var: resource_type}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}, {name: permissionType, var: permission_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_type: $resource_type, body_next_token: $body_next_token, body_max_results: $body_max_results, permission_type: $permission_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the principals that you are sharing resources with or that are sharing resources with you.
#
# POST /listprincipals
# Returns: record<principals: table<id: string, resourceShareArn: string, creationTime: string, lastUpdatedTime: string, external: bool>, nextToken: string>
# operationId: ListPrincipals
export def "list-principals" [
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
  resource_owner: string@resource-owner-completer # Specifies that you want to list information for only resource shares that match the following: SELF – principals that your account is sharing resources with OTHER-ACCOUNTS – principals that are sharing resources with your account
  --resource-arn: string # Specifies that you want to list principal information for the resource share with the specified Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html).
  --principals: list<string> # Specifies that you want to list information for only the listed principals. You can include the following values: An Amazon Web Services account ID, for example: 123456789012 An Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of an organization in Organizations, for example: organizations::123456789012:organization/o-exampleorgid An ARN of an organizational unit (OU) in Organizations, for example: organizations::123456789012:ou/o-exampleorgid/ou-examplerootid-exampleouid123 An ARN of an IAM role, for example: iam::123456789012:role/rolename An ARN of an IAM user, for example: iam::123456789012user/username Not all resource types can be shared with IAM roles and users. For more information, see Sharing with IAM roles and users (https://docs.aws.amazon.com/ram/latest/userguide/permissions.html#permissions-rbp-supported-resource-types) in the Resource Access Manager User Guide.
  --resource-type: string # Specifies that you want to list information for only principals associated with resource shares that include the specified resource type. For a list of valid values, query the ListResourceTypes operation.
  --resource-share-arns: list<string> # Specifies that you want to list information for only principals associated with the resource shares specified by a list the Amazon Resource Names (ARNs) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html).
  --body-next-token: string # Specifies that you want to receive the next page of results. Valid only if you received a NextToken response in the previous request. If you did, it indicates that more output is available. Set this parameter to the value provided by the previous call's NextToken response to request the next page of results. (spec name: nextToken)
  --body-max-results: int # Specifies the total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the number you specify, the NextToken response element is returned with a value (not null). Include the specified value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that the service might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/listprincipals"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceOwner, var: resource_owner}, {name: resourceArn, var: resource_arn}, {name: principals, var: principals}, {name: resourceType, var: resource_type}, {name: resourceShareArns, var: resource_share_arns}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_owner: $resource_owner, resource_arn: $resource_arn, principals: $principals, resource_type: $resource_type, resource_share_arns: $resource_share_arns, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the current status of the asynchronous tasks performed by RAM when you perform the ReplacePermissionAssociationsWork operation.
#
# POST /listreplacepermissionassociationswork
# Returns: record<replacePermissionAssociationsWorks: table<id: string, fromPermissionArn: string, fromPermissionVersion: string, toPermissionArn: string, toPermissionVersion: string, status: string, statusMessage: string, creationTime: string, lastUpdatedTime: string>, nextToken: string>
# operationId: ListReplacePermissionAssociationsWork
export def "list-replace-permission-associations-work" [
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
  --work-ids: list<string> # A list of IDs. These values come from the idfield of the replacePermissionAssociationsWorkstructure returned by the ReplacePermissionAssociations operation.
  --status: string@status-completer # Specifies that you want to see only the details about requests with a status that matches this value.
  --body-next-token: string # Specifies that you want to receive the next page of results. Valid only if you received a NextToken response in the previous request. If you did, it indicates that more output is available. Set this parameter to the value provided by the previous call's NextToken response to request the next page of results. (spec name: nextToken)
  --body-max-results: int # Specifies the total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the number you specify, the NextToken response element is returned with a value (not null). Include the specified value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that the service might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/listreplacepermissionassociationswork"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: workIds, var: work_ids}, {name: status, var: status}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, work_ids: $work_ids, status: $status, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the RAM permissions that are associated with a resource share.
#
# POST /listresourcesharepermissions
# Returns: record<permissions: table<arn: string, version: string, defaultVersion: bool, name: string, resourceType: string, status: string, creationTime: string, lastUpdatedTime: string, isResourceTypeDefault: bool, permissionType: string, featureSet: string, tags: list>, nextToken: string>
# operationId: ListResourceSharePermissions
export def "list-resource-share-permissions" [
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
  resource_share_arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resource share for which you want to retrieve the associated permissions.
  --body-next-token: string # Specifies that you want to receive the next page of results. Valid only if you received a NextToken response in the previous request. If you did, it indicates that more output is available. Set this parameter to the value provided by the previous call's NextToken response to request the next page of results. (spec name: nextToken)
  --body-max-results: int # Specifies the total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the number you specify, the NextToken response element is returned with a value (not null). Include the specified value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that the service might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/listresourcesharepermissions"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceShareArn, var: resource_share_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_share_arn: $resource_share_arn, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the resource types that can be shared by RAM.
#
# POST /listresourcetypes
# Returns: record<resourceTypes: table<resourceType: string, serviceName: string, resourceRegionScope: string>, nextToken: string>
# operationId: ListResourceTypes
export def "list-resource-types" [
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
  --body-next-token: string # Specifies that you want to receive the next page of results. Valid only if you received a NextToken response in the previous request. If you did, it indicates that more output is available. Set this parameter to the value provided by the previous call's NextToken response to request the next page of results. (spec name: nextToken)
  --body-max-results: int # Specifies the total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the number you specify, the NextToken response element is returned with a value (not null). Include the specified value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that the service might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: maxResults)
  --resource-region-scope: string@resource-region-scope-completer # Specifies that you want the results to include only resources that have the specified scope. ALL – the results include both global and regional resources or resource types. GLOBAL – the results include only global resources or resource types. REGIONAL – the results include only regional resources or resource types. The default value is ALL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/listresourcetypes"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}, {name: resourceRegionScope, var: resource_region_scope}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_next_token: $body_next_token, body_max_results: $body_max_results, resource_region_scope: $resource_region_scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the resources that you added to a resource share or the resources that are shared with you.
#
# POST /listresources
# Returns: record<resources: table<arn: string, type: string, resourceShareArn: string, resourceGroupArn: string, status: string, statusMessage: string, creationTime: string, lastUpdatedTime: string, resourceRegionScope: string>, nextToken: string>
# operationId: ListResources
export def "list-resources" [
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
  resource_owner: string@resource-owner-completer # Specifies that you want to list only the resource shares that match the following: SELF – resources that your account shares with other accounts OTHER-ACCOUNTS – resources that other accounts share with your account
  --principal: string # Specifies that you want to list only the resource shares that are associated with the specified principal.
  --resource-type: string # Specifies that you want to list only the resource shares that include resources of the specified resource type. For valid values, query the ListResourceTypes operation.
  --resource-arns: list<string> # Specifies that you want to list only the resource shares that include resources with the specified Amazon Resource Names (ARNs) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html).
  --resource-share-arns: list<string> # Specifies that you want to list only resources in the resource shares identified by the specified Amazon Resource Names (ARNs) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html).
  --body-next-token: string # Specifies that you want to receive the next page of results. Valid only if you received a NextToken response in the previous request. If you did, it indicates that more output is available. Set this parameter to the value provided by the previous call's NextToken response to request the next page of results. (spec name: nextToken)
  --body-max-results: int # Specifies the total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the number you specify, the NextToken response element is returned with a value (not null). Include the specified value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that the service might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: maxResults)
  --resource-region-scope: string@resource-region-scope-completer # Specifies that you want the results to include only resources that have the specified scope. ALL – the results include both global and regional resources or resource types. GLOBAL – the results include only global resources or resource types. REGIONAL – the results include only regional resources or resource types. The default value is ALL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/listresources"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceOwner, var: resource_owner}, {name: principal, var: principal}, {name: resourceType, var: resource_type}, {name: resourceArns, var: resource_arns}, {name: resourceShareArns, var: resource_share_arns}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}, {name: resourceRegionScope, var: resource_region_scope}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_owner: $resource_owner, principal: $principal, resource_type: $resource_type, resource_arns: $resource_arns, resource_share_arns: $resource_share_arns, body_next_token: $body_next_token, body_max_results: $body_max_results, resource_region_scope: $resource_region_scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# When you attach a resource-based policy to a resource, RAM automatically creates a resource share of featureSet=CREATED_FROM_POLICY with a managed permission that has the same IAM permissions as the original resource-based policy. However, this type of managed permission is visible to only the resource share owner, and the associated resource share can't be modified by using RAM. This operation creates a separate, fully manageable customer managed permission that has the same IAM permissions as the original resource-based policy. You can associate this customer managed permission to any resource shares. Before you use PromoteResourceShareCreatedFromPolicy, you should first run this operation to ensure that you have an appropriate customer managed permission that can be associated with the promoted resource share. The original CREATED_FROM_POLICY policy isn't deleted, and resource shares using that original policy aren't automatically updated. You can't modify a CREATED_FROM_POLICY resource share so you can't associate the new customer managed permission by using ReplacePermsissionAssociations. However, if you use PromoteResourceShareCreatedFromPolicy, that operation automatically associates the fully manageable customer managed permission to the newly promoted STANDARD resource share. After you promote a resource share, if the original CREATED_FROM_POLICY managed permission has no other associations to A resource share, then RAM automatically deletes it.
#
# POST /promotepermissioncreatedfrompolicy
# Returns: record<permission: record<arn: string, version: string, defaultVersion: bool, name: string, resourceType: string, status: string, creationTime: string, lastUpdatedTime: string, isResourceTypeDefault: bool, permissionType: string, featureSet: string, tags: list<record>>, clientToken: string>
# operationId: PromotePermissionCreatedFromPolicy
export def "promote-permission-created-from-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  permission_arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the CREATED_FROM_POLICY permission that you want to promote. You can get this Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) by calling the ListResourceSharePermissions operation.
  name: string # Specifies a name for the promoted customer managed permission.
  --client-token: string # Specifies a unique, case-sensitive identifier that you provide to ensure the idempotency of the request. This lets you safely retry the request without accidentally performing the same operation a second time. Passing the same value to a later call to an operation requires that you also pass the same value for all other parameters. We recommend that you use a UUID type of value. (https://wikipedia.org/wiki/Universally_unique_identifier). If you don't provide this value, then Amazon Web Services generates a random one for you. If you retry the operation with the same ClientToken, but with different parameters, the retry fails with an IdempotentParameterMismatch error.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/promotepermissioncreatedfrompolicy"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: permissionArn, var: permission_arn}, {name: name, var: name}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, permission_arn: $permission_arn, name: $name, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# When you attach a resource-based policy to a resource, RAM automatically creates a resource share of featureSet=CREATED_FROM_POLICY with a managed permission that has the same IAM permissions as the original resource-based policy. However, this type of managed permission is visible to only the resource share owner, and the associated resource share can't be modified by using RAM. This operation promotes the resource share to a STANDARD resource share that is fully manageable in RAM. When you promote a resource share, you can then manage the resource share in RAM and it becomes visible to all of the principals you shared it with. Before you perform this operation, you should first run PromotePermissionCreatedFromPolicyto ensure that you have an appropriate customer managed permission that can be associated with this resource share after its is promoted. If this operation can't find a managed permission that exactly matches the existing CREATED_FROM_POLICY permission, then this operation fails.
#
# POST /promoteresourcesharecreatedfrompolicy
# Returns: record<returnValue: bool>
# operationId: PromoteResourceShareCreatedFromPolicy
export def "promote-resource-share-created-from-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-share-arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resource share to promote. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/promoteresourcesharecreatedfrompolicy"
    query: [{name: resourceShareArn, var: resource_share_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_share_arn: $resource_share_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rejects an invitation to a resource share from another Amazon Web Services account.
#
# POST /rejectresourceshareinvitation
# Returns: record<resourceShareInvitation: record<resourceShareInvitationArn: string, resourceShareName: string, resourceShareArn: string, senderAccountId: string, receiverAccountId: string, invitationTimestamp: string, status: string, resourceShareAssociations: list<record>, receiverArn: string>, clientToken: string>
# operationId: RejectResourceShareInvitation
export def "reject-resource-share-invitation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  resource_share_invitation_arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the invitation that you want to reject.
  --client-token: string # Specifies a unique, case-sensitive identifier that you provide to ensure the idempotency of the request. This lets you safely retry the request without accidentally performing the same operation a second time. Passing the same value to a later call to an operation requires that you also pass the same value for all other parameters. We recommend that you use a UUID type of value. (https://wikipedia.org/wiki/Universally_unique_identifier). If you don't provide this value, then Amazon Web Services generates a random one for you. If you retry the operation with the same ClientToken, but with different parameters, the retry fails with an IdempotentParameterMismatch error.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rejectresourceshareinvitation"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceShareInvitationArn, var: resource_share_invitation_arn}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_share_invitation_arn: $resource_share_invitation_arn, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates all resource shares that use a managed permission to a different managed permission. This operation always applies the default version of the target managed permission. You can optionally specify that the update applies to only resource shares that currently use a specified version. This enables you to update to the latest version, without changing the which managed permission is used. You can use this operation to update all of your resource shares to use the current default version of the permission by specifying the same value for the fromPermissionArn and toPermissionArn parameters. You can use the optional fromPermissionVersion parameter to update only those resources that use a specified version of the managed permission to the new managed permission. To successfully perform this operation, you must have permission to update the resource-based policy on all affected resource types.
#
# POST /replacepermissionassociations
# Returns: record<replacePermissionAssociationsWork: record<id: string, fromPermissionArn: string, fromPermissionVersion: string, toPermissionArn: string, toPermissionVersion: string, status: string, statusMessage: string, creationTime: string, lastUpdatedTime: string>, clientToken: string>
# operationId: ReplacePermissionAssociations
export def "replace-permission-associations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  from_permission_arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the managed permission that you want to replace.
  --from-permission-version: int # Specifies that you want to updated the permissions for only those resource shares that use the specified version of the managed permission.
  to_permission_arn: string # Specifies the ARN of the managed permission that you want to associate with resource shares in place of the one specified by fromPerssionArn and fromPermissionVersion. The operation always associates the version that is currently the default for the specified managed permission.
  --client-token: string # Specifies a unique, case-sensitive identifier that you provide to ensure the idempotency of the request. This lets you safely retry the request without accidentally performing the same operation a second time. Passing the same value to a later call to an operation requires that you also pass the same value for all other parameters. We recommend that you use a UUID type of value. (https://wikipedia.org/wiki/Universally_unique_identifier). If you don't provide this value, then Amazon Web Services generates a random one for you. If you retry the operation with the same ClientToken, but with different parameters, the retry fails with an IdempotentParameterMismatch error.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/replacepermissionassociations"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: fromPermissionArn, var: from_permission_arn}, {name: fromPermissionVersion, var: from_permission_version}, {name: toPermissionArn, var: to_permission_arn}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, from_permission_arn: $from_permission_arn, from_permission_version: $from_permission_version, to_permission_arn: $to_permission_arn, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Designates the specified version number as the default version for the specified customer managed permission. New resource shares automatically use this new default permission. Existing resource shares continue to use their original permission version, but you can use ReplacePermissionAssociations to update them.
#
# POST /setdefaultpermissionversion
# Returns: record<returnValue: bool, clientToken: string>
# operationId: SetDefaultPermissionVersion
export def "set-default-permission-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  permission_arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the customer managed permission whose default version you want to change.
  permission_version: int # Specifies the version number that you want to designate as the default for customer managed permission. To see a list of all available version numbers, use ListPermissionVersions.
  --client-token: string # Specifies a unique, case-sensitive identifier that you provide to ensure the idempotency of the request. This lets you safely retry the request without accidentally performing the same operation a second time. Passing the same value to a later call to an operation requires that you also pass the same value for all other parameters. We recommend that you use a UUID type of value. (https://wikipedia.org/wiki/Universally_unique_identifier). If you don't provide this value, then Amazon Web Services generates a random one for you. If you retry the operation with the same ClientToken, but with different parameters, the retry fails with an IdempotentParameterMismatch error.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setdefaultpermissionversion"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: permissionArn, var: permission_arn}, {name: permissionVersion, var: permission_version}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, permission_arn: $permission_arn, permission_version: $permission_version, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds the specified tag keys and values to a resource share or managed permission. If you choose a resource share, the tags are attached to only the resource share, not to the resources that are in the resource share. The tags on a managed permission are the same for all versions of the managed permission.
#
# POST /tagresource
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
  --resource-share-arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resource share that you want to add tags to. You must specify either resourceShareArn, or resourceArn, but not both.
  tags: list # A list of one or more tag key and value pairs. The tag key must be present and not be an empty string. The tag value must be present but can be an empty string. — item shape: {key?: string, value?: string}
  --resource-arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the managed permission that you want to add tags to. You must specify either resourceArn, or resourceShareArn, but not both.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tagresource"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceShareArn, var: resource_share_arn}, {name: tags, var: tags}, {name: resourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_share_arn: $resource_share_arn, tags: $tags, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the specified tag key and value pairs from the specified resource share or managed permission.
#
# POST /untagresource
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
  --resource-share-arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resource share that you want to remove tags from. The tags are removed from the resource share, not the resources in the resource share. You must specify either resourceShareArn, or resourceArn, but not both.
  tag_keys: list<string> # Specifies a list of one or more tag keys that you want to remove.
  --resource-arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the managed permission that you want to remove tags from. You must specify either resourceArn, or resourceShareArn, but not both.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/untagresource"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceShareArn, var: resource_share_arn}, {name: tagKeys, var: tag_keys}, {name: resourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_share_arn: $resource_share_arn, tag_keys: $tag_keys, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies some of the properties of the specified resource share.
#
# POST /updateresourceshare
# Returns: record<resourceShare: record<resourceShareArn: string, name: string, owningAccountId: string, allowExternalPrincipals: bool, status: string, statusMessage: string, tags: list<record>, creationTime: string, lastUpdatedTime: string, featureSet: string>, clientToken: string>
# operationId: UpdateResourceShare
export def "update-resource-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  resource_share_arn: string # Specifies the Amazon Resource Name (ARN) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the resource share that you want to modify.
  --name: string # If specified, the new name that you want to attach to the resource share.
  --allow-external-principals: oneof<nothing, bool> # Specifies whether principals outside your organization in Organizations can be associated with a resource share.
  --client-token: string # Specifies a unique, case-sensitive identifier that you provide to ensure the idempotency of the request. This lets you safely retry the request without accidentally performing the same operation a second time. Passing the same value to a later call to an operation requires that you also pass the same value for all other parameters. We recommend that you use a UUID type of value. (https://wikipedia.org/wiki/Universally_unique_identifier). If you don't provide this value, then Amazon Web Services generates a random one for you. If you retry the operation with the same ClientToken, but with different parameters, the retry fails with an IdempotentParameterMismatch error.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/updateresourceshare"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceShareArn, var: resource_share_arn}, {name: name, var: name}, {name: allowExternalPrincipals, var: allow_external_principals}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_share_arn: $resource_share_arn, name: $name, allow_external_principals: $allow_external_principals, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
