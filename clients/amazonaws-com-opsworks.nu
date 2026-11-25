# Auto-generated client for AWS OpsWorks v2013-02-18
# Source: https://api.apis.guru/v2/specs/amazonaws.com/opsworks/2013-02-18/openapi.json
# Auth: --token flag or $env.AWS_OPSWORKS_TOKEN

const CLIENT = {
  base_url: "http://opsworks.us-east-1.amazonaws.com"
  token_env_var: "AWS_OPSWORKS_TOKEN"
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

def base-url-completer [] { ["http://opsworks.us-east-1.amazonaws.com" "http://opsworks.us-east-2.amazonaws.com" "http://opsworks.us-west-1.amazonaws.com" "http://opsworks.us-west-2.amazonaws.com" "http://opsworks.us-gov-west-1.amazonaws.com" "http://opsworks.us-gov-east-1.amazonaws.com" "http://opsworks.ca-central-1.amazonaws.com" "http://opsworks.eu-north-1.amazonaws.com" "http://opsworks.eu-west-1.amazonaws.com" "http://opsworks.eu-west-2.amazonaws.com" "http://opsworks.eu-west-3.amazonaws.com" "http://opsworks.eu-central-1.amazonaws.com" "http://opsworks.eu-south-1.amazonaws.com" "http://opsworks.af-south-1.amazonaws.com" "http://opsworks.ap-northeast-1.amazonaws.com" "http://opsworks.ap-northeast-2.amazonaws.com" "http://opsworks.ap-northeast-3.amazonaws.com" "http://opsworks.ap-southeast-1.amazonaws.com" "http://opsworks.ap-southeast-2.amazonaws.com" "http://opsworks.ap-east-1.amazonaws.com" "http://opsworks.ap-south-1.amazonaws.com" "http://opsworks.sa-east-1.amazonaws.com" "http://opsworks.me-south-1.amazonaws.com" "https://opsworks.us-east-1.amazonaws.com" "https://opsworks.us-east-2.amazonaws.com" "https://opsworks.us-west-1.amazonaws.com" "https://opsworks.us-west-2.amazonaws.com" "https://opsworks.us-gov-west-1.amazonaws.com" "https://opsworks.us-gov-east-1.amazonaws.com" "https://opsworks.ca-central-1.amazonaws.com" "https://opsworks.eu-north-1.amazonaws.com" "https://opsworks.eu-west-1.amazonaws.com" "https://opsworks.eu-west-2.amazonaws.com" "https://opsworks.eu-west-3.amazonaws.com" "https://opsworks.eu-central-1.amazonaws.com" "https://opsworks.eu-south-1.amazonaws.com" "https://opsworks.af-south-1.amazonaws.com" "https://opsworks.ap-northeast-1.amazonaws.com" "https://opsworks.ap-northeast-2.amazonaws.com" "https://opsworks.ap-northeast-3.amazonaws.com" "https://opsworks.ap-southeast-1.amazonaws.com" "https://opsworks.ap-southeast-2.amazonaws.com" "https://opsworks.ap-east-1.amazonaws.com" "https://opsworks.ap-south-1.amazonaws.com" "https://opsworks.sa-east-1.amazonaws.com" "https://opsworks.me-south-1.amazonaws.com" "http://opsworks.cn-north-1.amazonaws.com.cn" "http://opsworks.cn-northwest-1.amazonaws.com.cn" "https://opsworks.cn-north-1.amazonaws.com.cn" "https://opsworks.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["OpsWorks_20130218.AssignInstance"] }
def x-amz-target-completer-1 [] { ["OpsWorks_20130218.AssignVolume"] }
def x-amz-target-completer-2 [] { ["OpsWorks_20130218.AssociateElasticIp"] }
def x-amz-target-completer-3 [] { ["OpsWorks_20130218.AttachElasticLoadBalancer"] }
def default-root-device-type-completer [] { ["ebs" "instance-store"] }
def x-amz-target-completer-4 [] { ["OpsWorks_20130218.CloneStack"] }
def type-completer [] { ["aws-flow-ruby" "java" "nodejs" "other" "php" "rails" "static"] }
def x-amz-target-completer-5 [] { ["OpsWorks_20130218.CreateApp"] }
def x-amz-target-completer-6 [] { ["OpsWorks_20130218.CreateDeployment"] }
def auto-scaling-type-completer [] { ["load" "timer"] }
def architecture-completer [] { ["i386" "x86_64"] }
def root-device-type-completer [] { ["ebs" "instance-store"] }
def x-amz-target-completer-7 [] { ["OpsWorks_20130218.CreateInstance"] }
def type-completer-1 [] { ["aws-flow-ruby" "custom" "db-master" "ecs-cluster" "java-app" "lb" "memcached" "monitoring-master" "nodejs-app" "php-app" "rails-app" "web"] }
def x-amz-target-completer-8 [] { ["OpsWorks_20130218.CreateLayer"] }
def x-amz-target-completer-9 [] { ["OpsWorks_20130218.CreateStack"] }
def x-amz-target-completer-10 [] { ["OpsWorks_20130218.CreateUserProfile"] }
def x-amz-target-completer-11 [] { ["OpsWorks_20130218.DeleteApp"] }
def x-amz-target-completer-12 [] { ["OpsWorks_20130218.DeleteInstance"] }
def x-amz-target-completer-13 [] { ["OpsWorks_20130218.DeleteLayer"] }
def x-amz-target-completer-14 [] { ["OpsWorks_20130218.DeleteStack"] }
def x-amz-target-completer-15 [] { ["OpsWorks_20130218.DeleteUserProfile"] }
def x-amz-target-completer-16 [] { ["OpsWorks_20130218.DeregisterEcsCluster"] }
def x-amz-target-completer-17 [] { ["OpsWorks_20130218.DeregisterElasticIp"] }
def x-amz-target-completer-18 [] { ["OpsWorks_20130218.DeregisterInstance"] }
def x-amz-target-completer-19 [] { ["OpsWorks_20130218.DeregisterRdsDbInstance"] }
def x-amz-target-completer-20 [] { ["OpsWorks_20130218.DeregisterVolume"] }
def x-amz-target-completer-21 [] { ["OpsWorks_20130218.DescribeAgentVersions"] }
def x-amz-target-completer-22 [] { ["OpsWorks_20130218.DescribeApps"] }
def x-amz-target-completer-23 [] { ["OpsWorks_20130218.DescribeCommands"] }
def x-amz-target-completer-24 [] { ["OpsWorks_20130218.DescribeDeployments"] }
def x-amz-target-completer-25 [] { ["OpsWorks_20130218.DescribeEcsClusters"] }
def x-amz-target-completer-26 [] { ["OpsWorks_20130218.DescribeElasticIps"] }
def x-amz-target-completer-27 [] { ["OpsWorks_20130218.DescribeElasticLoadBalancers"] }
def x-amz-target-completer-28 [] { ["OpsWorks_20130218.DescribeInstances"] }
def x-amz-target-completer-29 [] { ["OpsWorks_20130218.DescribeLayers"] }
def x-amz-target-completer-30 [] { ["OpsWorks_20130218.DescribeLoadBasedAutoScaling"] }
def x-amz-target-completer-31 [] { ["OpsWorks_20130218.DescribeMyUserProfile"] }
def x-amz-target-completer-32 [] { ["OpsWorks_20130218.DescribeOperatingSystems"] }
def x-amz-target-completer-33 [] { ["OpsWorks_20130218.DescribePermissions"] }
def x-amz-target-completer-34 [] { ["OpsWorks_20130218.DescribeRaidArrays"] }
def x-amz-target-completer-35 [] { ["OpsWorks_20130218.DescribeRdsDbInstances"] }
def x-amz-target-completer-36 [] { ["OpsWorks_20130218.DescribeServiceErrors"] }
def x-amz-target-completer-37 [] { ["OpsWorks_20130218.DescribeStackProvisioningParameters"] }
def x-amz-target-completer-38 [] { ["OpsWorks_20130218.DescribeStackSummary"] }
def x-amz-target-completer-39 [] { ["OpsWorks_20130218.DescribeStacks"] }
def x-amz-target-completer-40 [] { ["OpsWorks_20130218.DescribeTimeBasedAutoScaling"] }
def x-amz-target-completer-41 [] { ["OpsWorks_20130218.DescribeUserProfiles"] }
def x-amz-target-completer-42 [] { ["OpsWorks_20130218.DescribeVolumes"] }
def x-amz-target-completer-43 [] { ["OpsWorks_20130218.DetachElasticLoadBalancer"] }
def x-amz-target-completer-44 [] { ["OpsWorks_20130218.DisassociateElasticIp"] }
def x-amz-target-completer-45 [] { ["OpsWorks_20130218.GetHostnameSuggestion"] }
def x-amz-target-completer-46 [] { ["OpsWorks_20130218.GrantAccess"] }
def x-amz-target-completer-47 [] { ["OpsWorks_20130218.ListTags"] }
def x-amz-target-completer-48 [] { ["OpsWorks_20130218.RebootInstance"] }
def x-amz-target-completer-49 [] { ["OpsWorks_20130218.RegisterEcsCluster"] }
def x-amz-target-completer-50 [] { ["OpsWorks_20130218.RegisterElasticIp"] }
def x-amz-target-completer-51 [] { ["OpsWorks_20130218.RegisterInstance"] }
def x-amz-target-completer-52 [] { ["OpsWorks_20130218.RegisterRdsDbInstance"] }
def x-amz-target-completer-53 [] { ["OpsWorks_20130218.RegisterVolume"] }
def x-amz-target-completer-54 [] { ["OpsWorks_20130218.SetLoadBasedAutoScaling"] }
def x-amz-target-completer-55 [] { ["OpsWorks_20130218.SetPermission"] }
def x-amz-target-completer-56 [] { ["OpsWorks_20130218.SetTimeBasedAutoScaling"] }
def x-amz-target-completer-57 [] { ["OpsWorks_20130218.StartInstance"] }
def x-amz-target-completer-58 [] { ["OpsWorks_20130218.StartStack"] }
def x-amz-target-completer-59 [] { ["OpsWorks_20130218.StopInstance"] }
def x-amz-target-completer-60 [] { ["OpsWorks_20130218.StopStack"] }
def x-amz-target-completer-61 [] { ["OpsWorks_20130218.TagResource"] }
def x-amz-target-completer-62 [] { ["OpsWorks_20130218.UnassignInstance"] }
def x-amz-target-completer-63 [] { ["OpsWorks_20130218.UnassignVolume"] }
def x-amz-target-completer-64 [] { ["OpsWorks_20130218.UntagResource"] }
def x-amz-target-completer-65 [] { ["OpsWorks_20130218.UpdateApp"] }
def x-amz-target-completer-66 [] { ["OpsWorks_20130218.UpdateElasticIp"] }
def x-amz-target-completer-67 [] { ["OpsWorks_20130218.UpdateInstance"] }
def x-amz-target-completer-68 [] { ["OpsWorks_20130218.UpdateLayer"] }
def x-amz-target-completer-69 [] { ["OpsWorks_20130218.UpdateMyUserProfile"] }
def x-amz-target-completer-70 [] { ["OpsWorks_20130218.UpdateRdsDbInstance"] }
def x-amz-target-completer-71 [] { ["OpsWorks_20130218.UpdateStack"] }
def x-amz-target-completer-72 [] { ["OpsWorks_20130218.UpdateUserProfile"] }
def x-amz-target-completer-73 [] { ["OpsWorks_20130218.UpdateVolume"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    clone-stack: "record<StackId: string>"
    create-app: "record<AppId: string>"
    create-deployment: "record<DeploymentId: string>"
    create-instance: "record<InstanceId: string>"
    create-layer: "record<LayerId: string>"
    create-stack: "record<StackId: string>"
    create-user-profile: "record<IamUserArn: string>"
    describe-agent-versions: "record<AgentVersions: table<Version: string, ConfigurationManager: record>>"
    describe-apps: "record<Apps: table<AppId: string, StackId: string, Shortname: string, Name: string, Description: string, DataSources: list, Type: string, AppSource: record, Domains: list, EnableSsl: bool, SslConfiguration: record, Attributes: record, CreatedAt: string, Environment: list>>"
    describe-commands: "record<Commands: table<CommandId: string, InstanceId: string, DeploymentId: string, CreatedAt: string, AcknowledgedAt: string, CompletedAt: string, Status: string, ExitCode: int, LogUrl: string, Type: string>>"
    describe-deployments: "record<Deployments: table<DeploymentId: string, StackId: string, AppId: string, CreatedAt: string, CompletedAt: string, Duration: int, IamUserArn: string, Comment: string, Command: record, Status: string, CustomJson: string, InstanceIds: list>>"
    describe-ecs-clusters: "record<EcsClusters: table<EcsClusterArn: string, EcsClusterName: string, StackId: string, RegisteredAt: string>, NextToken: string>"
    describe-elastic-ips: "record<ElasticIps: table<Ip: string, Name: string, Domain: string, Region: string, InstanceId: string>>"
    describe-elastic-load-balancers: "record<ElasticLoadBalancers: table<ElasticLoadBalancerName: string, Region: string, DnsName: string, StackId: string, LayerId: string, VpcId: string, AvailabilityZones: list, SubnetIds: list, Ec2InstanceIds: list>>"
    describe-instances: "record<Instances: table<AgentVersion: string, AmiId: string, Architecture: string, Arn: string, AutoScalingType: string, AvailabilityZone: string, BlockDeviceMappings: list, CreatedAt: string, EbsOptimized: bool, Ec2InstanceId: string, EcsClusterArn: string, EcsContainerInstanceArn: string, ElasticIp: string, Hostname: string, InfrastructureClass: string, InstallUpdatesOnBoot: bool, InstanceId: string, InstanceProfileArn: string, InstanceType: string, LastServiceErrorId: string, LayerIds: list, Os: string, Platform: string, PrivateDns: string, PrivateIp: string, PublicDns: string, PublicIp: string, RegisteredBy: string, ReportedAgentVersion: string, ReportedOs: record, RootDeviceType: string, RootDeviceVolumeId: string, SecurityGroupIds: list, SshHostDsaKeyFingerprint: string, SshHostRsaKeyFingerprint: string, SshKeyName: string, StackId: string, Status: string, SubnetId: string, Tenancy: string, VirtualizationType: string>>"
    describe-layers: "record<Layers: table<Arn: string, StackId: string, LayerId: string, Type: string, Name: string, Shortname: string, Attributes: record, CloudWatchLogsConfiguration: record, CustomInstanceProfileArn: string, CustomJson: string, CustomSecurityGroupIds: list, DefaultSecurityGroupNames: list, Packages: list, VolumeConfigurations: list, EnableAutoHealing: bool, AutoAssignElasticIps: bool, AutoAssignPublicIps: bool, DefaultRecipes: record, CustomRecipes: record, CreatedAt: string, InstallUpdatesOnBoot: bool, UseEbsOptimizedInstances: bool, LifecycleEventConfiguration: record>>"
    describe-load-based-auto-scaling: "record<LoadBasedAutoScalingConfigurations: table<LayerId: string, Enable: bool, UpScaling: record, DownScaling: record>>"
    describe-my-user-profile: "record<UserProfile: record<IamUserArn: string, Name: string, SshUsername: string, SshPublicKey: string>>"
    describe-operating-systems: "record<OperatingSystems: table<Name: string, Id: string, Type: string, ConfigurationManagers: list, ReportedName: string, ReportedVersion: string, Supported: bool>>"
    describe-permissions: "record<Permissions: table<StackId: string, IamUserArn: string, AllowSsh: bool, AllowSudo: bool, Level: string>>"
    describe-raid-arrays: "record<RaidArrays: table<RaidArrayId: string, InstanceId: string, Name: string, RaidLevel: int, NumberOfDisks: int, Size: int, Device: string, MountPoint: string, AvailabilityZone: string, CreatedAt: string, StackId: string, VolumeType: string, Iops: int>>"
    describe-rds-db-instances: "record<RdsDbInstances: table<RdsDbInstanceArn: string, DbInstanceIdentifier: string, DbUser: string, DbPassword: string, Region: string, Address: string, Engine: string, StackId: string, MissingOnRds: bool>>"
    describe-service-errors: "record<ServiceErrors: table<ServiceErrorId: string, StackId: string, InstanceId: string, Type: string, Message: string, CreatedAt: string>>"
    describe-stack-provisioning-parameters: "record<AgentInstallerUrl: string, Parameters: record>"
    describe-stack-summary: "record<StackSummary: record<StackId: string, Name: string, Arn: string, LayersCount: int, AppsCount: int, InstancesCount: record<Assigning: int, Booting: int, ConnectionLost: int, Deregistering: int, Online: int, Pending: int, Rebooting: int, Registered: int, Registering: int, Requested: int, RunningSetup: int, SetupFailed: int, ShuttingDown: int, StartFailed: int, StopFailed: int, Stopped: int, Stopping: int, Terminated: int, Terminating: int, Unassigning: int>>>"
    describe-stacks: "record<Stacks: table<StackId: string, Name: string, Arn: string, Region: string, VpcId: string, Attributes: record, ServiceRoleArn: string, DefaultInstanceProfileArn: string, DefaultOs: string, HostnameTheme: string, DefaultAvailabilityZone: string, DefaultSubnetId: string, CustomJson: string, ConfigurationManager: record, ChefConfiguration: record, UseCustomCookbooks: bool, UseOpsworksSecurityGroups: bool, CustomCookbooksSource: record, DefaultSshKeyName: string, CreatedAt: string, DefaultRootDeviceType: string, AgentVersion: string>>"
    describe-time-based-auto-scaling: "record<TimeBasedAutoScalingConfigurations: table<InstanceId: string, AutoScalingSchedule: record>>"
    describe-user-profiles: "record<UserProfiles: table<IamUserArn: string, Name: string, SshUsername: string, SshPublicKey: string, AllowSelfManagement: bool>>"
    describe-volumes: "record<Volumes: table<VolumeId: string, Ec2VolumeId: string, Name: string, RaidArrayId: string, InstanceId: string, Status: string, Size: int, Device: string, MountPoint: string, Region: string, AvailabilityZone: string, VolumeType: string, Iops: int, Encrypted: bool>>"
    get-hostname-suggestion: "record<LayerId: string, Hostname: string>"
    grant-access: "record<TemporaryCredential: record<Username: string, Password: string, ValidForInMinutes: int, InstanceId: string>>"
    list-tags: "record<Tags: record, NextToken: string>"
    register-ecs-cluster: "record<EcsClusterArn: string>"
    register-elastic-ip: "record<ElasticIp: string>"
    register-instance: "record<InstanceId: string>"
    register-volume: "record<VolumeId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["assign-instance" "assign-volume" "associate-elastic-ip" "attach-elastic-load-balancer" "clone-stack" "create-app" "create-deployment" "create-instance" "create-layer" "create-stack" "create-user-profile" "delete-app" "delete-instance" "delete-layer" "delete-stack" "delete-user-profile" "deregister-ecs-cluster" "deregister-elastic-ip" "deregister-instance" "deregister-rds-db-instance" "deregister-volume" "describe-agent-versions" "describe-apps" "describe-commands" "describe-deployments" "describe-ecs-clusters" "describe-elastic-ips" "describe-elastic-load-balancers" "describe-instances" "describe-layers" "describe-load-based-auto-scaling" "describe-my-user-profile" "describe-operating-systems" "describe-permissions" "describe-raid-arrays" "describe-rds-db-instances" "describe-service-errors" "describe-stack-provisioning-parameters" "describe-stack-summary" "describe-stacks" "describe-time-based-auto-scaling" "describe-user-profiles" "describe-volumes" "detach-elastic-load-balancer" "disassociate-elastic-ip" "get-hostname-suggestion" "grant-access" "list-tags" "reboot-instance" "register-ecs-cluster" "register-elastic-ip" "register-instance" "register-rds-db-instance" "register-volume" "set-load-based-auto-scaling" "set-permission" "set-time-based-auto-scaling" "start-instance" "start-stack" "stop-instance" "stop-stack" "tag-resource" "unassign-instance" "unassign-volume" "untag-resource" "update-app" "update-elastic-ip" "update-instance" "update-layer" "update-my-user-profile" "update-rds-db-instance" "update-stack" "update-user-profile" "update-volume" "commands"] | sort) } | get name | first)
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

# Assign a registered instance to a layer. You can assign registered on-premises instances to any layer type. You can assign registered Amazon EC2 instances only to custom layers. You cannot use this action with instances that were created with AWS OpsWorks Stacks. Required Permissions: To use this action, an AWS Identity and Access Management (IAM) user must have a Manage permissions level for the stack or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: AssignInstance
export def "assign-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_id: string # The instance ID.
  layer_ids: list<string> # The layer ID, which must correspond to a custom layer. You cannot assign a registered instance to a built-in layer.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.AssignInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: LayerIds, var: layer_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id, layer_ids: $layer_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assigns one of the stack's registered Amazon EBS volumes to a specified instance. The volume must first be registered with the stack by calling RegisterVolume. After you register the volume, you must call UpdateVolume to specify a mount point before calling AssignVolume. For more information, see Resource Management (https://docs.aws.amazon.com/opsworks/latest/userguide/resources.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: AssignVolume
export def "assign-volume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  volume_id: string # The volume ID.
  --instance-id: string # The instance ID.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.AssignVolume"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VolumeId, var: volume_id}, {name: InstanceId, var: instance_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, volume_id: $volume_id, instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates one of the stack's registered Elastic IP addresses with a specified instance. The address must first be registered with the stack by calling RegisterElasticIp. For more information, see Resource Management (https://docs.aws.amazon.com/opsworks/latest/userguide/resources.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: AssociateElasticIp
export def "associate-elastic-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  elastic_ip: string # The Elastic IP address.
  --instance-id: string # The instance ID.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.AssociateElasticIp"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ElasticIp, var: elastic_ip}, {name: InstanceId, var: instance_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, elastic_ip: $elastic_ip, instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches an Elastic Load Balancing load balancer to a specified layer. AWS OpsWorks Stacks does not support Application Load Balancer. You can only use Classic Load Balancer with AWS OpsWorks Stacks. For more information, see Elastic Load Balancing (https://docs.aws.amazon.com/opsworks/latest/userguide/layers-elb.html). You must create the Elastic Load Balancing instance separately, by using the Elastic Load Balancing console, API, or CLI. For more information, see Elastic Load Balancing Developer Guide (https://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/Welcome.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: AttachElasticLoadBalancer
export def "attach-elastic-load-balancer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  elastic_load_balancer_name: string # The Elastic Load Balancing instance's name.
  layer_id: string # The ID of the layer to which the Elastic Load Balancing instance is to be attached.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.AttachElasticLoadBalancer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ElasticLoadBalancerName, var: elastic_load_balancer_name}, {name: LayerId, var: layer_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, elastic_load_balancer_name: $elastic_load_balancer_name, layer_id: $layer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a clone of a specified stack. For more information, see Clone a Stack (https://docs.aws.amazon.com/opsworks/latest/userguide/workingstacks-cloning.html). By default, all parameters are set to the values used by the parent stack. Required Permissions: To use this action, an IAM user must have an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<StackId: string>
# operationId: CloneStack
export def "clone-stack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  source_stack_id: string # The source stack ID.
  --name: string # The cloned stack name.
  --region: string # The cloned stack AWS region, such as "ap-northeast-2". For more information about AWS regions, see Regions and Endpoints (https://docs.aws.amazon.com/general/latest/gr/rande.html).
  --vpc-id: string # The ID of the VPC that the cloned stack is to be launched into. It must be in the specified region. All instances are launched into this VPC, and you cannot change the ID later. If your account supports EC2 Classic, the default value is no VPC. If your account does not support EC2 Classic, the default value is the default VPC for the specified region. If the VPC ID corresponds to a default VPC and you have specified either the DefaultAvailabilityZone or the DefaultSubnetId parameter only, AWS OpsWorks Stacks infers the value of the other parameter. If you specify neither parameter, AWS OpsWorks Stacks sets these parameters to the first valid Availability Zone for the specified region and the corresponding default VPC subnet ID, respectively. If you specify a nondefault VPC ID, note the following: It must belong to a VPC in your account that is in the specified region. You must specify a value for DefaultSubnetId. For more information about how to use AWS OpsWorks Stacks with a VPC, see Running a Stack in a VPC (https://docs.aws.amazon.com/opsworks/latest/userguide/workingstacks-vpc.html). For more information about default VPC and EC2 Classic, see Supported Platforms (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-supported-platforms.html).
  --attributes: record # A list of stack attributes and values as key/value pairs to be added to the cloned stack.
  service_role_arn: string # The stack AWS Identity and Access Management (IAM) role, which allows AWS OpsWorks Stacks to work with AWS resources on your behalf. You must set this parameter to the Amazon Resource Name (ARN) for an existing IAM role. If you create a stack by using the AWS OpsWorks Stacks console, it creates the role for you. You can obtain an existing stack's IAM ARN programmatically by calling DescribePermissions. For more information about IAM ARNs, see Using Identifiers (https://docs.aws.amazon.com/IAM/latest/UserGuide/Using_Identifiers.html). You must set this parameter to a valid service role ARN or the action will fail; there is no default value. You can specify the source stack's service role ARN, if you prefer, but you must do so explicitly.
  --default-instance-profile-arn: string # The Amazon Resource Name (ARN) of an IAM profile that is the default profile for all of the stack's EC2 instances. For more information about IAM ARNs, see Using Identifiers (https://docs.aws.amazon.com/IAM/latest/UserGuide/Using_Identifiers.html).
  --default-os: string # The stack's operating system, which must be set to one of the following. A supported Linux operating system: An Amazon Linux version, such as Amazon Linux 2018.03, Amazon Linux 2017.09, Amazon Linux 2017.03, Amazon Linux 2016.09, Amazon Linux 2016.03, Amazon Linux 2015.09, or Amazon Linux 2015.03. A supported Ubuntu operating system, such as Ubuntu 16.04 LTS, Ubuntu 14.04 LTS, or Ubuntu 12.04 LTS. CentOS Linux 7 Red Hat Enterprise Linux 7 Microsoft Windows Server 2012 R2 Base, Microsoft Windows Server 2012 R2 with SQL Server Express, Microsoft Windows Server 2012 R2 with SQL Server Standard, or Microsoft Windows Server 2012 R2 with SQL Server Web. A custom AMI: Custom. You specify the custom AMI you want to use when you create instances. For more information about how to use custom AMIs with OpsWorks, see Using Custom AMIs (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-custom-ami.html). The default option is the parent stack's operating system. For more information about supported operating systems, see AWS OpsWorks Stacks Operating Systems (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-os.html). You can specify a different Linux operating system for the cloned stack, but you cannot change from Linux to Windows or Windows to Linux.
  --hostname-theme: string # The stack's host name theme, with spaces are replaced by underscores. The theme is used to generate host names for the stack's instances. By default, HostnameTheme is set to Layer_Dependent, which creates host names by appending integers to the layer's short name. The other themes are: Baked_Goods Clouds Europe_Cities Fruits Greek_Deities_and_Titans Legendary_creatures_from_Japan Planets_and_Moons Roman_Deities Scottish_Islands US_Cities Wild_Cats To obtain a generated host name, call GetHostNameSuggestion, which returns a host name based on the current theme.
  --default-availability-zone: string # The cloned stack's default Availability Zone, which must be in the specified region. For more information, see Regions and Endpoints (https://docs.aws.amazon.com/general/latest/gr/rande.html). If you also specify a value for DefaultSubnetId, the subnet must be in the same zone. For more information, see the VpcId parameter description.
  --default-subnet-id: string # The stack's default VPC subnet ID. This parameter is required if you specify a value for the VpcId parameter. All instances are launched into this subnet unless you specify otherwise when you create the instance. If you also specify a value for DefaultAvailabilityZone, the subnet must be in that zone. For information on default values and when this parameter is required, see the VpcId parameter description.
  --custom-json: string # A string that contains user-defined, custom JSON. It is used to override the corresponding default stack configuration JSON values. The string should be in the following format: "{\"key1\": \"value1\", \"key2\": \"value2\",...}" For more information about custom JSON, see Use Custom JSON to Modify the Stack Configuration Attributes (https://docs.aws.amazon.com/opsworks/latest/userguide/workingstacks-json.html)
  --configuration-manager: record # Describes the configuration manager. — shape: {Name?: string, Version?: string}
  --chef-configuration: record # Describes the Chef configuration. — shape: {ManageBerkshelf?: bool, BerkshelfVersion?: string}
  --use-custom-cookbooks: oneof<nothing, bool> # Whether to use custom cookbooks.
  --use-opsworks-security-groups: oneof<nothing, bool> # Whether to associate the AWS OpsWorks Stacks built-in security groups with the stack's layers. AWS OpsWorks Stacks provides a standard set of built-in security groups, one for each layer, which are associated with layers by default. With UseOpsworksSecurityGroups you can instead provide your own custom security groups. UseOpsworksSecurityGroups has the following settings: True - AWS OpsWorks Stacks automatically associates the appropriate built-in security group with each layer (default setting). You can associate additional security groups with a layer after you create it but you cannot delete the built-in security group. False - AWS OpsWorks Stacks does not associate built-in security groups with layers. You must create appropriate Amazon Elastic Compute Cloud (Amazon EC2) security groups and associate a security group with each layer that you create. However, you can still manually associate a built-in security group with a layer on creation; custom security groups are required only for those layers that need custom settings. For more information, see Create a New Stack (https://docs.aws.amazon.com/opsworks/latest/userguide/workingstacks-creating.html).
  --custom-cookbooks-source: record # Contains the information required to retrieve an app or cookbook from a repository. For more information, see Creating Apps (https://docs.aws.amazon.com/opsworks/latest/userguide/workingapps-creating.html) or Custom Recipes and Cookbooks (https://docs.aws.amazon.com/opsworks/latest/userguide/workingcookbook.html). — shape: {Type?: "git"|"svn"|"archive"|"s3", Url?: string, Username?: string, Password?: string, SshKey?: string, Revision?: string}
  --default-ssh-key-name: string # A default Amazon EC2 key pair name. The default value is none. If you specify a key pair name, AWS OpsWorks installs the public key on the instance and you can use the private key with an SSH client to log in to the instance. For more information, see Using SSH to Communicate with an Instance (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-ssh.html) and Managing SSH Access (https://docs.aws.amazon.com/opsworks/latest/userguide/security-ssh-access.html). You can override this setting by specifying a different key pair, or no key pair, when you create an instance (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-add.html).
  --clone-permissions: oneof<nothing, bool> # Whether to clone the source stack's permissions.
  --clone-app-ids: list<string> # A list of source stack app IDs to be included in the cloned stack.
  --default-root-device-type: string@default-root-device-type-completer # The default root device type. This value is used by default for all instances in the cloned stack, but you can override it when you create an instance. For more information, see Storage for the Root Device (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ComponentsAMIs.html#storage-for-the-root-device).
  --agent-version: string # The default AWS OpsWorks Stacks agent version. You have the following options: Auto-update - Set this parameter to LATEST. AWS OpsWorks Stacks automatically installs new agent versions on the stack's instances as soon as they are available. Fixed version - Set this parameter to your preferred agent version. To update the agent version, you must edit the stack configuration and specify a new version. AWS OpsWorks Stacks then automatically installs that version on the stack's instances. The default setting is LATEST. To specify an agent version, you must use the complete version number, not the abbreviated number shown on the console. For a list of available agent version numbers, call DescribeAgentVersions. AgentVersion cannot be set to Chef 12.2. You can also specify an agent version when you create or update an instance, which overrides the stack's default setting.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.CloneStack"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SourceStackId, var: source_stack_id}, {name: Name, var: name}, {name: Region, var: region}, {name: VpcId, var: vpc_id}, {name: Attributes, var: attributes}, {name: ServiceRoleArn, var: service_role_arn}, {name: DefaultInstanceProfileArn, var: default_instance_profile_arn}, {name: DefaultOs, var: default_os}, {name: HostnameTheme, var: hostname_theme}, {name: DefaultAvailabilityZone, var: default_availability_zone}, {name: DefaultSubnetId, var: default_subnet_id}, {name: CustomJson, var: custom_json}, {name: ConfigurationManager, var: configuration_manager}, {name: ChefConfiguration, var: chef_configuration}, {name: UseCustomCookbooks, var: use_custom_cookbooks}, {name: UseOpsworksSecurityGroups, var: use_opsworks_security_groups}, {name: CustomCookbooksSource, var: custom_cookbooks_source}, {name: DefaultSshKeyName, var: default_ssh_key_name}, {name: ClonePermissions, var: clone_permissions}, {name: CloneAppIds, var: clone_app_ids}, {name: DefaultRootDeviceType, var: default_root_device_type}, {name: AgentVersion, var: agent_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, source_stack_id: $source_stack_id, name: $name, region: $region, vpc_id: $vpc_id, attributes: $attributes, service_role_arn: $service_role_arn, default_instance_profile_arn: $default_instance_profile_arn, default_os: $default_os, hostname_theme: $hostname_theme, default_availability_zone: $default_availability_zone, default_subnet_id: $default_subnet_id, custom_json: $custom_json, configuration_manager: $configuration_manager, chef_configuration: $chef_configuration, use_custom_cookbooks: $use_custom_cookbooks, use_opsworks_security_groups: $use_opsworks_security_groups, custom_cookbooks_source: $custom_cookbooks_source, default_ssh_key_name: $default_ssh_key_name, clone_permissions: $clone_permissions, clone_app_ids: $clone_app_ids, default_root_device_type: $default_root_device_type, agent_version: $agent_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an app for a specified stack. For more information, see Creating Apps (https://docs.aws.amazon.com/opsworks/latest/userguide/workingapps-creating.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<AppId: string>
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
  --x-amz-target: string@x-amz-target-completer-5 # required
  stack_id: string # The stack ID.
  --shortname: string # The app's short name.
  name: string # The app name.
  --description: string # A description of the app.
  --data-sources: list # The app's data source. — item shape: {Type?: string, Arn?: string, DatabaseName?: string}
  type: string@type-completer # The app type. Each supported type is associated with a particular layer. For example, PHP applications are associated with a PHP layer. AWS OpsWorks Stacks deploys an application to those instances that are members of the corresponding layer. If your app isn't one of the standard types, or you prefer to implement your own Deploy recipes, specify other.
  --app-source: record # Contains the information required to retrieve an app or cookbook from a repository. For more information, see Creating Apps (https://docs.aws.amazon.com/opsworks/latest/userguide/workingapps-creating.html) or Custom Recipes and Cookbooks (https://docs.aws.amazon.com/opsworks/latest/userguide/workingcookbook.html). — shape: {Type?: "git"|"svn"|"archive"|"s3", Url?: string, Username?: string, Password?: string, SshKey?: string, Revision?: string}
  --domains: list<string> # The app virtual host settings, with multiple domains separated by commas. For example: 'www.example.com, example.com'
  --enable-ssl: oneof<nothing, bool> # Whether to enable SSL for the app.
  --ssl-configuration: record # Describes an app's SSL configuration. — shape: {Certificate: string, PrivateKey: string, Chain?: string}
  --attributes: record # One or more user-defined key/value pairs to be added to the stack attributes.
  --environment: list # An array of EnvironmentVariable objects that specify environment variables to be associated with the app. After you deploy the app, these variables are defined on the associated app server instance. For more information, see Environment Variables (https://docs.aws.amazon.com/opsworks/latest/userguide/workingapps-creating.html#workingapps-creating-environment). There is no specific limit on the number of environment variables. However, the size of the associated data structure - which includes the variables' names, values, and protected flag values - cannot exceed 20 KB. This limit should accommodate most if not all use cases. Exceeding it will cause an exception with the message, "Environment: is too large (maximum is 20KB)." If you have specified one or more environment variables, you cannot modify the stack's Chef version. — item shape: {Key: string, Value: string, Secure?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.CreateApp"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}, {name: Shortname, var: shortname}, {name: Name, var: name}, {name: Description, var: description}, {name: DataSources, var: data_sources}, {name: Type, var: type}, {name: AppSource, var: app_source}, {name: Domains, var: domains}, {name: EnableSsl, var: enable_ssl}, {name: SslConfiguration, var: ssl_configuration}, {name: Attributes, var: attributes}, {name: Environment, var: environment}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id, shortname: $shortname, name: $name, description: $description, data_sources: $data_sources, type: $type, app_source: $app_source, domains: $domains, enable_ssl: $enable_ssl, ssl_configuration: $ssl_configuration, attributes: $attributes, environment: $environment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs deployment or stack commands. For more information, see Deploying Apps (https://docs.aws.amazon.com/opsworks/latest/userguide/workingapps-deploying.html) and Run Stack Commands (https://docs.aws.amazon.com/opsworks/latest/userguide/workingstacks-commands.html). Required Permissions: To use this action, an IAM user must have a Deploy or Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<DeploymentId: string>
# operationId: CreateDeployment
export def "create-deployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  stack_id: string # The stack ID.
  --app-id: string # The app ID. This parameter is required for app deployments, but not for other deployment commands.
  --instance-ids: list<string> # The instance IDs for the deployment targets.
  --layer-ids: list<string> # The layer IDs for the deployment targets.
  command: record # Used to specify a stack or deployment command. — shape: {Name: "install_dependencies"|"update_dependencies"|"update_custom_cookbooks"|"execute_recipes"|"configure"|"setup"|"deploy"|"rollback"|"start"|"stop"|"restart"|"undeploy", Args?: record}
  --comment: string # A user-defined comment.
  --custom-json: string # A string that contains user-defined, custom JSON. You can use this parameter to override some corresponding default stack configuration JSON values. The string should be in the following format: "{\"key1\": \"value1\", \"key2\": \"value2\",...}" For more information about custom JSON, see Use Custom JSON to Modify the Stack Configuration Attributes (https://docs.aws.amazon.com/opsworks/latest/userguide/workingstacks-json.html) and Overriding Attributes With Custom JSON (https://docs.aws.amazon.com/opsworks/latest/userguide/workingcookbook-json-override.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.CreateDeployment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}, {name: AppId, var: app_id}, {name: InstanceIds, var: instance_ids}, {name: LayerIds, var: layer_ids}, {name: Command, var: command}, {name: Comment, var: comment}, {name: CustomJson, var: custom_json}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id, app_id: $app_id, instance_ids: $instance_ids, layer_ids: $layer_ids, command: $command, comment: $comment, custom_json: $custom_json
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an instance in a specified stack. For more information, see Adding an Instance to a Layer (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-add.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<InstanceId: string>
# operationId: CreateInstance
export def "create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  stack_id: string # The stack ID.
  layer_ids: list<string> # An array that contains the instance's layer IDs.
  instance_type: string # The instance type, such as t2.micro. For a list of supported instance types, open the stack in the console, choose Instances, and choose + Instance. The Size list contains the currently supported types. For more information, see Instance Families and Types (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html). The parameter values that you use to specify the various types are in the API Name column of the Available Instance Types table.
  --auto-scaling-type: string@auto-scaling-type-completer # For load-based or time-based instances, the type. Windows stacks can use only time-based instances.
  --hostname: string # The instance host name.
  --os: string # The instance's operating system, which must be set to one of the following. A supported Linux operating system: An Amazon Linux version, such as Amazon Linux 2018.03, Amazon Linux 2017.09, Amazon Linux 2017.03, Amazon Linux 2016.09, Amazon Linux 2016.03, Amazon Linux 2015.09, or Amazon Linux 2015.03. A supported Ubuntu operating system, such as Ubuntu 16.04 LTS, Ubuntu 14.04 LTS, or Ubuntu 12.04 LTS. CentOS Linux 7 Red Hat Enterprise Linux 7 A supported Windows operating system, such as Microsoft Windows Server 2012 R2 Base, Microsoft Windows Server 2012 R2 with SQL Server Express, Microsoft Windows Server 2012 R2 with SQL Server Standard, or Microsoft Windows Server 2012 R2 with SQL Server Web. A custom AMI: Custom. For more information about the supported operating systems, see AWS OpsWorks Stacks Operating Systems (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-os.html). The default option is the current Amazon Linux version. If you set this parameter to Custom, you must use the CreateInstance action's AmiId parameter to specify the custom AMI that you want to use. Block device mappings are not supported if the value is Custom. For more information about supported operating systems, see Operating Systems (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-os.html)For more information about how to use custom AMIs with AWS OpsWorks Stacks, see Using Custom AMIs (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-custom-ami.html).
  --ami-id: string # A custom AMI ID to be used to create the instance. The AMI should be based on one of the supported operating systems. For more information, see Using Custom AMIs (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-custom-ami.html). If you specify a custom AMI, you must set Os to Custom.
  --ssh-key-name: string # The instance's Amazon EC2 key-pair name.
  --availability-zone: string # The instance Availability Zone. For more information, see Regions and Endpoints (https://docs.aws.amazon.com/general/latest/gr/rande.html).
  --virtualization-type: string # The instance's virtualization type, paravirtual or hvm.
  --subnet-id: string # The ID of the instance's subnet. If the stack is running in a VPC, you can use this parameter to override the stack's default subnet ID value and direct AWS OpsWorks Stacks to launch the instance in a different subnet.
  --architecture: string@architecture-completer # The instance architecture. The default option is x86_64. Instance types do not necessarily support both architectures. For a list of the architectures that are supported by the different instance types, see Instance Families and Types (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html).
  --root-device-type: string@root-device-type-completer # The instance root device type. For more information, see Storage for the Root Device (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ComponentsAMIs.html#storage-for-the-root-device).
  --block-device-mappings: list # An array of BlockDeviceMapping objects that specify the instance's block devices. For more information, see Block Device Mapping (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/block-device-mapping-concepts.html). Note that block device mappings are not supported for custom AMIs. — item shape: {DeviceName?: string, NoDevice?: string, VirtualName?: string, Ebs?: record}
  --install-updates-on-boot: oneof<nothing, bool> # Whether to install operating system and package updates when the instance boots. The default value is true. To control when updates are installed, set this value to false. You must then update your instances manually by using CreateDeployment to run the update_dependencies stack command or by manually running yum (Amazon Linux) or apt-get (Ubuntu) on the instances. We strongly recommend using the default value of true to ensure that your instances have the latest security updates.
  --ebs-optimized: oneof<nothing, bool> # Whether to create an Amazon EBS-optimized instance.
  --agent-version: string # The default AWS OpsWorks Stacks agent version. You have the following options: INHERIT - Use the stack's default agent version setting. version_number - Use the specified agent version. This value overrides the stack's default setting. To update the agent version, edit the instance configuration and specify a new version. AWS OpsWorks Stacks then automatically installs that version on the instance. The default setting is INHERIT. To specify an agent version, you must use the complete version number, not the abbreviated number shown on the console. For a list of available agent version numbers, call DescribeAgentVersions. AgentVersion cannot be set to Chef 12.2.
  --tenancy: string # The instance's tenancy option. The default option is no tenancy, or if the instance is running in a VPC, inherit tenancy settings from the VPC. The following are valid values for this parameter: dedicated, default, or host. Because there are costs associated with changes in tenancy options, we recommend that you research tenancy options before choosing them for your instances. For more information about dedicated hosts, see Dedicated Hosts Overview (http://aws.amazon.com/ec2/dedicated-hosts/) and Amazon EC2 Dedicated Hosts (http://aws.amazon.com/ec2/dedicated-hosts/). For more information about dedicated instances, see Dedicated Instances (https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/dedicated-instance.html) and Amazon EC2 Dedicated Instances (http://aws.amazon.com/ec2/purchasing-options/dedicated-instances/).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.CreateInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}, {name: LayerIds, var: layer_ids}, {name: InstanceType, var: instance_type}, {name: AutoScalingType, var: auto_scaling_type}, {name: Hostname, var: hostname}, {name: Os, var: os}, {name: AmiId, var: ami_id}, {name: SshKeyName, var: ssh_key_name}, {name: AvailabilityZone, var: availability_zone}, {name: VirtualizationType, var: virtualization_type}, {name: SubnetId, var: subnet_id}, {name: Architecture, var: architecture}, {name: RootDeviceType, var: root_device_type}, {name: BlockDeviceMappings, var: block_device_mappings}, {name: InstallUpdatesOnBoot, var: install_updates_on_boot}, {name: EbsOptimized, var: ebs_optimized}, {name: AgentVersion, var: agent_version}, {name: Tenancy, var: tenancy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id, layer_ids: $layer_ids, instance_type: $instance_type, auto_scaling_type: $auto_scaling_type, hostname: $hostname, os: $os, ami_id: $ami_id, ssh_key_name: $ssh_key_name, availability_zone: $availability_zone, virtualization_type: $virtualization_type, subnet_id: $subnet_id, architecture: $architecture, root_device_type: $root_device_type, block_device_mappings: $block_device_mappings, install_updates_on_boot: $install_updates_on_boot, ebs_optimized: $ebs_optimized, agent_version: $agent_version, tenancy: $tenancy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a layer. For more information, see How to Create a Layer (https://docs.aws.amazon.com/opsworks/latest/userguide/workinglayers-basics-create.html). You should use CreateLayer for noncustom layer types such as PHP App Server only if the stack does not have an existing layer of that type. A stack can have at most one instance of each noncustom layer; if you attempt to create a second instance, CreateLayer fails. A stack can have an arbitrary number of custom layers, so you can call CreateLayer as many times as you like for that layer type. Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<LayerId: string>
# operationId: CreateLayer
export def "create-layer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  stack_id: string # The layer stack ID.
  type: string@type-completer-1 # The layer type. A stack cannot have more than one built-in layer of the same type. It can have any number of custom layers. Built-in layers are not available in Chef 12 stacks.
  name: string # The layer name, which is used by the console.
  shortname: string # For custom layers only, use this parameter to specify the layer's short name, which is used internally by AWS OpsWorks Stacks and by Chef recipes. The short name is also used as the name for the directory where your app files are installed. It can have a maximum of 200 characters, which are limited to the alphanumeric characters, '-', '_', and '.'. The built-in layers' short names are defined by AWS OpsWorks Stacks. For more information, see the Layer Reference (https://docs.aws.amazon.com/opsworks/latest/userguide/layers.html).
  --attributes: record # One or more user-defined key-value pairs to be added to the stack attributes. To create a cluster layer, set the EcsClusterArn attribute to the cluster's ARN.
  --cloud-watch-logs-configuration: record # Describes the Amazon CloudWatch logs configuration for a layer. — shape: {Enabled?: bool, LogStreams?: list}
  --custom-instance-profile-arn: string # The ARN of an IAM profile to be used for the layer's EC2 instances. For more information about IAM ARNs, see Using Identifiers (https://docs.aws.amazon.com/IAM/latest/UserGuide/Using_Identifiers.html).
  --custom-json: string # A JSON-formatted string containing custom stack configuration and deployment attributes to be installed on the layer's instances. For more information, see Using Custom JSON (https://docs.aws.amazon.com/opsworks/latest/userguide/workingcookbook-json-override.html). This feature is supported as of version 1.7.42 of the AWS CLI.
  --custom-security-group-ids: list<string> # An array containing the layer custom security group IDs.
  --packages: list<string> # An array of Package objects that describes the layer packages.
  --volume-configurations: list # A VolumeConfigurations object that describes the layer's Amazon EBS volumes. — item shape: {MountPoint: string, RaidLevel?: int, NumberOfDisks: int, Size: int, VolumeType?: string, Iops?: int, Encrypted?: bool}
  --enable-auto-healing: oneof<nothing, bool> # Whether to disable auto healing for the layer.
  --auto-assign-elastic-ips: oneof<nothing, bool> # Whether to automatically assign an Elastic IP address (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html) to the layer's instances. For more information, see How to Edit a Layer (https://docs.aws.amazon.com/opsworks/latest/userguide/workinglayers-basics-edit.html).
  --auto-assign-public-ips: oneof<nothing, bool> # For stacks that are running in a VPC, whether to automatically assign a public IP address to the layer's instances. For more information, see How to Edit a Layer (https://docs.aws.amazon.com/opsworks/latest/userguide/workinglayers-basics-edit.html).
  --custom-recipes: record # AWS OpsWorks Stacks supports five lifecycle events: setup, configuration, deploy, undeploy, and shutdown. For each layer, AWS OpsWorks Stacks runs a set of standard recipes for each event. In addition, you can provide custom recipes for any or all layers and events. AWS OpsWorks Stacks runs custom event recipes after the standard recipes. LayerCustomRecipes specifies the custom recipes for a particular layer to be run in response to each of the five events. To specify a recipe, use the cookbook's directory name in the repository followed by two colons and the recipe name, which is the recipe's file name without the .rb extension. For example: phpapp2::dbsetup specifies the dbsetup.rb recipe in the repository's phpapp2 folder. — shape: {Setup?: list<string>, Configure?: list<string>, Deploy?: list<string>, Undeploy?: list<string>, Shutdown?: list<string>}
  --install-updates-on-boot: oneof<nothing, bool> # Whether to install operating system and package updates when the instance boots. The default value is true. To control when updates are installed, set this value to false. You must then update your instances manually by using CreateDeployment to run the update_dependencies stack command or by manually running yum (Amazon Linux) or apt-get (Ubuntu) on the instances. To ensure that your instances have the latest security updates, we strongly recommend using the default value of true.
  --use-ebs-optimized-instances: oneof<nothing, bool> # Whether to use Amazon EBS-optimized instances.
  --lifecycle-event-configuration: record # Specifies the lifecycle event configuration — shape: {Shutdown?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.CreateLayer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}, {name: Type, var: type}, {name: Name, var: name}, {name: Shortname, var: shortname}, {name: Attributes, var: attributes}, {name: CloudWatchLogsConfiguration, var: cloud_watch_logs_configuration}, {name: CustomInstanceProfileArn, var: custom_instance_profile_arn}, {name: CustomJson, var: custom_json}, {name: CustomSecurityGroupIds, var: custom_security_group_ids}, {name: Packages, var: packages}, {name: VolumeConfigurations, var: volume_configurations}, {name: EnableAutoHealing, var: enable_auto_healing}, {name: AutoAssignElasticIps, var: auto_assign_elastic_ips}, {name: AutoAssignPublicIps, var: auto_assign_public_ips}, {name: CustomRecipes, var: custom_recipes}, {name: InstallUpdatesOnBoot, var: install_updates_on_boot}, {name: UseEbsOptimizedInstances, var: use_ebs_optimized_instances}, {name: LifecycleEventConfiguration, var: lifecycle_event_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id, type: $type, name: $name, shortname: $shortname, attributes: $attributes, cloud_watch_logs_configuration: $cloud_watch_logs_configuration, custom_instance_profile_arn: $custom_instance_profile_arn, custom_json: $custom_json, custom_security_group_ids: $custom_security_group_ids, packages: $packages, volume_configurations: $volume_configurations, enable_auto_healing: $enable_auto_healing, auto_assign_elastic_ips: $auto_assign_elastic_ips, auto_assign_public_ips: $auto_assign_public_ips, custom_recipes: $custom_recipes, install_updates_on_boot: $install_updates_on_boot, use_ebs_optimized_instances: $use_ebs_optimized_instances, lifecycle_event_configuration: $lifecycle_event_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new stack. For more information, see Create a New Stack (https://docs.aws.amazon.com/opsworks/latest/userguide/workingstacks-edit.html). Required Permissions: To use this action, an IAM user must have an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<StackId: string>
# operationId: CreateStack
export def "create-stack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The stack name.
  region: string # The stack's AWS region, such as ap-south-1. For more information about Amazon regions, see Regions and Endpoints (https://docs.aws.amazon.com/general/latest/gr/rande.html). In the AWS CLI, this API maps to the --stack-region parameter. If the --stack-region parameter and the AWS CLI common parameter --region are set to the same value, the stack uses a regional endpoint. If the --stack-region parameter is not set, but the AWS CLI --region parameter is, this also results in a stack with a regional endpoint. However, if the --region parameter is set to us-east-1, and the --stack-region parameter is set to one of the following, then the stack uses a legacy or classic region: us-west-1, us-west-2, sa-east-1, eu-central-1, eu-west-1, ap-northeast-1, ap-southeast-1, ap-southeast-2. In this case, the actual API endpoint of the stack is in us-east-1. Only the preceding regions are supported as classic regions in the us-east-1 API endpoint. Because it is a best practice to choose the regional endpoint that is closest to where you manage AWS, we recommend that you use regional endpoints for new stacks. The AWS CLI common --region parameter always specifies a regional API endpoint; it cannot be used to specify a classic AWS OpsWorks Stacks region.
  --vpc-id: string # The ID of the VPC that the stack is to be launched into. The VPC must be in the stack's region. All instances are launched into this VPC. You cannot change the ID later. If your account supports EC2-Classic, the default value is no VPC. If your account does not support EC2-Classic, the default value is the default VPC for the specified region. If the VPC ID corresponds to a default VPC and you have specified either the DefaultAvailabilityZone or the DefaultSubnetId parameter only, AWS OpsWorks Stacks infers the value of the other parameter. If you specify neither parameter, AWS OpsWorks Stacks sets these parameters to the first valid Availability Zone for the specified region and the corresponding default VPC subnet ID, respectively. If you specify a nondefault VPC ID, note the following: It must belong to a VPC in your account that is in the specified region. You must specify a value for DefaultSubnetId. For more information about how to use AWS OpsWorks Stacks with a VPC, see Running a Stack in a VPC (https://docs.aws.amazon.com/opsworks/latest/userguide/workingstacks-vpc.html). For more information about default VPC and EC2-Classic, see Supported Platforms (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-supported-platforms.html).
  --attributes: record # One or more user-defined key-value pairs to be added to the stack attributes.
  service_role_arn: string # The stack's AWS Identity and Access Management (IAM) role, which allows AWS OpsWorks Stacks to work with AWS resources on your behalf. You must set this parameter to the Amazon Resource Name (ARN) for an existing IAM role. For more information about IAM ARNs, see Using Identifiers (https://docs.aws.amazon.com/IAM/latest/UserGuide/Using_Identifiers.html).
  default_instance_profile_arn: string # The Amazon Resource Name (ARN) of an IAM profile that is the default profile for all of the stack's EC2 instances. For more information about IAM ARNs, see Using Identifiers (https://docs.aws.amazon.com/IAM/latest/UserGuide/Using_Identifiers.html).
  --default-os: string # The stack's default operating system, which is installed on every instance unless you specify a different operating system when you create the instance. You can specify one of the following. A supported Linux operating system: An Amazon Linux version, such as Amazon Linux 2018.03, Amazon Linux 2017.09, Amazon Linux 2017.03, Amazon Linux 2016.09, Amazon Linux 2016.03, Amazon Linux 2015.09, or Amazon Linux 2015.03. A supported Ubuntu operating system, such as Ubuntu 16.04 LTS, Ubuntu 14.04 LTS, or Ubuntu 12.04 LTS. CentOS Linux 7 Red Hat Enterprise Linux 7 A supported Windows operating system, such as Microsoft Windows Server 2012 R2 Base, Microsoft Windows Server 2012 R2 with SQL Server Express, Microsoft Windows Server 2012 R2 with SQL Server Standard, or Microsoft Windows Server 2012 R2 with SQL Server Web. A custom AMI: Custom. You specify the custom AMI you want to use when you create instances. For more information, see Using Custom AMIs (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-custom-ami.html). The default option is the current Amazon Linux version. For more information about supported operating systems, see AWS OpsWorks Stacks Operating Systems (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-os.html).
  --hostname-theme: string # The stack's host name theme, with spaces replaced by underscores. The theme is used to generate host names for the stack's instances. By default, HostnameTheme is set to Layer_Dependent, which creates host names by appending integers to the layer's short name. The other themes are: Baked_Goods Clouds Europe_Cities Fruits Greek_Deities_and_Titans Legendary_creatures_from_Japan Planets_and_Moons Roman_Deities Scottish_Islands US_Cities Wild_Cats To obtain a generated host name, call GetHostNameSuggestion, which returns a host name based on the current theme.
  --default-availability-zone: string # The stack's default Availability Zone, which must be in the specified region. For more information, see Regions and Endpoints (https://docs.aws.amazon.com/general/latest/gr/rande.html). If you also specify a value for DefaultSubnetId, the subnet must be in the same zone. For more information, see the VpcId parameter description.
  --default-subnet-id: string # The stack's default VPC subnet ID. This parameter is required if you specify a value for the VpcId parameter. All instances are launched into this subnet unless you specify otherwise when you create the instance. If you also specify a value for DefaultAvailabilityZone, the subnet must be in that zone. For information on default values and when this parameter is required, see the VpcId parameter description.
  --custom-json: string # A string that contains user-defined, custom JSON. It can be used to override the corresponding default stack configuration attribute values or to pass data to recipes. The string should be in the following format: "{\"key1\": \"value1\", \"key2\": \"value2\",...}" For more information about custom JSON, see Use Custom JSON to Modify the Stack Configuration Attributes (https://docs.aws.amazon.com/opsworks/latest/userguide/workingstacks-json.html).
  --configuration-manager: record # Describes the configuration manager. — shape: {Name?: string, Version?: string}
  --chef-configuration: record # Describes the Chef configuration. — shape: {ManageBerkshelf?: bool, BerkshelfVersion?: string}
  --use-custom-cookbooks: oneof<nothing, bool> # Whether the stack uses custom cookbooks.
  --use-opsworks-security-groups: oneof<nothing, bool> # Whether to associate the AWS OpsWorks Stacks built-in security groups with the stack's layers. AWS OpsWorks Stacks provides a standard set of built-in security groups, one for each layer, which are associated with layers by default. With UseOpsworksSecurityGroups you can instead provide your own custom security groups. UseOpsworksSecurityGroups has the following settings: True - AWS OpsWorks Stacks automatically associates the appropriate built-in security group with each layer (default setting). You can associate additional security groups with a layer after you create it, but you cannot delete the built-in security group. False - AWS OpsWorks Stacks does not associate built-in security groups with layers. You must create appropriate EC2 security groups and associate a security group with each layer that you create. However, you can still manually associate a built-in security group with a layer on creation; custom security groups are required only for those layers that need custom settings. For more information, see Create a New Stack (https://docs.aws.amazon.com/opsworks/latest/userguide/workingstacks-creating.html).
  --custom-cookbooks-source: record # Contains the information required to retrieve an app or cookbook from a repository. For more information, see Creating Apps (https://docs.aws.amazon.com/opsworks/latest/userguide/workingapps-creating.html) or Custom Recipes and Cookbooks (https://docs.aws.amazon.com/opsworks/latest/userguide/workingcookbook.html). — shape: {Type?: "git"|"svn"|"archive"|"s3", Url?: string, Username?: string, Password?: string, SshKey?: string, Revision?: string}
  --default-ssh-key-name: string # A default Amazon EC2 key pair name. The default value is none. If you specify a key pair name, AWS OpsWorks installs the public key on the instance and you can use the private key with an SSH client to log in to the instance. For more information, see Using SSH to Communicate with an Instance (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-ssh.html) and Managing SSH Access (https://docs.aws.amazon.com/opsworks/latest/userguide/security-ssh-access.html). You can override this setting by specifying a different key pair, or no key pair, when you create an instance (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-add.html).
  --default-root-device-type: string@default-root-device-type-completer # The default root device type. This value is the default for all instances in the stack, but you can override it when you create an instance. The default option is instance-store. For more information, see Storage for the Root Device (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ComponentsAMIs.html#storage-for-the-root-device).
  --agent-version: string # The default AWS OpsWorks Stacks agent version. You have the following options: Auto-update - Set this parameter to LATEST. AWS OpsWorks Stacks automatically installs new agent versions on the stack's instances as soon as they are available. Fixed version - Set this parameter to your preferred agent version. To update the agent version, you must edit the stack configuration and specify a new version. AWS OpsWorks Stacks then automatically installs that version on the stack's instances. The default setting is the most recent release of the agent. To specify an agent version, you must use the complete version number, not the abbreviated number shown on the console. For a list of available agent version numbers, call DescribeAgentVersions. AgentVersion cannot be set to Chef 12.2. You can also specify an agent version when you create or update an instance, which overrides the stack's default setting.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.CreateStack"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Region, var: region}, {name: VpcId, var: vpc_id}, {name: Attributes, var: attributes}, {name: ServiceRoleArn, var: service_role_arn}, {name: DefaultInstanceProfileArn, var: default_instance_profile_arn}, {name: DefaultOs, var: default_os}, {name: HostnameTheme, var: hostname_theme}, {name: DefaultAvailabilityZone, var: default_availability_zone}, {name: DefaultSubnetId, var: default_subnet_id}, {name: CustomJson, var: custom_json}, {name: ConfigurationManager, var: configuration_manager}, {name: ChefConfiguration, var: chef_configuration}, {name: UseCustomCookbooks, var: use_custom_cookbooks}, {name: UseOpsworksSecurityGroups, var: use_opsworks_security_groups}, {name: CustomCookbooksSource, var: custom_cookbooks_source}, {name: DefaultSshKeyName, var: default_ssh_key_name}, {name: DefaultRootDeviceType, var: default_root_device_type}, {name: AgentVersion, var: agent_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, region: $region, vpc_id: $vpc_id, attributes: $attributes, service_role_arn: $service_role_arn, default_instance_profile_arn: $default_instance_profile_arn, default_os: $default_os, hostname_theme: $hostname_theme, default_availability_zone: $default_availability_zone, default_subnet_id: $default_subnet_id, custom_json: $custom_json, configuration_manager: $configuration_manager, chef_configuration: $chef_configuration, use_custom_cookbooks: $use_custom_cookbooks, use_opsworks_security_groups: $use_opsworks_security_groups, custom_cookbooks_source: $custom_cookbooks_source, default_ssh_key_name: $default_ssh_key_name, default_root_device_type: $default_root_device_type, agent_version: $agent_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new user profile. Required Permissions: To use this action, an IAM user must have an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<IamUserArn: string>
# operationId: CreateUserProfile
export def "create-user-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  iam_user_arn: string # The user's IAM ARN; this can also be a federated user's ARN.
  --ssh-username: string # The user's SSH user name. The allowable characters are [a-z], [A-Z], [0-9], '-', and '_'. If the specified name includes other punctuation marks, AWS OpsWorks Stacks removes them. For example, my.name will be changed to myname. If you do not specify an SSH user name, AWS OpsWorks Stacks generates one from the IAM user name.
  --ssh-public-key: string # The user's public SSH key.
  --allow-self-management: oneof<nothing, bool> # Whether users can specify their own SSH public key through the My Settings page. For more information, see Setting an IAM User's Public SSH Key (https://docs.aws.amazon.com/opsworks/latest/userguide/security-settingsshkey.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.CreateUserProfile"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IamUserArn, var: iam_user_arn}, {name: SshUsername, var: ssh_username}, {name: SshPublicKey, var: ssh_public_key}, {name: AllowSelfManagement, var: allow_self_management}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, iam_user_arn: $iam_user_arn, ssh_username: $ssh_username, ssh_public_key: $ssh_public_key, allow_self_management: $allow_self_management
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specified app. Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: DeleteApp
export def "delete-app" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  app_id: string # The app ID.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DeleteApp"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AppId, var: app_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specified instance, which terminates the associated Amazon EC2 instance. You must stop an instance before you can delete it. For more information, see Deleting Instances (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-delete.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: DeleteInstance
export def "delete-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_id: string # The instance ID.
  --delete-elastic-ip: oneof<nothing, bool> # Whether to delete the instance Elastic IP address.
  --delete-volumes: oneof<nothing, bool> # Whether to delete the instance's Amazon EBS volumes.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DeleteInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: DeleteElasticIp, var: delete_elastic_ip}, {name: DeleteVolumes, var: delete_volumes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id, delete_elastic_ip: $delete_elastic_ip, delete_volumes: $delete_volumes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specified layer. You must first stop and then delete all associated instances or unassign registered instances. For more information, see How to Delete a Layer (https://docs.aws.amazon.com/opsworks/latest/userguide/workinglayers-basics-delete.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: DeleteLayer
export def "delete-layer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  layer_id: string # The layer ID.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DeleteLayer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LayerId, var: layer_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, layer_id: $layer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specified stack. You must first delete all instances, layers, and apps or deregister registered instances. For more information, see Shut Down a Stack (https://docs.aws.amazon.com/opsworks/latest/userguide/workingstacks-shutting.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: DeleteStack
export def "delete-stack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  stack_id: string # The stack ID.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DeleteStack"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a user profile. Required Permissions: To use this action, an IAM user must have an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: DeleteUserProfile
export def "delete-user-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  iam_user_arn: string # The user's IAM ARN. This can also be a federated user's ARN.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DeleteUserProfile"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IamUserArn, var: iam_user_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, iam_user_arn: $iam_user_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deregisters a specified Amazon ECS cluster from a stack. For more information, see Resource Management (https://docs.aws.amazon.com/opsworks/latest/userguide/workinglayers-ecscluster.html#workinglayers-ecscluster-delete). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack or an attached policy that explicitly grants permissions. For more information on user permissions, see https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: DeregisterEcsCluster
export def "deregister-ecs-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  ecs_cluster_arn: string # The cluster's Amazon Resource Number (ARN).
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DeregisterEcsCluster"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EcsClusterArn, var: ecs_cluster_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ecs_cluster_arn: $ecs_cluster_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deregisters a specified Elastic IP address. The address can then be registered by another stack. For more information, see Resource Management (https://docs.aws.amazon.com/opsworks/latest/userguide/resources.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: DeregisterElasticIp
export def "deregister-elastic-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  elastic_ip: string # The Elastic IP address.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DeregisterElasticIp"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ElasticIp, var: elastic_ip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, elastic_ip: $elastic_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deregister a registered Amazon EC2 or on-premises instance. This action removes the instance from the stack and returns it to your control. This action cannot be used with instances that were created with AWS OpsWorks Stacks. Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  instance_id: string # The instance ID.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DeregisterInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deregisters an Amazon RDS instance. Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: DeregisterRdsDbInstance
export def "deregister-rds-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  rds_db_instance_arn: string # The Amazon RDS instance's ARN.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DeregisterRdsDbInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: RdsDbInstanceArn, var: rds_db_instance_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, rds_db_instance_arn: $rds_db_instance_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deregisters an Amazon EBS volume. The volume can then be registered by another stack. For more information, see Resource Management (https://docs.aws.amazon.com/opsworks/latest/userguide/resources.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: DeregisterVolume
export def "deregister-volume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  volume_id: string # The AWS OpsWorks Stacks volume ID, which is the GUID that AWS OpsWorks Stacks assigned to the instance when you registered the volume with the stack, not the Amazon EC2 volume ID.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DeregisterVolume"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VolumeId, var: volume_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, volume_id: $volume_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the available AWS OpsWorks Stacks agent versions. You must specify a stack ID or a configuration manager. DescribeAgentVersions returns a list of available agent versions for the specified stack or configuration manager.
#
# POST /
# Returns: record<AgentVersions: table<Version: string, ConfigurationManager: record>>
# operationId: DescribeAgentVersions
export def "describe-agent-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --stack-id: string # The stack ID.
  --configuration-manager: record # Describes the configuration manager. — shape: {Name?: string, Version?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeAgentVersions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}, {name: ConfigurationManager, var: configuration_manager}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id, configuration_manager: $configuration_manager
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests a description of a specified set of apps. This call accepts only one resource-identifying parameter. Required Permissions: To use this action, an IAM user must have a Show, Deploy, or Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<Apps: table<AppId: string, StackId: string, Shortname: string, Name: string, Description: string, DataSources: list, Type: string, AppSource: record, Domains: list, EnableSsl: bool, SslConfiguration: record, Attributes: record, CreatedAt: string, Environment: list>>
# operationId: DescribeApps
export def "describe-apps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --stack-id: string # The app stack ID. If you use this parameter, DescribeApps returns a description of the apps in the specified stack.
  --app-ids: list<string> # An array of app IDs for the apps to be described. If you use this parameter, DescribeApps returns a description of the specified apps. Otherwise, it returns a description of every app.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeApps"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}, {name: AppIds, var: app_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id, app_ids: $app_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the results of specified commands. This call accepts only one resource-identifying parameter. Required Permissions: To use this action, an IAM user must have a Show, Deploy, or Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<Commands: table<CommandId: string, InstanceId: string, DeploymentId: string, CreatedAt: string, AcknowledgedAt: string, CompletedAt: string, Status: string, ExitCode: int, LogUrl: string, Type: string>>
# operationId: DescribeCommands
export def "describe-commands" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --deployment-id: string # The deployment ID. If you include this parameter, DescribeCommands returns a description of the commands associated with the specified deployment.
  --instance-id: string # The instance ID. If you include this parameter, DescribeCommands returns a description of the commands associated with the specified instance.
  --command-ids: list<string> # An array of command IDs. If you include this parameter, DescribeCommands returns a description of the specified commands. Otherwise, it returns a description of every command.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeCommands"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DeploymentId, var: deployment_id}, {name: InstanceId, var: instance_id}, {name: CommandIds, var: command_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deployment_id: $deployment_id, instance_id: $instance_id, command_ids: $command_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests a description of a specified set of deployments. This call accepts only one resource-identifying parameter. Required Permissions: To use this action, an IAM user must have a Show, Deploy, or Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<Deployments: table<DeploymentId: string, StackId: string, AppId: string, CreatedAt: string, CompletedAt: string, Duration: int, IamUserArn: string, Comment: string, Command: record, Status: string, CustomJson: string, InstanceIds: list>>
# operationId: DescribeDeployments
export def "describe-deployments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --stack-id: string # The stack ID. If you include this parameter, the command returns a description of the commands associated with the specified stack.
  --app-id: string # The app ID. If you include this parameter, the command returns a description of the commands associated with the specified app.
  --deployment-ids: list<string> # An array of deployment IDs to be described. If you include this parameter, the command returns a description of the specified deployments. Otherwise, it returns a description of every deployment.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeDeployments"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}, {name: AppId, var: app_id}, {name: DeploymentIds, var: deployment_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id, app_id: $app_id, deployment_ids: $deployment_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes Amazon ECS clusters that are registered with a stack. If you specify only a stack ID, you can use the MaxResults and NextToken parameters to paginate the response. However, AWS OpsWorks Stacks currently supports only one cluster per layer, so the result set has a maximum of one element. Required Permissions: To use this action, an IAM user must have a Show, Deploy, or Manage permissions level for the stack or an attached policy that explicitly grants permission. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html). This call accepts only one resource-identifying parameter.
#
# POST /
# Returns: record<EcsClusters: table<EcsClusterArn: string, EcsClusterName: string, StackId: string, RegisteredAt: string>, NextToken: string>
# operationId: DescribeEcsClusters
export def "describe-ecs-clusters" [
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
  --x-amz-target: string@x-amz-target-completer-25 # required
  --ecs-cluster-arns: list<string> # A list of ARNs, one for each cluster to be described.
  --stack-id: string # A stack ID. DescribeEcsClusters returns a description of the cluster that is registered with the stack.
  --body-next-token: string # If the previous paginated request did not return all of the remaining results, the response object'sNextToken parameter value is set to a token. To retrieve the next set of results, call DescribeEcsClusters again and assign that token to the request object's NextToken parameter. If there are no remaining results, the previous response object's NextToken parameter is set to null. (spec name: NextToken)
  --body-max-results: int # To receive a paginated response, use this parameter to specify the maximum number of results to be returned with a single call. If the number of available results exceeds this maximum, the response includes a NextToken value that you can assign to the NextToken request parameter to get the next set of results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeEcsClusters"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EcsClusterArns, var: ecs_cluster_arns}, {name: StackId, var: stack_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ecs_cluster_arns: $ecs_cluster_arns, stack_id: $stack_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes Elastic IP addresses (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html). This call accepts only one resource-identifying parameter. Required Permissions: To use this action, an IAM user must have a Show, Deploy, or Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<ElasticIps: table<Ip: string, Name: string, Domain: string, Region: string, InstanceId: string>>
# operationId: DescribeElasticIps
export def "describe-elastic-ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --instance-id: string # The instance ID. If you include this parameter, DescribeElasticIps returns a description of the Elastic IP addresses associated with the specified instance.
  --stack-id: string # A stack ID. If you include this parameter, DescribeElasticIps returns a description of the Elastic IP addresses that are registered with the specified stack.
  --ips: list<string> # An array of Elastic IP addresses to be described. If you include this parameter, DescribeElasticIps returns a description of the specified Elastic IP addresses. Otherwise, it returns a description of every Elastic IP address.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeElasticIps"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: StackId, var: stack_id}, {name: Ips, var: ips}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id, stack_id: $stack_id, ips: $ips
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a stack's Elastic Load Balancing instances. This call accepts only one resource-identifying parameter. Required Permissions: To use this action, an IAM user must have a Show, Deploy, or Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<ElasticLoadBalancers: table<ElasticLoadBalancerName: string, Region: string, DnsName: string, StackId: string, LayerId: string, VpcId: string, AvailabilityZones: list, SubnetIds: list, Ec2InstanceIds: list>>
# operationId: DescribeElasticLoadBalancers
export def "describe-elastic-load-balancers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --stack-id: string # A stack ID. The action describes the stack's Elastic Load Balancing instances.
  --layer-ids: list<string> # A list of layer IDs. The action describes the Elastic Load Balancing instances for the specified layers.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeElasticLoadBalancers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}, {name: LayerIds, var: layer_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id, layer_ids: $layer_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests a description of a set of instances. This call accepts only one resource-identifying parameter. Required Permissions: To use this action, an IAM user must have a Show, Deploy, or Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<Instances: table<AgentVersion: string, AmiId: string, Architecture: string, Arn: string, AutoScalingType: string, AvailabilityZone: string, BlockDeviceMappings: list, CreatedAt: string, EbsOptimized: bool, Ec2InstanceId: string, EcsClusterArn: string, EcsContainerInstanceArn: string, ElasticIp: string, Hostname: string, InfrastructureClass: string, InstallUpdatesOnBoot: bool, InstanceId: string, InstanceProfileArn: string, InstanceType: string, LastServiceErrorId: string, LayerIds: list, Os: string, Platform: string, PrivateDns: string, PrivateIp: string, PublicDns: string, PublicIp: string, RegisteredBy: string, ReportedAgentVersion: string, ReportedOs: record, RootDeviceType: string, RootDeviceVolumeId: string, SecurityGroupIds: list, SshHostDsaKeyFingerprint: string, SshHostRsaKeyFingerprint: string, SshKeyName: string, StackId: string, Status: string, SubnetId: string, Tenancy: string, VirtualizationType: string>>
# operationId: DescribeInstances
export def "describe-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --stack-id: string # A stack ID. If you use this parameter, DescribeInstances returns descriptions of the instances associated with the specified stack.
  --layer-id: string # A layer ID. If you use this parameter, DescribeInstances returns descriptions of the instances associated with the specified layer.
  --instance-ids: list<string> # An array of instance IDs to be described. If you use this parameter, DescribeInstances returns a description of the specified instances. Otherwise, it returns a description of every instance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeInstances"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}, {name: LayerId, var: layer_id}, {name: InstanceIds, var: instance_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id, layer_id: $layer_id, instance_ids: $instance_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests a description of one or more layers in a specified stack. This call accepts only one resource-identifying parameter. Required Permissions: To use this action, an IAM user must have a Show, Deploy, or Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<Layers: table<Arn: string, StackId: string, LayerId: string, Type: string, Name: string, Shortname: string, Attributes: record, CloudWatchLogsConfiguration: record, CustomInstanceProfileArn: string, CustomJson: string, CustomSecurityGroupIds: list, DefaultSecurityGroupNames: list, Packages: list, VolumeConfigurations: list, EnableAutoHealing: bool, AutoAssignElasticIps: bool, AutoAssignPublicIps: bool, DefaultRecipes: record, CustomRecipes: record, CreatedAt: string, InstallUpdatesOnBoot: bool, UseEbsOptimizedInstances: bool, LifecycleEventConfiguration: record>>
# operationId: DescribeLayers
export def "describe-layers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --stack-id: string # The stack ID.
  --layer-ids: list<string> # An array of layer IDs that specify the layers to be described. If you omit this parameter, DescribeLayers returns a description of every layer in the specified stack.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeLayers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}, {name: LayerIds, var: layer_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id, layer_ids: $layer_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes load-based auto scaling configurations for specified layers. You must specify at least one of the parameters. Required Permissions: To use this action, an IAM user must have a Show, Deploy, or Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<LoadBasedAutoScalingConfigurations: table<LayerId: string, Enable: bool, UpScaling: record, DownScaling: record>>
# operationId: DescribeLoadBasedAutoScaling
export def "describe-load-based-auto-scaling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  layer_ids: list<string> # An array of layer IDs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeLoadBasedAutoScaling"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LayerIds, var: layer_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, layer_ids: $layer_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a user's SSH information. Required Permissions: To use this action, an IAM user must have self-management enabled or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<UserProfile: record<IamUserArn: string, Name: string, SshUsername: string, SshPublicKey: string>>
# operationId: DescribeMyUserProfile
export def "describe-my-user-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeMyUserProfile"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the operating systems that are supported by AWS OpsWorks Stacks.
#
# POST /
# Returns: record<OperatingSystems: table<Name: string, Id: string, Type: string, ConfigurationManagers: list, ReportedName: string, ReportedVersion: string, Supported: bool>>
# operationId: DescribeOperatingSystems
export def "describe-operating-systems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeOperatingSystems"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the permissions for a specified stack. Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<Permissions: table<StackId: string, IamUserArn: string, AllowSsh: bool, AllowSudo: bool, Level: string>>
# operationId: DescribePermissions
export def "describe-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --iam-user-arn: string # The user's IAM ARN. This can also be a federated user's ARN. For more information about IAM ARNs, see Using Identifiers (https://docs.aws.amazon.com/IAM/latest/UserGuide/Using_Identifiers.html).
  --stack-id: string # The stack ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribePermissions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IamUserArn, var: iam_user_arn}, {name: StackId, var: stack_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, iam_user_arn: $iam_user_arn, stack_id: $stack_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe an instance's RAID arrays. This call accepts only one resource-identifying parameter. Required Permissions: To use this action, an IAM user must have a Show, Deploy, or Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<RaidArrays: table<RaidArrayId: string, InstanceId: string, Name: string, RaidLevel: int, NumberOfDisks: int, Size: int, Device: string, MountPoint: string, AvailabilityZone: string, CreatedAt: string, StackId: string, VolumeType: string, Iops: int>>
# operationId: DescribeRaidArrays
export def "describe-raid-arrays" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --instance-id: string # The instance ID. If you use this parameter, DescribeRaidArrays returns descriptions of the RAID arrays associated with the specified instance.
  --stack-id: string # The stack ID.
  --raid-array-ids: list<string> # An array of RAID array IDs. If you use this parameter, DescribeRaidArrays returns descriptions of the specified arrays. Otherwise, it returns a description of every array.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeRaidArrays"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: StackId, var: stack_id}, {name: RaidArrayIds, var: raid_array_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id, stack_id: $stack_id, raid_array_ids: $raid_array_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes Amazon RDS instances. Required Permissions: To use this action, an IAM user must have a Show, Deploy, or Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html). This call accepts only one resource-identifying parameter.
#
# POST /
# Returns: record<RdsDbInstances: table<RdsDbInstanceArn: string, DbInstanceIdentifier: string, DbUser: string, DbPassword: string, Region: string, Address: string, Engine: string, StackId: string, MissingOnRds: bool>>
# operationId: DescribeRdsDbInstances
export def "describe-rds-db-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  stack_id: string # The ID of the stack with which the instances are registered. The operation returns descriptions of all registered Amazon RDS instances.
  --rds-db-instance-arns: list<string> # An array containing the ARNs of the instances to be described.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeRdsDbInstances"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}, {name: RdsDbInstanceArns, var: rds_db_instance_arns}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id, rds_db_instance_arns: $rds_db_instance_arns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes AWS OpsWorks Stacks service errors. Required Permissions: To use this action, an IAM user must have a Show, Deploy, or Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html). This call accepts only one resource-identifying parameter.
#
# POST /
# Returns: record<ServiceErrors: table<ServiceErrorId: string, StackId: string, InstanceId: string, Type: string, Message: string, CreatedAt: string>>
# operationId: DescribeServiceErrors
export def "describe-service-errors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --stack-id: string # The stack ID. If you use this parameter, DescribeServiceErrors returns descriptions of the errors associated with the specified stack.
  --instance-id: string # The instance ID. If you use this parameter, DescribeServiceErrors returns descriptions of the errors associated with the specified instance.
  --service-error-ids: list<string> # An array of service error IDs. If you use this parameter, DescribeServiceErrors returns descriptions of the specified errors. Otherwise, it returns a description of every error.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeServiceErrors"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}, {name: InstanceId, var: instance_id}, {name: ServiceErrorIds, var: service_error_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id, instance_id: $instance_id, service_error_ids: $service_error_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests a description of a stack's provisioning parameters. Required Permissions: To use this action, an IAM user must have a Show, Deploy, or Manage permissions level for the stack or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<AgentInstallerUrl: string, Parameters: record>
# operationId: DescribeStackProvisioningParameters
export def "describe-stack-provisioning-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  stack_id: string # The stack ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeStackProvisioningParameters"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the number of layers and apps in a specified stack, and the number of instances in each state, such as running_setup or online. Required Permissions: To use this action, an IAM user must have a Show, Deploy, or Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<StackSummary: record<StackId: string, Name: string, Arn: string, LayersCount: int, AppsCount: int, InstancesCount: record<Assigning: int, Booting: int, ConnectionLost: int, Deregistering: int, Online: int, Pending: int, Rebooting: int, Registered: int, Registering: int, Requested: int, RunningSetup: int, SetupFailed: int, ShuttingDown: int, StartFailed: int, StopFailed: int, Stopped: int, Stopping: int, Terminated: int, Terminating: int, Unassigning: int>>>
# operationId: DescribeStackSummary
export def "describe-stack-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  stack_id: string # The stack ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeStackSummary"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests a description of one or more stacks. Required Permissions: To use this action, an IAM user must have a Show, Deploy, or Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<Stacks: table<StackId: string, Name: string, Arn: string, Region: string, VpcId: string, Attributes: record, ServiceRoleArn: string, DefaultInstanceProfileArn: string, DefaultOs: string, HostnameTheme: string, DefaultAvailabilityZone: string, DefaultSubnetId: string, CustomJson: string, ConfigurationManager: record, ChefConfiguration: record, UseCustomCookbooks: bool, UseOpsworksSecurityGroups: bool, CustomCookbooksSource: record, DefaultSshKeyName: string, CreatedAt: string, DefaultRootDeviceType: string, AgentVersion: string>>
# operationId: DescribeStacks
export def "describe-stacks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --stack-ids: list<string> # An array of stack IDs that specify the stacks to be described. If you omit this parameter, DescribeStacks returns a description of every stack.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeStacks"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackIds, var: stack_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_ids: $stack_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes time-based auto scaling configurations for specified instances. You must specify at least one of the parameters. Required Permissions: To use this action, an IAM user must have a Show, Deploy, or Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<TimeBasedAutoScalingConfigurations: table<InstanceId: string, AutoScalingSchedule: record>>
# operationId: DescribeTimeBasedAutoScaling
export def "describe-time-based-auto-scaling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_ids: list<string> # An array of instance IDs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeTimeBasedAutoScaling"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceIds, var: instance_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_ids: $instance_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe specified users. Required Permissions: To use this action, an IAM user must have an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<UserProfiles: table<IamUserArn: string, Name: string, SshUsername: string, SshPublicKey: string, AllowSelfManagement: bool>>
# operationId: DescribeUserProfiles
export def "describe-user-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --iam-user-arns: list<string> # An array of IAM or federated user ARNs that identify the users to be described.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeUserProfiles"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IamUserArns, var: iam_user_arns}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, iam_user_arns: $iam_user_arns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an instance's Amazon EBS volumes. This call accepts only one resource-identifying parameter. Required Permissions: To use this action, an IAM user must have a Show, Deploy, or Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<Volumes: table<VolumeId: string, Ec2VolumeId: string, Name: string, RaidArrayId: string, InstanceId: string, Status: string, Size: int, Device: string, MountPoint: string, Region: string, AvailabilityZone: string, VolumeType: string, Iops: int, Encrypted: bool>>
# operationId: DescribeVolumes
export def "describe-volumes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --instance-id: string # The instance ID. If you use this parameter, DescribeVolumes returns descriptions of the volumes associated with the specified instance.
  --stack-id: string # A stack ID. The action describes the stack's registered Amazon EBS volumes.
  --raid-array-id: string # The RAID array ID. If you use this parameter, DescribeVolumes returns descriptions of the volumes associated with the specified RAID array.
  --volume-ids: list<string> # Am array of volume IDs. If you use this parameter, DescribeVolumes returns descriptions of the specified volumes. Otherwise, it returns a description of every volume.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DescribeVolumes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: StackId, var: stack_id}, {name: RaidArrayId, var: raid_array_id}, {name: VolumeIds, var: volume_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id, stack_id: $stack_id, raid_array_id: $raid_array_id, volume_ids: $volume_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detaches a specified Elastic Load Balancing instance from its layer. Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: DetachElasticLoadBalancer
export def "detach-elastic-load-balancer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  elastic_load_balancer_name: string # The Elastic Load Balancing instance's name.
  layer_id: string # The ID of the layer that the Elastic Load Balancing instance is attached to.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DetachElasticLoadBalancer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ElasticLoadBalancerName, var: elastic_load_balancer_name}, {name: LayerId, var: layer_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, elastic_load_balancer_name: $elastic_load_balancer_name, layer_id: $layer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates an Elastic IP address from its instance. The address remains registered with the stack. For more information, see Resource Management (https://docs.aws.amazon.com/opsworks/latest/userguide/resources.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: DisassociateElasticIp
export def "disassociate-elastic-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  elastic_ip: string # The Elastic IP address.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.DisassociateElasticIp"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ElasticIp, var: elastic_ip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, elastic_ip: $elastic_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a generated host name for the specified layer, based on the current host name theme. Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<LayerId: string, Hostname: string>
# operationId: GetHostnameSuggestion
export def "get-hostname-suggestion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-45 # required
  layer_id: string # The layer ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.GetHostnameSuggestion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LayerId, var: layer_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, layer_id: $layer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This action can be used only with Windows stacks. Grants RDP access to a Windows instance for a specified time period.
#
# POST /
# Returns: record<TemporaryCredential: record<Username: string, Password: string, ValidForInMinutes: int, InstanceId: string>>
# operationId: GrantAccess
export def "grant-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-46 # required
  instance_id: string # The instance's AWS OpsWorks Stacks ID.
  --valid-for-in-minutes: int # The length of time (in minutes) that the grant is valid. When the grant expires at the end of this period, the user will no longer be able to use the credentials to log in. If the user is logged in at the time, he or she automatically will be logged out.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.GrantAccess"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: ValidForInMinutes, var: valid_for_in_minutes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id, valid_for_in_minutes: $valid_for_in_minutes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of tags that are applied to the specified stack or layer.
#
# POST /
# Returns: record<Tags: record, NextToken: string>
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-47 # required
  resource_arn: string # The stack or layer's Amazon Resource Number (ARN).
  --max-results: int # Do not use. A validation exception occurs if you add a MaxResults parameter to a ListTagsRequest call.
  --next-token: string # Do not use. A validation exception occurs if you add a NextToken parameter to a ListTagsRequest call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.ListTags"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reboots a specified instance. For more information, see Starting, Stopping, and Rebooting Instances (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-starting.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: RebootInstance
export def "reboot-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_id: string # The instance ID.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.RebootInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a specified Amazon ECS cluster with a stack. You can register only one cluster with a stack. A cluster can be registered with only one stack. For more information, see Resource Management (https://docs.aws.amazon.com/opsworks/latest/userguide/workinglayers-ecscluster.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<EcsClusterArn: string>
# operationId: RegisterEcsCluster
export def "register-ecs-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-49 # required
  ecs_cluster_arn: string # The cluster's ARN.
  stack_id: string # The stack ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.RegisterEcsCluster"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EcsClusterArn, var: ecs_cluster_arn}, {name: StackId, var: stack_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ecs_cluster_arn: $ecs_cluster_arn, stack_id: $stack_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers an Elastic IP address with a specified stack. An address can be registered with only one stack at a time. If the address is already registered, you must first deregister it by calling DeregisterElasticIp. For more information, see Resource Management (https://docs.aws.amazon.com/opsworks/latest/userguide/resources.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<ElasticIp: string>
# operationId: RegisterElasticIp
export def "register-elastic-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  elastic_ip: string # The Elastic IP address.
  stack_id: string # The stack ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.RegisterElasticIp"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ElasticIp, var: elastic_ip}, {name: StackId, var: stack_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, elastic_ip: $elastic_ip, stack_id: $stack_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers instances that were created outside of AWS OpsWorks Stacks with a specified stack. We do not recommend using this action to register instances. The complete registration operation includes two tasks: installing the AWS OpsWorks Stacks agent on the instance, and registering the instance with the stack. RegisterInstance handles only the second step. You should instead use the AWS CLI register command, which performs the entire registration operation. For more information, see Registering an Instance with an AWS OpsWorks Stacks Stack (https://docs.aws.amazon.com/opsworks/latest/userguide/registered-instances-register.html). Registered instances have the same requirements as instances that are created by using the CreateInstance API. For example, registered instances must be running a supported Linux-based operating system, and they must have a supported instance type. For more information about requirements for instances that you want to register, see Preparing the Instance (https://docs.aws.amazon.com/opsworks/latest/userguide/registered-instances-register-registering-preparer.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<InstanceId: string>
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
  --x-amz-target: string@x-amz-target-completer-51 # required
  stack_id: string # The ID of the stack that the instance is to be registered with.
  --hostname: string # The instance's hostname.
  --public-ip: string # The instance's public IP address.
  --private-ip: string # The instance's private IP address.
  --rsa-public-key: string # The instances public RSA key. This key is used to encrypt communication between the instance and the service.
  --rsa-public-key-fingerprint: string # The instances public RSA key fingerprint.
  --instance-identity: record # Contains a description of an Amazon EC2 instance from the Amazon EC2 metadata service. For more information, see Instance Metadata and User Data (https://docs.aws.amazon.com/sdkfornet/latest/apidocs/Index.html). — shape: {Document?: string, Signature?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.RegisterInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}, {name: Hostname, var: hostname}, {name: PublicIp, var: public_ip}, {name: PrivateIp, var: private_ip}, {name: RsaPublicKey, var: rsa_public_key}, {name: RsaPublicKeyFingerprint, var: rsa_public_key_fingerprint}, {name: InstanceIdentity, var: instance_identity}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id, hostname: $hostname, public_ip: $public_ip, private_ip: $private_ip, rsa_public_key: $rsa_public_key, rsa_public_key_fingerprint: $rsa_public_key_fingerprint, instance_identity: $instance_identity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers an Amazon RDS instance with a stack. Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: RegisterRdsDbInstance
export def "register-rds-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  stack_id: string # The stack ID.
  rds_db_instance_arn: string # The Amazon RDS instance's ARN.
  db_user: string # The database's master user name.
  db_password: string # The database password.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.RegisterRdsDbInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}, {name: RdsDbInstanceArn, var: rds_db_instance_arn}, {name: DbUser, var: db_user}, {name: DbPassword, var: db_password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id, rds_db_instance_arn: $rds_db_instance_arn, db_user: $db_user, db_password: $db_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers an Amazon EBS volume with a specified stack. A volume can be registered with only one stack at a time. If the volume is already registered, you must first deregister it by calling DeregisterVolume. For more information, see Resource Management (https://docs.aws.amazon.com/opsworks/latest/userguide/resources.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# Returns: record<VolumeId: string>
# operationId: RegisterVolume
export def "register-volume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --ec2-volume-id: string # The Amazon EBS volume ID.
  stack_id: string # The stack ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.RegisterVolume"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Ec2VolumeId, var: ec2_volume_id}, {name: StackId, var: stack_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ec2_volume_id: $ec2_volume_id, stack_id: $stack_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Specify the load-based auto scaling configuration for a specified layer. For more information, see Managing Load with Time-based and Load-based Instances (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-autoscaling.html). To use load-based auto scaling, you must create a set of load-based auto scaling instances. Load-based auto scaling operates only on the instances from that set, so you must ensure that you have created enough instances to handle the maximum anticipated load. Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: SetLoadBasedAutoScaling
export def "set-load-based-auto-scaling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  layer_id: string # The layer ID.
  --enable: oneof<nothing, bool> # Enables load-based auto scaling for the layer.
  --up-scaling: record # Describes a load-based auto scaling upscaling or downscaling threshold configuration, which specifies when AWS OpsWorks Stacks starts or stops load-based instances. — shape: {InstanceCount?: int, ThresholdsWaitTime?: int, IgnoreMetricsTime?: int, CpuThreshold?: float, MemoryThreshold?: float, LoadThreshold?: float, Alarms?: list<string>}
  --down-scaling: record # Describes a load-based auto scaling upscaling or downscaling threshold configuration, which specifies when AWS OpsWorks Stacks starts or stops load-based instances. — shape: {InstanceCount?: int, ThresholdsWaitTime?: int, IgnoreMetricsTime?: int, CpuThreshold?: float, MemoryThreshold?: float, LoadThreshold?: float, Alarms?: list<string>}
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.SetLoadBasedAutoScaling"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LayerId, var: layer_id}, {name: Enable, var: enable}, {name: UpScaling, var: up_scaling}, {name: DownScaling, var: down_scaling}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, layer_id: $layer_id, enable: $enable, up_scaling: $up_scaling, down_scaling: $down_scaling
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Specifies a user's permissions. For more information, see Security and Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/workingsecurity.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: SetPermission
export def "set-permission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  stack_id: string # The stack ID.
  iam_user_arn: string # The user's IAM ARN. This can also be a federated user's ARN.
  --allow-ssh: oneof<nothing, bool> # The user is allowed to use SSH to communicate with the instance.
  --allow-sudo: oneof<nothing, bool> # The user is allowed to use sudo to elevate privileges.
  --level: string # The user's permission level, which must be set to one of the following strings. You cannot set your own permissions level. deny show deploy manage iam_only For more information about the permissions associated with these levels, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.SetPermission"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}, {name: IamUserArn, var: iam_user_arn}, {name: AllowSsh, var: allow_ssh}, {name: AllowSudo, var: allow_sudo}, {name: Level, var: level}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id, iam_user_arn: $iam_user_arn, allow_ssh: $allow_ssh, allow_sudo: $allow_sudo, level: $level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Specify the time-based auto scaling configuration for a specified instance. For more information, see Managing Load with Time-based and Load-based Instances (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-autoscaling.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: SetTimeBasedAutoScaling
export def "set-time-based-auto-scaling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_id: string # The instance ID.
  --auto-scaling-schedule: record # Describes a time-based instance's auto scaling schedule. The schedule consists of a set of key-value pairs. The key is the time period (a UTC hour) and must be an integer from 0 - 23. The value indicates whether the instance should be online or offline for the specified period, and must be set to "on" or "off" The default setting for all time periods is off, so you use the following parameters primarily to specify the online periods. You don't have to explicitly specify offline periods unless you want to change an online period to an offline period. The following example specifies that the instance should be online for four hours, from UTC 1200 - 1600. It will be off for the remainder of the day. { "12":"on", "13":"on", "14":"on", "15":"on" } — shape: {Monday?: record, Tuesday?: record, Wednesday?: record, Thursday?: record, Friday?: record, Saturday?: record, Sunday?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.SetTimeBasedAutoScaling"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: AutoScalingSchedule, var: auto_scaling_schedule}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id, auto_scaling_schedule: $auto_scaling_schedule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a specified instance. For more information, see Starting, Stopping, and Rebooting Instances (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-starting.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: StartInstance
export def "start-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_id: string # The instance ID.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.StartInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a stack's instances. Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: StartStack
export def "start-stack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  stack_id: string # The stack ID.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.StartStack"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a specified instance. When you stop a standard instance, the data disappears and must be reinstalled when you restart the instance. You can stop an Amazon EBS-backed instance without losing data. For more information, see Starting, Stopping, and Rebooting Instances (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-starting.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: StopInstance
export def "stop-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_id: string # The instance ID.
  --force: oneof<nothing, bool> # Specifies whether to force an instance to stop. If the instance's root device type is ebs, or EBS-backed, adding the Force parameter to the StopInstances API call disassociates the AWS OpsWorks Stacks instance from EC2, and forces deletion of only the OpsWorks Stacks instance. You must also delete the formerly-associated instance in EC2 after troubleshooting and replacing the AWS OpsWorks Stacks instance with a new one.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.StopInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: Force, var: force}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a specified stack. Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: StopStack
export def "stop-stack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  stack_id: string # The stack ID.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.StopStack"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Apply cost-allocation tags to a specified stack or layer in AWS OpsWorks Stacks. For more information about how tagging works, see Tags (https://docs.aws.amazon.com/opsworks/latest/userguide/tagging.html) in the AWS OpsWorks User Guide.
#
# POST /
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
  --x-amz-target: string@x-amz-target-completer-61 # required
  resource_arn: string # The stack or layer's Amazon Resource Number (ARN).
  tags: record # A map that contains tag keys and tag values that are attached to a stack or layer. The key cannot be empty. The key can be a maximum of 127 characters, and can contain only Unicode letters, numbers, or separators, or the following special characters: + - = . _ : / The value can be a maximum 255 characters, and contain only Unicode letters, numbers, or separators, or the following special characters: + - = . _ : / Leading and trailing white spaces are trimmed from both the key and value. A maximum of 40 tags is allowed for any resource.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unassigns a registered instance from all layers that are using the instance. The instance remains in the stack as an unassigned instance, and can be assigned to another layer as needed. You cannot use this action with instances that were created with AWS OpsWorks Stacks. Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: UnassignInstance
export def "unassign-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_id: string # The instance ID.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.UnassignInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unassigns an assigned Amazon EBS volume. The volume remains registered with the stack. For more information, see Resource Management (https://docs.aws.amazon.com/opsworks/latest/userguide/resources.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: UnassignVolume
export def "unassign-volume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  volume_id: string # The volume ID.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.UnassignVolume"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VolumeId, var: volume_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, volume_id: $volume_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes tags from a specified stack or layer.
#
# POST /
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
  --x-amz-target: string@x-amz-target-completer-64 # required
  resource_arn: string # The stack or layer's Amazon Resource Number (ARN).
  tag_keys: list<string> # A list of the keys of tags to be removed from a stack or layer.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specified app. Required Permissions: To use this action, an IAM user must have a Deploy or Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: UpdateApp
export def "update-app" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-65 # required
  app_id: string # The app ID.
  --name: string # The app name.
  --description: string # A description of the app.
  --data-sources: list # The app's data sources. — item shape: {Type?: string, Arn?: string, DatabaseName?: string}
  --type: string@type-completer # The app type.
  --app-source: record # Contains the information required to retrieve an app or cookbook from a repository. For more information, see Creating Apps (https://docs.aws.amazon.com/opsworks/latest/userguide/workingapps-creating.html) or Custom Recipes and Cookbooks (https://docs.aws.amazon.com/opsworks/latest/userguide/workingcookbook.html). — shape: {Type?: "git"|"svn"|"archive"|"s3", Url?: string, Username?: string, Password?: string, SshKey?: string, Revision?: string}
  --domains: list<string> # The app's virtual host settings, with multiple domains separated by commas. For example: 'www.example.com, example.com'
  --enable-ssl: oneof<nothing, bool> # Whether SSL is enabled for the app.
  --ssl-configuration: record # Describes an app's SSL configuration. — shape: {Certificate: string, PrivateKey: string, Chain?: string}
  --attributes: record # One or more user-defined key/value pairs to be added to the stack attributes.
  --environment: list # An array of EnvironmentVariable objects that specify environment variables to be associated with the app. After you deploy the app, these variables are defined on the associated app server instances.For more information, see Environment Variables (https://docs.aws.amazon.com/opsworks/latest/userguide/workingapps-creating.html#workingapps-creating-environment). There is no specific limit on the number of environment variables. However, the size of the associated data structure - which includes the variables' names, values, and protected flag values - cannot exceed 20 KB. This limit should accommodate most if not all use cases. Exceeding it will cause an exception with the message, "Environment: is too large (maximum is 20 KB)." If you have specified one or more environment variables, you cannot modify the stack's Chef version. — item shape: {Key: string, Value: string, Secure?: bool}
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.UpdateApp"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AppId, var: app_id}, {name: Name, var: name}, {name: Description, var: description}, {name: DataSources, var: data_sources}, {name: Type, var: type}, {name: AppSource, var: app_source}, {name: Domains, var: domains}, {name: EnableSsl, var: enable_ssl}, {name: SslConfiguration, var: ssl_configuration}, {name: Attributes, var: attributes}, {name: Environment, var: environment}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, app_id: $app_id, name: $name, description: $description, data_sources: $data_sources, type: $type, app_source: $app_source, domains: $domains, enable_ssl: $enable_ssl, ssl_configuration: $ssl_configuration, attributes: $attributes, environment: $environment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a registered Elastic IP address's name. For more information, see Resource Management (https://docs.aws.amazon.com/opsworks/latest/userguide/resources.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: UpdateElasticIp
export def "update-elastic-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-66 # required
  elastic_ip: string # The IP address for which you want to update the name.
  --name: string # The new name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.UpdateElasticIp"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ElasticIp, var: elastic_ip}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, elastic_ip: $elastic_ip, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specified instance. Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: UpdateInstance
export def "update-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-67 # required
  instance_id: string # The instance ID.
  --layer-ids: list<string> # The instance's layer IDs.
  --instance-type: string # The instance type, such as t2.micro. For a list of supported instance types, open the stack in the console, choose Instances, and choose + Instance. The Size list contains the currently supported types. For more information, see Instance Families and Types (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html). The parameter values that you use to specify the various types are in the API Name column of the Available Instance Types table.
  --auto-scaling-type: string@auto-scaling-type-completer # For load-based or time-based instances, the type. Windows stacks can use only time-based instances.
  --hostname: string # The instance host name.
  --os: string # The instance's operating system, which must be set to one of the following. You cannot update an instance that is using a custom AMI. A supported Linux operating system: An Amazon Linux version, such as Amazon Linux 2018.03, Amazon Linux 2017.09, Amazon Linux 2017.03, Amazon Linux 2016.09, Amazon Linux 2016.03, Amazon Linux 2015.09, or Amazon Linux 2015.03. A supported Ubuntu operating system, such as Ubuntu 16.04 LTS, Ubuntu 14.04 LTS, or Ubuntu 12.04 LTS. CentOS Linux 7 Red Hat Enterprise Linux 7 A supported Windows operating system, such as Microsoft Windows Server 2012 R2 Base, Microsoft Windows Server 2012 R2 with SQL Server Express, Microsoft Windows Server 2012 R2 with SQL Server Standard, or Microsoft Windows Server 2012 R2 with SQL Server Web. For more information about supported operating systems, see AWS OpsWorks Stacks Operating Systems (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-os.html). The default option is the current Amazon Linux version. If you set this parameter to Custom, you must use the AmiId parameter to specify the custom AMI that you want to use. For more information about supported operating systems, see Operating Systems (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-os.html). For more information about how to use custom AMIs with OpsWorks, see Using Custom AMIs (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-custom-ami.html). You can specify a different Linux operating system for the updated stack, but you cannot change from Linux to Windows or Windows to Linux.
  --ami-id: string # The ID of the AMI that was used to create the instance. The value of this parameter must be the same AMI ID that the instance is already using. You cannot apply a new AMI to an instance by running UpdateInstance. UpdateInstance does not work on instances that are using custom AMIs.
  --ssh-key-name: string # The instance's Amazon EC2 key name.
  --architecture: string@architecture-completer # The instance architecture. Instance types do not necessarily support both architectures. For a list of the architectures that are supported by the different instance types, see Instance Families and Types (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html).
  --install-updates-on-boot: oneof<nothing, bool> # Whether to install operating system and package updates when the instance boots. The default value is true. To control when updates are installed, set this value to false. You must then update your instances manually by using CreateDeployment to run the update_dependencies stack command or by manually running yum (Amazon Linux) or apt-get (Ubuntu) on the instances. We strongly recommend using the default value of true, to ensure that your instances have the latest security updates.
  --ebs-optimized: oneof<nothing, bool> # This property cannot be updated.
  --agent-version: string # The default AWS OpsWorks Stacks agent version. You have the following options: INHERIT - Use the stack's default agent version setting. version_number - Use the specified agent version. This value overrides the stack's default setting. To update the agent version, you must edit the instance configuration and specify a new version. AWS OpsWorks Stacks then automatically installs that version on the instance. The default setting is INHERIT. To specify an agent version, you must use the complete version number, not the abbreviated number shown on the console. For a list of available agent version numbers, call DescribeAgentVersions. AgentVersion cannot be set to Chef 12.2.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.UpdateInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: InstanceId, var: instance_id}, {name: LayerIds, var: layer_ids}, {name: InstanceType, var: instance_type}, {name: AutoScalingType, var: auto_scaling_type}, {name: Hostname, var: hostname}, {name: Os, var: os}, {name: AmiId, var: ami_id}, {name: SshKeyName, var: ssh_key_name}, {name: Architecture, var: architecture}, {name: InstallUpdatesOnBoot, var: install_updates_on_boot}, {name: EbsOptimized, var: ebs_optimized}, {name: AgentVersion, var: agent_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_id: $instance_id, layer_ids: $layer_ids, instance_type: $instance_type, auto_scaling_type: $auto_scaling_type, hostname: $hostname, os: $os, ami_id: $ami_id, ssh_key_name: $ssh_key_name, architecture: $architecture, install_updates_on_boot: $install_updates_on_boot, ebs_optimized: $ebs_optimized, agent_version: $agent_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specified layer. Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: UpdateLayer
export def "update-layer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-68 # required
  layer_id: string # The layer ID.
  --name: string # The layer name, which is used by the console.
  --shortname: string # For custom layers only, use this parameter to specify the layer's short name, which is used internally by AWS OpsWorks Stacks and by Chef. The short name is also used as the name for the directory where your app files are installed. It can have a maximum of 200 characters and must be in the following format: /\A[a-z0-9\-\_\.]+\Z/. The built-in layers' short names are defined by AWS OpsWorks Stacks. For more information, see the Layer Reference (https://docs.aws.amazon.com/opsworks/latest/userguide/layers.html)
  --attributes: record # One or more user-defined key/value pairs to be added to the stack attributes.
  --cloud-watch-logs-configuration: record # Describes the Amazon CloudWatch logs configuration for a layer. — shape: {Enabled?: bool, LogStreams?: list}
  --custom-instance-profile-arn: string # The ARN of an IAM profile to be used for all of the layer's EC2 instances. For more information about IAM ARNs, see Using Identifiers (https://docs.aws.amazon.com/IAM/latest/UserGuide/Using_Identifiers.html).
  --custom-json: string # A JSON-formatted string containing custom stack configuration and deployment attributes to be installed on the layer's instances. For more information, see Using Custom JSON (https://docs.aws.amazon.com/opsworks/latest/userguide/workingcookbook-json-override.html).
  --custom-security-group-ids: list<string> # An array containing the layer's custom security group IDs.
  --packages: list<string> # An array of Package objects that describe the layer's packages.
  --volume-configurations: list # A VolumeConfigurations object that describes the layer's Amazon EBS volumes. — item shape: {MountPoint: string, RaidLevel?: int, NumberOfDisks: int, Size: int, VolumeType?: string, Iops?: int, Encrypted?: bool}
  --enable-auto-healing: oneof<nothing, bool> # Whether to disable auto healing for the layer.
  --auto-assign-elastic-ips: oneof<nothing, bool> # Whether to automatically assign an Elastic IP address (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html) to the layer's instances. For more information, see How to Edit a Layer (https://docs.aws.amazon.com/opsworks/latest/userguide/workinglayers-basics-edit.html).
  --auto-assign-public-ips: oneof<nothing, bool> # For stacks that are running in a VPC, whether to automatically assign a public IP address to the layer's instances. For more information, see How to Edit a Layer (https://docs.aws.amazon.com/opsworks/latest/userguide/workinglayers-basics-edit.html).
  --custom-recipes: record # AWS OpsWorks Stacks supports five lifecycle events: setup, configuration, deploy, undeploy, and shutdown. For each layer, AWS OpsWorks Stacks runs a set of standard recipes for each event. In addition, you can provide custom recipes for any or all layers and events. AWS OpsWorks Stacks runs custom event recipes after the standard recipes. LayerCustomRecipes specifies the custom recipes for a particular layer to be run in response to each of the five events. To specify a recipe, use the cookbook's directory name in the repository followed by two colons and the recipe name, which is the recipe's file name without the .rb extension. For example: phpapp2::dbsetup specifies the dbsetup.rb recipe in the repository's phpapp2 folder. — shape: {Setup?: list<string>, Configure?: list<string>, Deploy?: list<string>, Undeploy?: list<string>, Shutdown?: list<string>}
  --install-updates-on-boot: oneof<nothing, bool> # Whether to install operating system and package updates when the instance boots. The default value is true. To control when updates are installed, set this value to false. You must then update your instances manually by using CreateDeployment to run the update_dependencies stack command or manually running yum (Amazon Linux) or apt-get (Ubuntu) on the instances. We strongly recommend using the default value of true, to ensure that your instances have the latest security updates.
  --use-ebs-optimized-instances: oneof<nothing, bool> # Whether to use Amazon EBS-optimized instances.
  --lifecycle-event-configuration: record # Specifies the lifecycle event configuration — shape: {Shutdown?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.UpdateLayer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LayerId, var: layer_id}, {name: Name, var: name}, {name: Shortname, var: shortname}, {name: Attributes, var: attributes}, {name: CloudWatchLogsConfiguration, var: cloud_watch_logs_configuration}, {name: CustomInstanceProfileArn, var: custom_instance_profile_arn}, {name: CustomJson, var: custom_json}, {name: CustomSecurityGroupIds, var: custom_security_group_ids}, {name: Packages, var: packages}, {name: VolumeConfigurations, var: volume_configurations}, {name: EnableAutoHealing, var: enable_auto_healing}, {name: AutoAssignElasticIps, var: auto_assign_elastic_ips}, {name: AutoAssignPublicIps, var: auto_assign_public_ips}, {name: CustomRecipes, var: custom_recipes}, {name: InstallUpdatesOnBoot, var: install_updates_on_boot}, {name: UseEbsOptimizedInstances, var: use_ebs_optimized_instances}, {name: LifecycleEventConfiguration, var: lifecycle_event_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, layer_id: $layer_id, name: $name, shortname: $shortname, attributes: $attributes, cloud_watch_logs_configuration: $cloud_watch_logs_configuration, custom_instance_profile_arn: $custom_instance_profile_arn, custom_json: $custom_json, custom_security_group_ids: $custom_security_group_ids, packages: $packages, volume_configurations: $volume_configurations, enable_auto_healing: $enable_auto_healing, auto_assign_elastic_ips: $auto_assign_elastic_ips, auto_assign_public_ips: $auto_assign_public_ips, custom_recipes: $custom_recipes, install_updates_on_boot: $install_updates_on_boot, use_ebs_optimized_instances: $use_ebs_optimized_instances, lifecycle_event_configuration: $lifecycle_event_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a user's SSH public key. Required Permissions: To use this action, an IAM user must have self-management enabled or an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: UpdateMyUserProfile
export def "update-my-user-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-69 # required
  --ssh-public-key: string # The user's SSH public key.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.UpdateMyUserProfile"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SshPublicKey, var: ssh_public_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ssh_public_key: $ssh_public_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an Amazon RDS instance. Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: UpdateRdsDbInstance
export def "update-rds-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-70 # required
  rds_db_instance_arn: string # The Amazon RDS instance's ARN.
  --db-user: string # The master user name.
  --db-password: string # The database password.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.UpdateRdsDbInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: RdsDbInstanceArn, var: rds_db_instance_arn}, {name: DbUser, var: db_user}, {name: DbPassword, var: db_password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, rds_db_instance_arn: $rds_db_instance_arn, db_user: $db_user, db_password: $db_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specified stack. Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: UpdateStack
export def "update-stack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-71 # required
  stack_id: string # The stack ID.
  --name: string # The stack's new name.
  --attributes: record # One or more user-defined key-value pairs to be added to the stack attributes.
  --service-role-arn: string # Do not use this parameter. You cannot update a stack's service role.
  --default-instance-profile-arn: string # The ARN of an IAM profile that is the default profile for all of the stack's EC2 instances. For more information about IAM ARNs, see Using Identifiers (https://docs.aws.amazon.com/IAM/latest/UserGuide/Using_Identifiers.html).
  --default-os: string # The stack's operating system, which must be set to one of the following: A supported Linux operating system: An Amazon Linux version, such as Amazon Linux 2018.03, Amazon Linux 2017.09, Amazon Linux 2017.03, Amazon Linux 2016.09, Amazon Linux 2016.03, Amazon Linux 2015.09, or Amazon Linux 2015.03. A supported Ubuntu operating system, such as Ubuntu 16.04 LTS, Ubuntu 14.04 LTS, or Ubuntu 12.04 LTS. CentOS Linux 7 Red Hat Enterprise Linux 7 A supported Windows operating system, such as Microsoft Windows Server 2012 R2 Base, Microsoft Windows Server 2012 R2 with SQL Server Express, Microsoft Windows Server 2012 R2 with SQL Server Standard, or Microsoft Windows Server 2012 R2 with SQL Server Web. A custom AMI: Custom. You specify the custom AMI you want to use when you create instances. For more information about how to use custom AMIs with OpsWorks, see Using Custom AMIs (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-custom-ami.html). The default option is the stack's current operating system. For more information about supported operating systems, see AWS OpsWorks Stacks Operating Systems (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-os.html).
  --hostname-theme: string # The stack's new host name theme, with spaces replaced by underscores. The theme is used to generate host names for the stack's instances. By default, HostnameTheme is set to Layer_Dependent, which creates host names by appending integers to the layer's short name. The other themes are: Baked_Goods Clouds Europe_Cities Fruits Greek_Deities_and_Titans Legendary_creatures_from_Japan Planets_and_Moons Roman_Deities Scottish_Islands US_Cities Wild_Cats To obtain a generated host name, call GetHostNameSuggestion, which returns a host name based on the current theme.
  --default-availability-zone: string # The stack's default Availability Zone, which must be in the stack's region. For more information, see Regions and Endpoints (https://docs.aws.amazon.com/general/latest/gr/rande.html). If you also specify a value for DefaultSubnetId, the subnet must be in the same zone. For more information, see CreateStack.
  --default-subnet-id: string # The stack's default VPC subnet ID. This parameter is required if you specify a value for the VpcId parameter. All instances are launched into this subnet unless you specify otherwise when you create the instance. If you also specify a value for DefaultAvailabilityZone, the subnet must be in that zone. For information on default values and when this parameter is required, see the VpcId parameter description.
  --custom-json: string # A string that contains user-defined, custom JSON. It can be used to override the corresponding default stack configuration JSON values or to pass data to recipes. The string should be in the following format: "{\"key1\": \"value1\", \"key2\": \"value2\",...}" For more information about custom JSON, see Use Custom JSON to Modify the Stack Configuration Attributes (https://docs.aws.amazon.com/opsworks/latest/userguide/workingstacks-json.html).
  --configuration-manager: record # Describes the configuration manager. — shape: {Name?: string, Version?: string}
  --chef-configuration: record # Describes the Chef configuration. — shape: {ManageBerkshelf?: bool, BerkshelfVersion?: string}
  --use-custom-cookbooks: oneof<nothing, bool> # Whether the stack uses custom cookbooks.
  --custom-cookbooks-source: record # Contains the information required to retrieve an app or cookbook from a repository. For more information, see Creating Apps (https://docs.aws.amazon.com/opsworks/latest/userguide/workingapps-creating.html) or Custom Recipes and Cookbooks (https://docs.aws.amazon.com/opsworks/latest/userguide/workingcookbook.html). — shape: {Type?: "git"|"svn"|"archive"|"s3", Url?: string, Username?: string, Password?: string, SshKey?: string, Revision?: string}
  --default-ssh-key-name: string # A default Amazon EC2 key-pair name. The default value is none. If you specify a key-pair name, AWS OpsWorks Stacks installs the public key on the instance and you can use the private key with an SSH client to log in to the instance. For more information, see Using SSH to Communicate with an Instance (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-ssh.html) and Managing SSH Access (https://docs.aws.amazon.com/opsworks/latest/userguide/security-ssh-access.html). You can override this setting by specifying a different key pair, or no key pair, when you create an instance (https://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-add.html).
  --default-root-device-type: string@default-root-device-type-completer # The default root device type. This value is used by default for all instances in the stack, but you can override it when you create an instance. For more information, see Storage for the Root Device (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ComponentsAMIs.html#storage-for-the-root-device).
  --use-opsworks-security-groups: oneof<nothing, bool> # Whether to associate the AWS OpsWorks Stacks built-in security groups with the stack's layers. AWS OpsWorks Stacks provides a standard set of built-in security groups, one for each layer, which are associated with layers by default. UseOpsworksSecurityGroups allows you to provide your own custom security groups instead of using the built-in groups. UseOpsworksSecurityGroups has the following settings: True - AWS OpsWorks Stacks automatically associates the appropriate built-in security group with each layer (default setting). You can associate additional security groups with a layer after you create it, but you cannot delete the built-in security group. False - AWS OpsWorks Stacks does not associate built-in security groups with layers. You must create appropriate EC2 security groups and associate a security group with each layer that you create. However, you can still manually associate a built-in security group with a layer on. Custom security groups are required only for those layers that need custom settings. For more information, see Create a New Stack (https://docs.aws.amazon.com/opsworks/latest/userguide/workingstacks-creating.html).
  --agent-version: string # The default AWS OpsWorks Stacks agent version. You have the following options: Auto-update - Set this parameter to LATEST. AWS OpsWorks Stacks automatically installs new agent versions on the stack's instances as soon as they are available. Fixed version - Set this parameter to your preferred agent version. To update the agent version, you must edit the stack configuration and specify a new version. AWS OpsWorks Stacks then automatically installs that version on the stack's instances. The default setting is LATEST. To specify an agent version, you must use the complete version number, not the abbreviated number shown on the console. For a list of available agent version numbers, call DescribeAgentVersions. AgentVersion cannot be set to Chef 12.2. You can also specify an agent version when you create or update an instance, which overrides the stack's default setting.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.UpdateStack"}]
    body: {content_type: "application/json", kind: json, fields: [{name: StackId, var: stack_id}, {name: Name, var: name}, {name: Attributes, var: attributes}, {name: ServiceRoleArn, var: service_role_arn}, {name: DefaultInstanceProfileArn, var: default_instance_profile_arn}, {name: DefaultOs, var: default_os}, {name: HostnameTheme, var: hostname_theme}, {name: DefaultAvailabilityZone, var: default_availability_zone}, {name: DefaultSubnetId, var: default_subnet_id}, {name: CustomJson, var: custom_json}, {name: ConfigurationManager, var: configuration_manager}, {name: ChefConfiguration, var: chef_configuration}, {name: UseCustomCookbooks, var: use_custom_cookbooks}, {name: CustomCookbooksSource, var: custom_cookbooks_source}, {name: DefaultSshKeyName, var: default_ssh_key_name}, {name: DefaultRootDeviceType, var: default_root_device_type}, {name: UseOpsworksSecurityGroups, var: use_opsworks_security_groups}, {name: AgentVersion, var: agent_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, stack_id: $stack_id, name: $name, attributes: $attributes, service_role_arn: $service_role_arn, default_instance_profile_arn: $default_instance_profile_arn, default_os: $default_os, hostname_theme: $hostname_theme, default_availability_zone: $default_availability_zone, default_subnet_id: $default_subnet_id, custom_json: $custom_json, configuration_manager: $configuration_manager, chef_configuration: $chef_configuration, use_custom_cookbooks: $use_custom_cookbooks, custom_cookbooks_source: $custom_cookbooks_source, default_ssh_key_name: $default_ssh_key_name, default_root_device_type: $default_root_device_type, use_opsworks_security_groups: $use_opsworks_security_groups, agent_version: $agent_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specified user profile. Required Permissions: To use this action, an IAM user must have an attached policy that explicitly grants permissions. For more information about user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: UpdateUserProfile
export def "update-user-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-72 # required
  iam_user_arn: string # The user IAM ARN. This can also be a federated user's ARN.
  --ssh-username: string # The user's SSH user name. The allowable characters are [a-z], [A-Z], [0-9], '-', and '_'. If the specified name includes other punctuation marks, AWS OpsWorks Stacks removes them. For example, my.name will be changed to myname. If you do not specify an SSH user name, AWS OpsWorks Stacks generates one from the IAM user name.
  --ssh-public-key: string # The user's new SSH public key.
  --allow-self-management: oneof<nothing, bool> # Whether users can specify their own SSH public key through the My Settings page. For more information, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/security-settingsshkey.html).
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.UpdateUserProfile"}]
    body: {content_type: "application/json", kind: json, fields: [{name: IamUserArn, var: iam_user_arn}, {name: SshUsername, var: ssh_username}, {name: SshPublicKey, var: ssh_public_key}, {name: AllowSelfManagement, var: allow_self_management}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, iam_user_arn: $iam_user_arn, ssh_username: $ssh_username, ssh_public_key: $ssh_public_key, allow_self_management: $allow_self_management
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an Amazon EBS volume's name or mount point. For more information, see Resource Management (https://docs.aws.amazon.com/opsworks/latest/userguide/resources.html). Required Permissions: To use this action, an IAM user must have a Manage permissions level for the stack, or an attached policy that explicitly grants permissions. For more information on user permissions, see Managing User Permissions (https://docs.aws.amazon.com/opsworks/latest/userguide/opsworks-security-users.html).
#
# POST /
# operationId: UpdateVolume
export def "update-volume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-73 # required
  volume_id: string # The volume ID.
  --name: string # The new name.
  --mount-point: string # The new mount point.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OpsWorks_20130218.UpdateVolume"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VolumeId, var: volume_id}, {name: Name, var: name}, {name: MountPoint, var: mount_point}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, volume_id: $volume_id, name: $name, mount_point: $mount_point
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
