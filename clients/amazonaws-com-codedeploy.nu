# Auto-generated client for AWS CodeDeploy v2014-10-06
# Source: https://api.apis.guru/v2/specs/amazonaws.com/codedeploy/2014-10-06/openapi.json
# Auth: --token flag or $env.AWS_CODEDEPLOY_TOKEN

const CLIENT = {
  base_url: "http://codedeploy.us-east-1.amazonaws.com"
  token_env_var: "AWS_CODEDEPLOY_TOKEN"
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

def base-url-completer [] { ["http://codedeploy.us-east-1.amazonaws.com" "http://codedeploy.us-east-2.amazonaws.com" "http://codedeploy.us-west-1.amazonaws.com" "http://codedeploy.us-west-2.amazonaws.com" "http://codedeploy.us-gov-west-1.amazonaws.com" "http://codedeploy.us-gov-east-1.amazonaws.com" "http://codedeploy.ca-central-1.amazonaws.com" "http://codedeploy.eu-north-1.amazonaws.com" "http://codedeploy.eu-west-1.amazonaws.com" "http://codedeploy.eu-west-2.amazonaws.com" "http://codedeploy.eu-west-3.amazonaws.com" "http://codedeploy.eu-central-1.amazonaws.com" "http://codedeploy.eu-south-1.amazonaws.com" "http://codedeploy.af-south-1.amazonaws.com" "http://codedeploy.ap-northeast-1.amazonaws.com" "http://codedeploy.ap-northeast-2.amazonaws.com" "http://codedeploy.ap-northeast-3.amazonaws.com" "http://codedeploy.ap-southeast-1.amazonaws.com" "http://codedeploy.ap-southeast-2.amazonaws.com" "http://codedeploy.ap-east-1.amazonaws.com" "http://codedeploy.ap-south-1.amazonaws.com" "http://codedeploy.sa-east-1.amazonaws.com" "http://codedeploy.me-south-1.amazonaws.com" "https://codedeploy.us-east-1.amazonaws.com" "https://codedeploy.us-east-2.amazonaws.com" "https://codedeploy.us-west-1.amazonaws.com" "https://codedeploy.us-west-2.amazonaws.com" "https://codedeploy.us-gov-west-1.amazonaws.com" "https://codedeploy.us-gov-east-1.amazonaws.com" "https://codedeploy.ca-central-1.amazonaws.com" "https://codedeploy.eu-north-1.amazonaws.com" "https://codedeploy.eu-west-1.amazonaws.com" "https://codedeploy.eu-west-2.amazonaws.com" "https://codedeploy.eu-west-3.amazonaws.com" "https://codedeploy.eu-central-1.amazonaws.com" "https://codedeploy.eu-south-1.amazonaws.com" "https://codedeploy.af-south-1.amazonaws.com" "https://codedeploy.ap-northeast-1.amazonaws.com" "https://codedeploy.ap-northeast-2.amazonaws.com" "https://codedeploy.ap-northeast-3.amazonaws.com" "https://codedeploy.ap-southeast-1.amazonaws.com" "https://codedeploy.ap-southeast-2.amazonaws.com" "https://codedeploy.ap-east-1.amazonaws.com" "https://codedeploy.ap-south-1.amazonaws.com" "https://codedeploy.sa-east-1.amazonaws.com" "https://codedeploy.me-south-1.amazonaws.com" "http://codedeploy.cn-north-1.amazonaws.com.cn" "http://codedeploy.cn-northwest-1.amazonaws.com.cn" "https://codedeploy.cn-north-1.amazonaws.com.cn" "https://codedeploy.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["CodeDeploy_20141006.AddTagsToOnPremisesInstances"] }
def x-amz-target-completer-1 [] { ["CodeDeploy_20141006.BatchGetApplicationRevisions"] }
def x-amz-target-completer-2 [] { ["CodeDeploy_20141006.BatchGetApplications"] }
def x-amz-target-completer-3 [] { ["CodeDeploy_20141006.BatchGetDeploymentGroups"] }
def x-amz-target-completer-4 [] { ["CodeDeploy_20141006.BatchGetDeploymentInstances"] }
def x-amz-target-completer-5 [] { ["CodeDeploy_20141006.BatchGetDeploymentTargets"] }
def x-amz-target-completer-6 [] { ["CodeDeploy_20141006.BatchGetDeployments"] }
def x-amz-target-completer-7 [] { ["CodeDeploy_20141006.BatchGetOnPremisesInstances"] }
def deployment-wait-type-completer [] { ["READY_WAIT" "TERMINATION_WAIT"] }
def x-amz-target-completer-8 [] { ["CodeDeploy_20141006.ContinueDeployment"] }
def compute-platform-completer [] { ["ECS" "Lambda" "Server"] }
def x-amz-target-completer-9 [] { ["CodeDeploy_20141006.CreateApplication"] }
def file-exists-behavior-completer [] { ["DISALLOW" "OVERWRITE" "RETAIN"] }
def x-amz-target-completer-10 [] { ["CodeDeploy_20141006.CreateDeployment"] }
def x-amz-target-completer-11 [] { ["CodeDeploy_20141006.CreateDeploymentConfig"] }
def outdated-instances-strategy-completer [] { ["IGNORE" "UPDATE"] }
def x-amz-target-completer-12 [] { ["CodeDeploy_20141006.CreateDeploymentGroup"] }
def x-amz-target-completer-13 [] { ["CodeDeploy_20141006.DeleteApplication"] }
def x-amz-target-completer-14 [] { ["CodeDeploy_20141006.DeleteDeploymentConfig"] }
def x-amz-target-completer-15 [] { ["CodeDeploy_20141006.DeleteDeploymentGroup"] }
def x-amz-target-completer-16 [] { ["CodeDeploy_20141006.DeleteGitHubAccountToken"] }
def x-amz-target-completer-17 [] { ["CodeDeploy_20141006.DeleteResourcesByExternalId"] }
def x-amz-target-completer-18 [] { ["CodeDeploy_20141006.DeregisterOnPremisesInstance"] }
def x-amz-target-completer-19 [] { ["CodeDeploy_20141006.GetApplication"] }
def x-amz-target-completer-20 [] { ["CodeDeploy_20141006.GetApplicationRevision"] }
def x-amz-target-completer-21 [] { ["CodeDeploy_20141006.GetDeployment"] }
def x-amz-target-completer-22 [] { ["CodeDeploy_20141006.GetDeploymentConfig"] }
def x-amz-target-completer-23 [] { ["CodeDeploy_20141006.GetDeploymentGroup"] }
def x-amz-target-completer-24 [] { ["CodeDeploy_20141006.GetDeploymentInstance"] }
def x-amz-target-completer-25 [] { ["CodeDeploy_20141006.GetDeploymentTarget"] }
def x-amz-target-completer-26 [] { ["CodeDeploy_20141006.GetOnPremisesInstance"] }
def sort-by-completer [] { ["firstUsedTime" "lastUsedTime" "registerTime"] }
def sort-order-completer [] { ["ascending" "descending"] }
def deployed-completer [] { ["exclude" "ignore" "include"] }
def x-amz-target-completer-27 [] { ["CodeDeploy_20141006.ListApplicationRevisions"] }
def x-amz-target-completer-28 [] { ["CodeDeploy_20141006.ListApplications"] }
def x-amz-target-completer-29 [] { ["CodeDeploy_20141006.ListDeploymentConfigs"] }
def x-amz-target-completer-30 [] { ["CodeDeploy_20141006.ListDeploymentGroups"] }
def x-amz-target-completer-31 [] { ["CodeDeploy_20141006.ListDeploymentInstances"] }
def x-amz-target-completer-32 [] { ["CodeDeploy_20141006.ListDeploymentTargets"] }
def x-amz-target-completer-33 [] { ["CodeDeploy_20141006.ListDeployments"] }
def x-amz-target-completer-34 [] { ["CodeDeploy_20141006.ListGitHubAccountTokenNames"] }
def registration-status-completer [] { ["Deregistered" "Registered"] }
def x-amz-target-completer-35 [] { ["CodeDeploy_20141006.ListOnPremisesInstances"] }
def x-amz-target-completer-36 [] { ["CodeDeploy_20141006.ListTagsForResource"] }
def status-completer [] { ["Failed" "InProgress" "Pending" "Skipped" "Succeeded" "Unknown"] }
def x-amz-target-completer-37 [] { ["CodeDeploy_20141006.PutLifecycleEventHookExecutionStatus"] }
def x-amz-target-completer-38 [] { ["CodeDeploy_20141006.RegisterApplicationRevision"] }
def x-amz-target-completer-39 [] { ["CodeDeploy_20141006.RegisterOnPremisesInstance"] }
def x-amz-target-completer-40 [] { ["CodeDeploy_20141006.RemoveTagsFromOnPremisesInstances"] }
def x-amz-target-completer-41 [] { ["CodeDeploy_20141006.SkipWaitTimeForInstanceTermination"] }
def x-amz-target-completer-42 [] { ["CodeDeploy_20141006.StopDeployment"] }
def x-amz-target-completer-43 [] { ["CodeDeploy_20141006.TagResource"] }
def x-amz-target-completer-44 [] { ["CodeDeploy_20141006.UntagResource"] }
def x-amz-target-completer-45 [] { ["CodeDeploy_20141006.UpdateApplication"] }
def x-amz-target-completer-46 [] { ["CodeDeploy_20141006.UpdateDeploymentGroup"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    batch-get-application-revisions: "record<applicationName: string, errorMessage: string, revisions: table<revisionLocation: record, genericRevisionInfo: record>>"
    batch-get-applications: "record<applicationsInfo: table<applicationId: string, applicationName: string, createTime: string, linkedToGitHub: bool, gitHubAccountName: string, computePlatform: string>>"
    batch-get-deployment-groups: "record<deploymentGroupsInfo: table<applicationName: string, deploymentGroupId: string, deploymentGroupName: string, deploymentConfigName: string, ec2TagFilters: list, onPremisesInstanceTagFilters: list, autoScalingGroups: list, serviceRoleArn: string, targetRevision: record, triggerConfigurations: list, alarmConfiguration: record, autoRollbackConfiguration: record, deploymentStyle: record, outdatedInstancesStrategy: string, blueGreenDeploymentConfiguration: record, loadBalancerInfo: record, lastSuccessfulDeployment: record, lastAttemptedDeployment: record, ec2TagSet: record, onPremisesTagSet: record, computePlatform: string, ecsServices: list>, errorMessage: string>"
    batch-get-deployment-instances: "record<instancesSummary: table<deploymentId: string, instanceId: string, status: string, lastUpdatedAt: string, lifecycleEvents: list, instanceType: string>, errorMessage: string>"
    batch-get-deployment-targets: "record<deploymentTargets: table<deploymentTargetType: string, instanceTarget: record, lambdaTarget: record, ecsTarget: record, cloudFormationTarget: record>>"
    batch-get-deployments: "record<deploymentsInfo: table<applicationName: string, deploymentGroupName: string, deploymentConfigName: string, deploymentId: string, previousRevision: record, revision: record, status: string, errorInformation: record, createTime: string, startTime: string, completeTime: string, deploymentOverview: record, description: string, creator: string, ignoreApplicationStopFailures: bool, autoRollbackConfiguration: record, updateOutdatedInstancesOnly: bool, rollbackInfo: record, deploymentStyle: record, targetInstances: record, instanceTerminationWaitTimeStarted: bool, blueGreenDeploymentConfiguration: record, loadBalancerInfo: record, additionalDeploymentStatusInfo: string, fileExistsBehavior: string, deploymentStatusMessages: list, computePlatform: string, externalId: string, relatedDeployments: record, overrideAlarmConfiguration: record>>"
    batch-get-on-premises-instances: "record<instanceInfos: table<instanceName: string, iamSessionArn: string, iamUserArn: string, instanceArn: string, registerTime: string, deregisterTime: string, tags: list>>"
    create-application: "record<applicationId: string>"
    create-deployment: "record<deploymentId: string>"
    create-deployment-config: "record<deploymentConfigId: string>"
    create-deployment-group: "record<deploymentGroupId: string>"
    delete-deployment-group: "record<hooksNotCleanedUp: table<name: string, hook: string>>"
    delete-git-hub-account-token: "record<tokenName: string>"
    delete-resources-by-external-id: "record"
    get-application: "record<application: record<applicationId: string, applicationName: string, createTime: string, linkedToGitHub: bool, gitHubAccountName: string, computePlatform: string>>"
    get-application-revision: "record<applicationName: string, revision: record<revisionType: string, s3Location: record<bucket: string, key: string, bundleType: string, version: string, eTag: string>, gitHubLocation: record<repository: string, commitId: string>, string: record<content: string, sha256: string>, appSpecContent: record<content: string, sha256: string>>, revisionInfo: record<description: string, deploymentGroups: list<string>, firstUsedTime: string, lastUsedTime: string, registerTime: string>>"
    get-deployment: "record<deploymentInfo: record<applicationName: string, deploymentGroupName: string, deploymentConfigName: string, deploymentId: string, previousRevision: record<revisionType: string, s3Location: record, gitHubLocation: record, string: record, appSpecContent: record>, revision: record<revisionType: string, s3Location: record, gitHubLocation: record, string: record, appSpecContent: record>, status: string, errorInformation: record<code: string, message: string>, createTime: string, startTime: string, completeTime: string, deploymentOverview: record<Pending: int, InProgress: int, Succeeded: int, Failed: int, Skipped: int, Ready: int>, description: string, creator: string, ignoreApplicationStopFailures: bool, autoRollbackConfiguration: record<enabled: bool, events: list>, updateOutdatedInstancesOnly: bool, rollbackInfo: record<rollbackDeploymentId: string, rollbackTriggeringDeploymentId: string, rollbackMessage: string>, deploymentStyle: record<deploymentType: string, deploymentOption: string>, targetInstances: record<tagFilters: list, autoScalingGroups: list, ec2TagSet: record>, instanceTerminationWaitTimeStarted: bool, blueGreenDeploymentConfiguration: record<terminateBlueInstancesOnDeploymentSuccess: record, deploymentReadyOption: record, greenFleetProvisioningOption: record>, loadBalancerInfo: record<elbInfoList: list, targetGroupInfoList: list, targetGroupPairInfoList: list>, additionalDeploymentStatusInfo: string, fileExistsBehavior: string, deploymentStatusMessages: list<string>, computePlatform: string, externalId: string, relatedDeployments: record<autoUpdateOutdatedInstancesRootDeploymentId: string, autoUpdateOutdatedInstancesDeploymentIds: list>, overrideAlarmConfiguration: record<enabled: bool, ignorePollAlarmFailure: bool, alarms: list>>>"
    get-deployment-config: "record<deploymentConfigInfo: record<deploymentConfigId: string, deploymentConfigName: string, minimumHealthyHosts: record<type: string, value: int>, createTime: string, computePlatform: string, trafficRoutingConfig: record<type: string, timeBasedCanary: record, timeBasedLinear: record>>>"
    get-deployment-group: "record<deploymentGroupInfo: record<applicationName: string, deploymentGroupId: string, deploymentGroupName: string, deploymentConfigName: string, ec2TagFilters: list<record>, onPremisesInstanceTagFilters: list<record>, autoScalingGroups: list<record>, serviceRoleArn: string, targetRevision: record<revisionType: string, s3Location: record, gitHubLocation: record, string: record, appSpecContent: record>, triggerConfigurations: list<record>, alarmConfiguration: record<enabled: bool, ignorePollAlarmFailure: bool, alarms: list>, autoRollbackConfiguration: record<enabled: bool, events: list>, deploymentStyle: record<deploymentType: string, deploymentOption: string>, outdatedInstancesStrategy: string, blueGreenDeploymentConfiguration: record<terminateBlueInstancesOnDeploymentSuccess: record, deploymentReadyOption: record, greenFleetProvisioningOption: record>, loadBalancerInfo: record<elbInfoList: list, targetGroupInfoList: list, targetGroupPairInfoList: list>, lastSuccessfulDeployment: record<deploymentId: string, status: string, endTime: string, createTime: string>, lastAttemptedDeployment: record<deploymentId: string, status: string, endTime: string, createTime: string>, ec2TagSet: record<ec2TagSetList: list>, onPremisesTagSet: record<onPremisesTagSetList: list>, computePlatform: string, ecsServices: list<record>>>"
    get-deployment-instance: "record<instanceSummary: record<deploymentId: string, instanceId: string, status: string, lastUpdatedAt: string, lifecycleEvents: list<record>, instanceType: string>>"
    get-deployment-target: "record<deploymentTarget: record<deploymentTargetType: string, instanceTarget: record<deploymentId: string, targetId: string, targetArn: string, status: string, lastUpdatedAt: string, lifecycleEvents: list, instanceLabel: string>, lambdaTarget: record<deploymentId: string, targetId: string, targetArn: string, status: string, lastUpdatedAt: string, lifecycleEvents: list, lambdaFunctionInfo: record>, ecsTarget: record<deploymentId: string, targetId: string, targetArn: string, lastUpdatedAt: string, lifecycleEvents: list, status: string, taskSetsInfo: list>, cloudFormationTarget: record<deploymentId: string, targetId: string, lastUpdatedAt: string, lifecycleEvents: list, status: string, resourceType: string, targetVersionWeight: float>>>"
    get-on-premises-instance: "record<instanceInfo: record<instanceName: string, iamSessionArn: string, iamUserArn: string, instanceArn: string, registerTime: string, deregisterTime: string, tags: list<record>>>"
    list-application-revisions: "record<revisions: table<revisionType: string, s3Location: record, gitHubLocation: record, string: record, appSpecContent: record>, nextToken: string>"
    list-applications: "record<applications: list<string>, nextToken: string>"
    list-deployment-configs: "record<deploymentConfigsList: list<string>, nextToken: string>"
    list-deployment-groups: "record<applicationName: string, deploymentGroups: list<string>, nextToken: string>"
    list-deployment-instances: "record<instancesList: list<string>, nextToken: string>"
    list-deployment-targets: "record<targetIds: list<string>, nextToken: string>"
    list-deployments: "record<deployments: list<string>, nextToken: string>"
    list-git-hub-account-token-names: "record<tokenNameList: list<string>, nextToken: string>"
    list-on-premises-instances: "record<instanceNames: list<string>, nextToken: string>"
    list-tags-for-resource: "record<Tags: table<Key: string, Value: string>, NextToken: string>"
    put-lifecycle-event-hook-execution-status: "record<lifecycleEventHookExecutionId: string>"
    stop-deployment: "record<status: string, statusMessage: string>"
    tag-resource: "record"
    untag-resource: "record"
    update-deployment-group: "record<hooksNotCleanedUp: table<name: string, hook: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["add-tags-to-on-premises-instances" "batch-get-application-revisions" "batch-get-applications" "batch-get-deployment-groups" "batch-get-deployment-instances" "batch-get-deployment-targets" "batch-get-deployments" "batch-get-on-premises-instances" "continue-deployment" "create-application" "create-deployment" "create-deployment-config" "create-deployment-group" "delete-application" "delete-deployment-config" "delete-deployment-group" "delete-git-hub-account-token" "delete-resources-by-external-id" "deregister-on-premises-instance" "get-application" "get-application-revision" "get-deployment" "get-deployment-config" "get-deployment-group" "get-deployment-instance" "get-deployment-target" "get-on-premises-instance" "list-application-revisions" "list-applications" "list-deployment-configs" "list-deployment-groups" "list-deployment-instances" "list-deployment-targets" "list-deployments" "list-git-hub-account-token-names" "list-on-premises-instances" "list-tags-for-resource" "put-lifecycle-event-hook-execution-status" "register-application-revision" "register-on-premises-instance" "remove-tags-from-on-premises-instances" "skip-wait-time-for-instance-termination" "stop-deployment" "tag-resource" "untag-resource" "update-application" "update-deployment-group" "commands"] | sort) } | get name | first)
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

# Adds tags to on-premises instances.
#
# POST /
# operationId: AddTagsToOnPremisesInstances
export def "add-tags-to-on-premises-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  tags: list # The tag key-value pairs to add to the on-premises instances. Keys and values are both required. Keys cannot be null or empty strings. Value-only tags are not allowed. — item shape: {Key?: string, Value?: string}
  instance_names: list<string> # The names of the on-premises instances to which to add tags.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.AddTagsToOnPremisesInstances"}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}, {name: instanceNames, var: instance_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, tags: $tags, instance_names: $instance_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about one or more application revisions. The maximum number of application revisions that can be returned is 25.
#
# POST /
# Returns: record<applicationName: string, errorMessage: string, revisions: table<revisionLocation: record, genericRevisionInfo: record>>
# operationId: BatchGetApplicationRevisions
export def "batch-get-application-revisions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  application_name: string # The name of an CodeDeploy application about which to get revision information.
  revisions: list # An array of RevisionLocation objects that specify information to get about the application revisions, including type and location. The maximum number of RevisionLocation objects you can specify is 25. — item shape: {revisionType?: "S3"|"GitHub"|"String"|"AppSpecContent", s3Location?: record, gitHubLocation?: record, string?: record, appSpecContent?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.BatchGetApplicationRevisions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationName, var: application_name}, {name: revisions, var: revisions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, application_name: $application_name, revisions: $revisions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about one or more applications. The maximum number of applications that can be returned is 100.
#
# POST /
# Returns: record<applicationsInfo: table<applicationId: string, applicationName: string, createTime: string, linkedToGitHub: bool, gitHubAccountName: string, computePlatform: string>>
# operationId: BatchGetApplications
export def "batch-get-applications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  application_names: list<string> # A list of application names separated by spaces. The maximum number of application names you can specify is 100.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.BatchGetApplications"}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationNames, var: application_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, application_names: $application_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about one or more deployment groups.
#
# POST /
# Returns: record<deploymentGroupsInfo: table<applicationName: string, deploymentGroupId: string, deploymentGroupName: string, deploymentConfigName: string, ec2TagFilters: list, onPremisesInstanceTagFilters: list, autoScalingGroups: list, serviceRoleArn: string, targetRevision: record, triggerConfigurations: list, alarmConfiguration: record, autoRollbackConfiguration: record, deploymentStyle: record, outdatedInstancesStrategy: string, blueGreenDeploymentConfiguration: record, loadBalancerInfo: record, lastSuccessfulDeployment: record, lastAttemptedDeployment: record, ec2TagSet: record, onPremisesTagSet: record, computePlatform: string, ecsServices: list>, errorMessage: string>
# operationId: BatchGetDeploymentGroups
export def "batch-get-deployment-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  application_name: string # The name of an CodeDeploy application associated with the applicable IAM or Amazon Web Services account.
  deployment_group_names: list<string> # The names of the deployment groups.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.BatchGetDeploymentGroups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationName, var: application_name}, {name: deploymentGroupNames, var: deployment_group_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, application_name: $application_name, deployment_group_names: $deployment_group_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method works, but is deprecated. Use BatchGetDeploymentTargets instead. Returns an array of one or more instances associated with a deployment. This method works with EC2/On-premises and Lambda compute platforms. The newer BatchGetDeploymentTargets works with all compute platforms. The maximum number of instances that can be returned is 25.
#
# POST /
# DEPRECATED
# Returns: record<instancesSummary: table<deploymentId: string, instanceId: string, status: string, lastUpdatedAt: string, lifecycleEvents: list, instanceType: string>, errorMessage: string>
# operationId: BatchGetDeploymentInstances
@deprecated
export def "batch-get-deployment-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  deployment_id: string # The unique ID of a deployment.
  instance_ids: list<string> # The unique IDs of instances used in the deployment. The maximum number of instance IDs you can specify is 25.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.BatchGetDeploymentInstances"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentId, var: deployment_id}, {name: instanceIds, var: instance_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deployment_id: $deployment_id, instance_ids: $instance_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an array of one or more targets associated with a deployment. This method works with all compute types and should be used instead of the deprecated BatchGetDeploymentInstances. The maximum number of targets that can be returned is 25. The type of targets returned depends on the deployment's compute platform or deployment method: EC2/On-premises: Information about Amazon EC2 instance targets. Lambda: Information about Lambda functions targets. Amazon ECS: Information about Amazon ECS service targets. CloudFormation: Information about targets of blue/green deployments initiated by a CloudFormation stack update.
#
# POST /
# Returns: record<deploymentTargets: table<deploymentTargetType: string, instanceTarget: record, lambdaTarget: record, ecsTarget: record, cloudFormationTarget: record>>
# operationId: BatchGetDeploymentTargets
export def "batch-get-deployment-targets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --deployment-id: string # The unique ID of a deployment.
  --target-ids: list<string> # The unique IDs of the deployment targets. The compute platform of the deployment determines the type of the targets and their formats. The maximum number of deployment target IDs you can specify is 25. For deployments that use the EC2/On-premises compute platform, the target IDs are Amazon EC2 or on-premises instances IDs, and their target type is instanceTarget. For deployments that use the Lambda compute platform, the target IDs are the names of Lambda functions, and their target type is instanceTarget. For deployments that use the Amazon ECS compute platform, the target IDs are pairs of Amazon ECS clusters and services specified using the format <clustername>:<servicename>. Their target type is ecsTarget. For deployments that are deployed with CloudFormation, the target IDs are CloudFormation stack IDs. Their target type is cloudFormationTarget.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.BatchGetDeploymentTargets"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentId, var: deployment_id}, {name: targetIds, var: target_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deployment_id: $deployment_id, target_ids: $target_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about one or more deployments. The maximum number of deployments that can be returned is 25.
#
# POST /
# Returns: record<deploymentsInfo: table<applicationName: string, deploymentGroupName: string, deploymentConfigName: string, deploymentId: string, previousRevision: record, revision: record, status: string, errorInformation: record, createTime: string, startTime: string, completeTime: string, deploymentOverview: record, description: string, creator: string, ignoreApplicationStopFailures: bool, autoRollbackConfiguration: record, updateOutdatedInstancesOnly: bool, rollbackInfo: record, deploymentStyle: record, targetInstances: record, instanceTerminationWaitTimeStarted: bool, blueGreenDeploymentConfiguration: record, loadBalancerInfo: record, additionalDeploymentStatusInfo: string, fileExistsBehavior: string, deploymentStatusMessages: list, computePlatform: string, externalId: string, relatedDeployments: record, overrideAlarmConfiguration: record>>
# operationId: BatchGetDeployments
export def "batch-get-deployments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  deployment_ids: list<string> # A list of deployment IDs, separated by spaces. The maximum number of deployment IDs you can specify is 25.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.BatchGetDeployments"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentIds, var: deployment_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deployment_ids: $deployment_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about one or more on-premises instances. The maximum number of on-premises instances that can be returned is 25.
#
# POST /
# Returns: record<instanceInfos: table<instanceName: string, iamSessionArn: string, iamUserArn: string, instanceArn: string, registerTime: string, deregisterTime: string, tags: list>>
# operationId: BatchGetOnPremisesInstances
export def "batch-get-on-premises-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_names: list<string> # The names of the on-premises instances about which to get information. The maximum number of instance names you can specify is 25.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.BatchGetOnPremisesInstances"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceNames, var: instance_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_names: $instance_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For a blue/green deployment, starts the process of rerouting traffic from instances in the original environment to instances in the replacement environment without waiting for a specified wait time to elapse. (Traffic rerouting, which is achieved by registering instances in the replacement environment with the load balancer, can start as soon as all instances have a status of Ready.)
#
# POST /
# operationId: ContinueDeployment
export def "continue-deployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --deployment-id: string # The unique ID of a blue/green deployment for which you want to start rerouting traffic to the replacement environment.
  --deployment-wait-type: string@deployment-wait-type-completer # The status of the deployment's waiting period. READY_WAIT indicates that the deployment is ready to start shifting traffic. TERMINATION_WAIT indicates that the traffic is shifted, but the original target is not terminated.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.ContinueDeployment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentId, var: deployment_id}, {name: deploymentWaitType, var: deployment_wait_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deployment_id: $deployment_id, deployment_wait_type: $deployment_wait_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an application.
#
# POST /
# Returns: record<applicationId: string>
# operationId: CreateApplication
export def "create-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  application_name: string # The name of the application. This name must be unique with the applicable IAM or Amazon Web Services account.
  --compute-platform: string@compute-platform-completer # The destination platform type for the deployment (Lambda, Server, or ECS).
  --tags: list # The metadata that you apply to CodeDeploy applications to help you organize and categorize them. Each tag consists of a key and an optional value, both of which you define. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.CreateApplication"}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationName, var: application_name}, {name: computePlatform, var: compute_platform}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, application_name: $application_name, compute_platform: $compute_platform, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deploys an application revision through the specified deployment group.
#
# POST /
# Returns: record<deploymentId: string>
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
  --x-amz-target: string@x-amz-target-completer-10 # required
  application_name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account.
  --deployment-group-name: string # The name of the deployment group.
  --revision: record # Information about the location of an application revision. — shape: {revisionType?: "S3"|"GitHub"|"String"|"AppSpecContent", s3Location?: record, gitHubLocation?: record, string?: record, appSpecContent?: record}
  --deployment-config-name: string # The name of a deployment configuration associated with the IAM user or Amazon Web Services account. If not specified, the value configured in the deployment group is used as the default. If the deployment group does not have a deployment configuration associated with it, CodeDeployDefault.OneAtATime is used by default.
  --description: string # A comment about the deployment.
  --ignore-application-stop-failures: oneof<nothing, bool> # If true, then if an ApplicationStop, BeforeBlockTraffic, or AfterBlockTraffic deployment lifecycle event to an instance fails, then the deployment continues to the next deployment lifecycle event. For example, if ApplicationStop fails, the deployment continues with DownloadBundle. If BeforeBlockTraffic fails, the deployment continues with BlockTraffic. If AfterBlockTraffic fails, the deployment continues with ApplicationStop. If false or not specified, then if a lifecycle event fails during a deployment to an instance, that deployment fails. If deployment to that instance is part of an overall deployment and the number of healthy hosts is not less than the minimum number of healthy hosts, then a deployment to the next instance is attempted. During a deployment, the CodeDeploy agent runs the scripts specified for ApplicationStop, BeforeBlockTraffic, and AfterBlockTraffic in the AppSpec file from the previous successful deployment. (All other scripts are run from the AppSpec file in the current deployment.) If one of these scripts contains an error and does not run successfully, the deployment can fail. If the cause of the failure is a script from the last successful deployment that will never run successfully, create a new deployment and use ignoreApplicationStopFailures to specify that the ApplicationStop, BeforeBlockTraffic, and AfterBlockTraffic failures should be ignored.
  --target-instances: record # Information about the instances to be used in the replacement environment in a blue/green deployment. — shape: {tagFilters?: list, autoScalingGroups?: list<string>, ec2TagSet?: record}
  --auto-rollback-configuration: record # Information about a configuration for automatically rolling back to a previous version of an application revision when a deployment is not completed successfully. — shape: {enabled?: bool, events?: list<string>}
  --update-outdated-instances-only: oneof<nothing, bool> # Indicates whether to deploy to all instances or only to instances that are not running the latest application revision.
  --file-exists-behavior: string@file-exists-behavior-completer # Information about how CodeDeploy handles files that already exist in a deployment target location but weren't part of the previous successful deployment. The fileExistsBehavior parameter takes any of the following values: DISALLOW: The deployment fails. This is also the default behavior if no option is specified. OVERWRITE: The version of the file from the application revision currently being deployed replaces the version already on the instance. RETAIN: The version of the file already on the instance is kept and used as part of the new deployment.
  --override-alarm-configuration: record # Information about alarms associated with a deployment or deployment group. — shape: {enabled?: bool, ignorePollAlarmFailure?: bool, alarms?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.CreateDeployment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationName, var: application_name}, {name: deploymentGroupName, var: deployment_group_name}, {name: revision, var: revision}, {name: deploymentConfigName, var: deployment_config_name}, {name: description, var: description}, {name: ignoreApplicationStopFailures, var: ignore_application_stop_failures}, {name: targetInstances, var: target_instances}, {name: autoRollbackConfiguration, var: auto_rollback_configuration}, {name: updateOutdatedInstancesOnly, var: update_outdated_instances_only}, {name: fileExistsBehavior, var: file_exists_behavior}, {name: overrideAlarmConfiguration, var: override_alarm_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, application_name: $application_name, deployment_group_name: $deployment_group_name, revision: $revision, deployment_config_name: $deployment_config_name, description: $description, ignore_application_stop_failures: $ignore_application_stop_failures, target_instances: $target_instances, auto_rollback_configuration: $auto_rollback_configuration, update_outdated_instances_only: $update_outdated_instances_only, file_exists_behavior: $file_exists_behavior, override_alarm_configuration: $override_alarm_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a deployment configuration.
#
# POST /
# Returns: record<deploymentConfigId: string>
# operationId: CreateDeploymentConfig
export def "create-deployment-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  deployment_config_name: string # The name of the deployment configuration to create.
  --minimum-healthy-hosts: record # Information about minimum healthy instance. — shape: {type?: "HOST_COUNT"|"FLEET_PERCENT", value?: int}
  --traffic-routing-config: record # The configuration that specifies how traffic is shifted from one version of a Lambda function to another version during an Lambda deployment, or from one Amazon ECS task set to another during an Amazon ECS deployment. — shape: {type?: "TimeBasedCanary"|"TimeBasedLinear"|"AllAtOnce", timeBasedCanary?: record, timeBasedLinear?: record}
  --compute-platform: string@compute-platform-completer # The destination platform type for the deployment (Lambda, Server, or ECS).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.CreateDeploymentConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentConfigName, var: deployment_config_name}, {name: minimumHealthyHosts, var: minimum_healthy_hosts}, {name: trafficRoutingConfig, var: traffic_routing_config}, {name: computePlatform, var: compute_platform}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deployment_config_name: $deployment_config_name, minimum_healthy_hosts: $minimum_healthy_hosts, traffic_routing_config: $traffic_routing_config, compute_platform: $compute_platform
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a deployment group to which application revisions are deployed.
#
# POST /
# Returns: record<deploymentGroupId: string>
# operationId: CreateDeploymentGroup
export def "create-deployment-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  application_name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account.
  deployment_group_name: string # The name of a new deployment group for the specified application.
  --deployment-config-name: string # If specified, the deployment configuration name can be either one of the predefined configurations provided with CodeDeploy or a custom deployment configuration that you create by calling the create deployment configuration operation. CodeDeployDefault.OneAtATime is the default deployment configuration. It is used if a configuration isn't specified for the deployment or deployment group. For more information about the predefined deployment configurations in CodeDeploy, see Working with Deployment Configurations in CodeDeploy (https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-configurations.html) in the CodeDeploy User Guide.
  --ec2-tag-filters: list # The Amazon EC2 tags on which to filter. The deployment group includes Amazon EC2 instances with any of the specified tags. Cannot be used in the same call as ec2TagSet. — item shape: {Key?: string, Value?: string, Type?: "KEY_ONLY"|"VALUE_ONLY"|"KEY_AND_VALUE"}
  --on-premises-instance-tag-filters: list # The on-premises instance tags on which to filter. The deployment group includes on-premises instances with any of the specified tags. Cannot be used in the same call as OnPremisesTagSet. — item shape: {Key?: string, Value?: string, Type?: "KEY_ONLY"|"VALUE_ONLY"|"KEY_AND_VALUE"}
  --auto-scaling-groups: list<string> # A list of associated Amazon EC2 Auto Scaling groups.
  service_role_arn: string # A service role Amazon Resource Name (ARN) that allows CodeDeploy to act on the user's behalf when interacting with Amazon Web Services services.
  --trigger-configurations: list # Information about triggers to create when the deployment group is created. For examples, see Create a Trigger for an CodeDeploy Event (https://docs.aws.amazon.com/codedeploy/latest/userguide/how-to-notify-sns.html) in the CodeDeploy User Guide. — item shape: {triggerName?: string, triggerTargetArn?: string, triggerEvents?: list<string>}
  --alarm-configuration: record # Information about alarms associated with a deployment or deployment group. — shape: {enabled?: bool, ignorePollAlarmFailure?: bool, alarms?: list}
  --auto-rollback-configuration: record # Information about a configuration for automatically rolling back to a previous version of an application revision when a deployment is not completed successfully. — shape: {enabled?: bool, events?: list<string>}
  --outdated-instances-strategy: string@outdated-instances-strategy-completer # Indicates what happens when new Amazon EC2 instances are launched mid-deployment and do not receive the deployed application revision. If this option is set to UPDATE or is unspecified, CodeDeploy initiates one or more 'auto-update outdated instances' deployments to apply the deployed application revision to the new Amazon EC2 instances. If this option is set to IGNORE, CodeDeploy does not initiate a deployment to update the new Amazon EC2 instances. This may result in instances having different revisions.
  --deployment-style: record # Information about the type of deployment, either in-place or blue/green, you want to run and whether to route deployment traffic behind a load balancer. — shape: {deploymentType?: "IN_PLACE"|"BLUE_GREEN", deploymentOption?: "WITH_TRAFFIC_CONTROL"|"WITHOUT_TRAFFIC_CONTROL"}
  --blue-green-deployment-configuration: record # Information about blue/green deployment options for a deployment group. — shape: {terminateBlueInstancesOnDeploymentSuccess?: record, deploymentReadyOption?: record, greenFleetProvisioningOption?: record}
  --load-balancer-info: record # Information about the Elastic Load Balancing load balancer or target group used in a deployment. — shape: {elbInfoList?: list, targetGroupInfoList?: list, targetGroupPairInfoList?: list}
  --ec2-tag-set: record # Information about groups of Amazon EC2 instance tags. — shape: {ec2TagSetList?: list}
  --ecs-services: list # The target Amazon ECS services in the deployment group. This applies only to deployment groups that use the Amazon ECS compute platform. A target Amazon ECS service is specified as an Amazon ECS cluster and service name pair using the format <clustername>:<servicename>. — item shape: {serviceName?: string, clusterName?: string}
  --on-premises-tag-set: record # Information about groups of on-premises instance tags. — shape: {onPremisesTagSetList?: list}
  --tags: list # The metadata that you apply to CodeDeploy deployment groups to help you organize and categorize them. Each tag consists of a key and an optional value, both of which you define. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.CreateDeploymentGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationName, var: application_name}, {name: deploymentGroupName, var: deployment_group_name}, {name: deploymentConfigName, var: deployment_config_name}, {name: ec2TagFilters, var: ec2_tag_filters}, {name: onPremisesInstanceTagFilters, var: on_premises_instance_tag_filters}, {name: autoScalingGroups, var: auto_scaling_groups}, {name: serviceRoleArn, var: service_role_arn}, {name: triggerConfigurations, var: trigger_configurations}, {name: alarmConfiguration, var: alarm_configuration}, {name: autoRollbackConfiguration, var: auto_rollback_configuration}, {name: outdatedInstancesStrategy, var: outdated_instances_strategy}, {name: deploymentStyle, var: deployment_style}, {name: blueGreenDeploymentConfiguration, var: blue_green_deployment_configuration}, {name: loadBalancerInfo, var: load_balancer_info}, {name: ec2TagSet, var: ec2_tag_set}, {name: ecsServices, var: ecs_services}, {name: onPremisesTagSet, var: on_premises_tag_set}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, application_name: $application_name, deployment_group_name: $deployment_group_name, deployment_config_name: $deployment_config_name, ec2_tag_filters: $ec2_tag_filters, on_premises_instance_tag_filters: $on_premises_instance_tag_filters, auto_scaling_groups: $auto_scaling_groups, service_role_arn: $service_role_arn, trigger_configurations: $trigger_configurations, alarm_configuration: $alarm_configuration, auto_rollback_configuration: $auto_rollback_configuration, outdated_instances_strategy: $outdated_instances_strategy, deployment_style: $deployment_style, blue_green_deployment_configuration: $blue_green_deployment_configuration, load_balancer_info: $load_balancer_info, ec2_tag_set: $ec2_tag_set, ecs_services: $ecs_services, on_premises_tag_set: $on_premises_tag_set, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an application.
#
# POST /
# operationId: DeleteApplication
export def "delete-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  application_name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.DeleteApplication"}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationName, var: application_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, application_name: $application_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a deployment configuration. A deployment configuration cannot be deleted if it is currently in use. Predefined configurations cannot be deleted.
#
# POST /
# operationId: DeleteDeploymentConfig
export def "delete-deployment-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  deployment_config_name: string # The name of a deployment configuration associated with the IAM user or Amazon Web Services account.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.DeleteDeploymentConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentConfigName, var: deployment_config_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deployment_config_name: $deployment_config_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a deployment group.
#
# POST /
# Returns: record<hooksNotCleanedUp: table<name: string, hook: string>>
# operationId: DeleteDeploymentGroup
export def "delete-deployment-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  application_name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account.
  deployment_group_name: string # The name of a deployment group for the specified application.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.DeleteDeploymentGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationName, var: application_name}, {name: deploymentGroupName, var: deployment_group_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, application_name: $application_name, deployment_group_name: $deployment_group_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a GitHub account connection.
#
# POST /
# Returns: record<tokenName: string>
# operationId: DeleteGitHubAccountToken
export def "delete-git-hub-account-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --token-name: string # The name of the GitHub account connection to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.DeleteGitHubAccountToken"}]
    body: {content_type: "application/json", kind: json, fields: [{name: tokenName, var: token_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, token_name: $token_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes resources linked to an external ID.
#
# POST /
# Returns: record
# operationId: DeleteResourcesByExternalId
export def "delete-resources-by-external-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --external-id: string # The unique ID of an external resource (for example, a CloudFormation stack ID) that is linked to one or more CodeDeploy resources.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.DeleteResourcesByExternalId"}]
    body: {content_type: "application/json", kind: json, fields: [{name: externalId, var: external_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, external_id: $external_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deregisters an on-premises instance.
#
# POST /
# operationId: DeregisterOnPremisesInstance
export def "deregister-on-premises-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_name: string # The name of the on-premises instance to deregister.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.DeregisterOnPremisesInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceName, var: instance_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_name: $instance_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about an application.
#
# POST /
# Returns: record<application: record<applicationId: string, applicationName: string, createTime: string, linkedToGitHub: bool, gitHubAccountName: string, computePlatform: string>>
# operationId: GetApplication
export def "get-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  application_name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.GetApplication"}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationName, var: application_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, application_name: $application_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about an application revision.
#
# POST /
# Returns: record<applicationName: string, revision: record<revisionType: string, s3Location: record<bucket: string, key: string, bundleType: string, version: string, eTag: string>, gitHubLocation: record<repository: string, commitId: string>, string: record<content: string, sha256: string>, appSpecContent: record<content: string, sha256: string>>, revisionInfo: record<description: string, deploymentGroups: list<string>, firstUsedTime: string, lastUsedTime: string, registerTime: string>>
# operationId: GetApplicationRevision
export def "get-application-revision" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  application_name: string # The name of the application that corresponds to the revision.
  revision: record # Information about the location of an application revision. — shape: {revisionType?: "S3"|"GitHub"|"String"|"AppSpecContent", s3Location?: record, gitHubLocation?: record, string?: record, appSpecContent?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.GetApplicationRevision"}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationName, var: application_name}, {name: revision, var: revision}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, application_name: $application_name, revision: $revision
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a deployment. The content property of the appSpecContent object in the returned revision is always null. Use GetApplicationRevision and the sha256 property of the returned appSpecContent object to get the content of the deployment’s AppSpec file.
#
# POST /
# Returns: record<deploymentInfo: record<applicationName: string, deploymentGroupName: string, deploymentConfigName: string, deploymentId: string, previousRevision: record<revisionType: string, s3Location: record, gitHubLocation: record, string: record, appSpecContent: record>, revision: record<revisionType: string, s3Location: record, gitHubLocation: record, string: record, appSpecContent: record>, status: string, errorInformation: record<code: string, message: string>, createTime: string, startTime: string, completeTime: string, deploymentOverview: record<Pending: int, InProgress: int, Succeeded: int, Failed: int, Skipped: int, Ready: int>, description: string, creator: string, ignoreApplicationStopFailures: bool, autoRollbackConfiguration: record<enabled: bool, events: list>, updateOutdatedInstancesOnly: bool, rollbackInfo: record<rollbackDeploymentId: string, rollbackTriggeringDeploymentId: string, rollbackMessage: string>, deploymentStyle: record<deploymentType: string, deploymentOption: string>, targetInstances: record<tagFilters: list, autoScalingGroups: list, ec2TagSet: record>, instanceTerminationWaitTimeStarted: bool, blueGreenDeploymentConfiguration: record<terminateBlueInstancesOnDeploymentSuccess: record, deploymentReadyOption: record, greenFleetProvisioningOption: record>, loadBalancerInfo: record<elbInfoList: list, targetGroupInfoList: list, targetGroupPairInfoList: list>, additionalDeploymentStatusInfo: string, fileExistsBehavior: string, deploymentStatusMessages: list<string>, computePlatform: string, externalId: string, relatedDeployments: record<autoUpdateOutdatedInstancesRootDeploymentId: string, autoUpdateOutdatedInstancesDeploymentIds: list>, overrideAlarmConfiguration: record<enabled: bool, ignorePollAlarmFailure: bool, alarms: list>>>
# operationId: GetDeployment
export def "get-deployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  deployment_id: string # The unique ID of a deployment associated with the IAM user or Amazon Web Services account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.GetDeployment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentId, var: deployment_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deployment_id: $deployment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a deployment configuration.
#
# POST /
# Returns: record<deploymentConfigInfo: record<deploymentConfigId: string, deploymentConfigName: string, minimumHealthyHosts: record<type: string, value: int>, createTime: string, computePlatform: string, trafficRoutingConfig: record<type: string, timeBasedCanary: record, timeBasedLinear: record>>>
# operationId: GetDeploymentConfig
export def "get-deployment-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  deployment_config_name: string # The name of a deployment configuration associated with the IAM user or Amazon Web Services account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.GetDeploymentConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentConfigName, var: deployment_config_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deployment_config_name: $deployment_config_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a deployment group.
#
# POST /
# Returns: record<deploymentGroupInfo: record<applicationName: string, deploymentGroupId: string, deploymentGroupName: string, deploymentConfigName: string, ec2TagFilters: list<record>, onPremisesInstanceTagFilters: list<record>, autoScalingGroups: list<record>, serviceRoleArn: string, targetRevision: record<revisionType: string, s3Location: record, gitHubLocation: record, string: record, appSpecContent: record>, triggerConfigurations: list<record>, alarmConfiguration: record<enabled: bool, ignorePollAlarmFailure: bool, alarms: list>, autoRollbackConfiguration: record<enabled: bool, events: list>, deploymentStyle: record<deploymentType: string, deploymentOption: string>, outdatedInstancesStrategy: string, blueGreenDeploymentConfiguration: record<terminateBlueInstancesOnDeploymentSuccess: record, deploymentReadyOption: record, greenFleetProvisioningOption: record>, loadBalancerInfo: record<elbInfoList: list, targetGroupInfoList: list, targetGroupPairInfoList: list>, lastSuccessfulDeployment: record<deploymentId: string, status: string, endTime: string, createTime: string>, lastAttemptedDeployment: record<deploymentId: string, status: string, endTime: string, createTime: string>, ec2TagSet: record<ec2TagSetList: list>, onPremisesTagSet: record<onPremisesTagSetList: list>, computePlatform: string, ecsServices: list<record>>>
# operationId: GetDeploymentGroup
export def "get-deployment-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  application_name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account.
  deployment_group_name: string # The name of a deployment group for the specified application.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.GetDeploymentGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationName, var: application_name}, {name: deploymentGroupName, var: deployment_group_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, application_name: $application_name, deployment_group_name: $deployment_group_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about an instance as part of a deployment.
#
# POST /
# DEPRECATED
# Returns: record<instanceSummary: record<deploymentId: string, instanceId: string, status: string, lastUpdatedAt: string, lifecycleEvents: list<record>, instanceType: string>>
# operationId: GetDeploymentInstance
@deprecated
export def "get-deployment-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  deployment_id: string # The unique ID of a deployment.
  instance_id: string # The unique ID of an instance in the deployment group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.GetDeploymentInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentId, var: deployment_id}, {name: instanceId, var: instance_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deployment_id: $deployment_id, instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a deployment target.
#
# POST /
# Returns: record<deploymentTarget: record<deploymentTargetType: string, instanceTarget: record<deploymentId: string, targetId: string, targetArn: string, status: string, lastUpdatedAt: string, lifecycleEvents: list, instanceLabel: string>, lambdaTarget: record<deploymentId: string, targetId: string, targetArn: string, status: string, lastUpdatedAt: string, lifecycleEvents: list, lambdaFunctionInfo: record>, ecsTarget: record<deploymentId: string, targetId: string, targetArn: string, lastUpdatedAt: string, lifecycleEvents: list, status: string, taskSetsInfo: list>, cloudFormationTarget: record<deploymentId: string, targetId: string, lastUpdatedAt: string, lifecycleEvents: list, status: string, resourceType: string, targetVersionWeight: float>>>
# operationId: GetDeploymentTarget
export def "get-deployment-target" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --deployment-id: string # The unique ID of a deployment.
  --target-id: string # The unique ID of a deployment target.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.GetDeploymentTarget"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentId, var: deployment_id}, {name: targetId, var: target_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deployment_id: $deployment_id, target_id: $target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about an on-premises instance.
#
# POST /
# Returns: record<instanceInfo: record<instanceName: string, iamSessionArn: string, iamUserArn: string, instanceArn: string, registerTime: string, deregisterTime: string, tags: list<record>>>
# operationId: GetOnPremisesInstance
export def "get-on-premises-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_name: string # The name of the on-premises instance about which to get information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.GetOnPremisesInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceName, var: instance_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_name: $instance_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists information about revisions for an application.
#
# POST /
# Returns: record<revisions: table<revisionType: string, s3Location: record, gitHubLocation: record, string: record, appSpecContent: record>, nextToken: string>
# operationId: ListApplicationRevisions
export def "list-application-revisions" [
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
  application_name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account.
  --sort-by: string@sort-by-completer # The column name to use to sort the list results: registerTime: Sort by the time the revisions were registered with CodeDeploy. firstUsedTime: Sort by the time the revisions were first used in a deployment. lastUsedTime: Sort by the time the revisions were last used in a deployment. If not specified or set to null, the results are returned in an arbitrary order.
  --sort-order: string@sort-order-completer # The order in which to sort the list results: ascending: ascending order. descending: descending order. If not specified, the results are sorted in ascending order. If set to null, the results are sorted in an arbitrary order.
  --s3-bucket: string # An Amazon S3 bucket name to limit the search for revisions. If set to null, all of the user's buckets are searched.
  --s3-key-prefix: string # A key prefix for the set of Amazon S3 objects to limit the search for revisions.
  --deployed: string@deployed-completer # Whether to list revisions based on whether the revision is the target revision of a deployment group: include: List revisions that are target revisions of a deployment group. exclude: Do not list revisions that are target revisions of a deployment group. ignore: List all revisions.
  --body-next-token: string # An identifier returned from the previous ListApplicationRevisions call. It can be used to return the next set of applications in the list. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.ListApplicationRevisions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationName, var: application_name}, {name: sortBy, var: sort_by}, {name: sortOrder, var: sort_order}, {name: s3Bucket, var: s3_bucket}, {name: s3KeyPrefix, var: s3_key_prefix}, {name: deployed, var: deployed}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, application_name: $application_name, sort_by: $sort_by, sort_order: $sort_order, s3_bucket: $s3_bucket, s3_key_prefix: $s3_key_prefix, deployed: $deployed, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the applications registered with the IAM user or Amazon Web Services account.
#
# POST /
# Returns: record<applications: list<string>, nextToken: string>
# operationId: ListApplications
export def "list-applications" [
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
  --body-next-token: string # An identifier returned from the previous list applications call. It can be used to return the next set of applications in the list. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.ListApplications"}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the deployment configurations with the IAM user or Amazon Web Services account.
#
# POST /
# Returns: record<deploymentConfigsList: list<string>, nextToken: string>
# operationId: ListDeploymentConfigs
export def "list-deployment-configs" [
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
  --x-amz-target: string@x-amz-target-completer-29 # required
  --body-next-token: string # An identifier returned from the previous ListDeploymentConfigs call. It can be used to return the next set of deployment configurations in the list. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.ListDeploymentConfigs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the deployment groups for an application registered with the IAM user or Amazon Web Services account.
#
# POST /
# Returns: record<applicationName: string, deploymentGroups: list<string>, nextToken: string>
# operationId: ListDeploymentGroups
export def "list-deployment-groups" [
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
  --x-amz-target: string@x-amz-target-completer-30 # required
  application_name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account.
  --body-next-token: string # An identifier returned from the previous list deployment groups call. It can be used to return the next set of deployment groups in the list. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.ListDeploymentGroups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationName, var: application_name}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, application_name: $application_name, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The newer BatchGetDeploymentTargets should be used instead because it works with all compute types. ListDeploymentInstances throws an exception if it is used with a compute platform other than EC2/On-premises or Lambda. Lists the instance for a deployment associated with the IAM user or Amazon Web Services account.
#
# POST /
# DEPRECATED
# Returns: record<instancesList: list<string>, nextToken: string>
# operationId: ListDeploymentInstances
@deprecated
export def "list-deployment-instances" [
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
  --x-amz-target: string@x-amz-target-completer-31 # required
  deployment_id: string # The unique ID of a deployment.
  --body-next-token: string # An identifier returned from the previous list deployment instances call. It can be used to return the next set of deployment instances in the list. (spec name: nextToken)
  --instance-status-filter: list<string> # A subset of instances to list by status: Pending: Include those instances with pending deployments. InProgress: Include those instances where deployments are still in progress. Succeeded: Include those instances with successful deployments. Failed: Include those instances with failed deployments. Skipped: Include those instances with skipped deployments. Unknown: Include those instances with deployments in an unknown state.
  --instance-type-filter: list<string> # The set of instances in a blue/green deployment, either those in the original environment ("BLUE") or those in the replacement environment ("GREEN"), for which you want to view instance information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.ListDeploymentInstances"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentId, var: deployment_id}, {name: nextToken, var: body_next_token}, {name: instanceStatusFilter, var: instance_status_filter}, {name: instanceTypeFilter, var: instance_type_filter}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deployment_id: $deployment_id, body_next_token: $body_next_token, instance_status_filter: $instance_status_filter, instance_type_filter: $instance_type_filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an array of target IDs that are associated a deployment.
#
# POST /
# Returns: record<targetIds: list<string>, nextToken: string>
# operationId: ListDeploymentTargets
export def "list-deployment-targets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --deployment-id: string # The unique ID of a deployment.
  --next-token: string # A token identifier returned from the previous ListDeploymentTargets call. It can be used to return the next set of deployment targets in the list.
  --target-filters: record # A key used to filter the returned targets. The two valid values are: TargetStatus - A TargetStatus filter string can be Failed, InProgress, Pending, Ready, Skipped, Succeeded, or Unknown. ServerInstanceLabel - A ServerInstanceLabel filter string can be Blue or Green.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.ListDeploymentTargets"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentId, var: deployment_id}, {name: nextToken, var: next_token}, {name: targetFilters, var: target_filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deployment_id: $deployment_id, next_token: $next_token, target_filters: $target_filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the deployments in a deployment group for an application registered with the IAM user or Amazon Web Services account.
#
# POST /
# Returns: record<deployments: list<string>, nextToken: string>
# operationId: ListDeployments
export def "list-deployments" [
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
  --x-amz-target: string@x-amz-target-completer-33 # required
  --application-name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account. If applicationName is specified, then deploymentGroupName must be specified. If it is not specified, then deploymentGroupName must not be specified.
  --deployment-group-name: string # The name of a deployment group for the specified application. If deploymentGroupName is specified, then applicationName must be specified. If it is not specified, then applicationName must not be specified.
  --external-id: string # The unique ID of an external resource for returning deployments linked to the external resource.
  --include-only-statuses: list<string> # A subset of deployments to list by status: Created: Include created deployments in the resulting list. Queued: Include queued deployments in the resulting list. In Progress: Include in-progress deployments in the resulting list. Succeeded: Include successful deployments in the resulting list. Failed: Include failed deployments in the resulting list. Stopped: Include stopped deployments in the resulting list.
  --create-time-range: record # Information about a time range. — shape: {start?: string, end?: string}
  --body-next-token: string # An identifier returned from the previous list deployments call. It can be used to return the next set of deployments in the list. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.ListDeployments"}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationName, var: application_name}, {name: deploymentGroupName, var: deployment_group_name}, {name: externalId, var: external_id}, {name: includeOnlyStatuses, var: include_only_statuses}, {name: createTimeRange, var: create_time_range}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, application_name: $application_name, deployment_group_name: $deployment_group_name, external_id: $external_id, include_only_statuses: $include_only_statuses, create_time_range: $create_time_range, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the names of stored connections to GitHub accounts.
#
# POST /
# Returns: record<tokenNameList: list<string>, nextToken: string>
# operationId: ListGitHubAccountTokenNames
export def "list-git-hub-account-token-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --next-token: string # An identifier returned from the previous ListGitHubAccountTokenNames call. It can be used to return the next set of names in the list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.ListGitHubAccountTokenNames"}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of names for one or more on-premises instances. Unless otherwise specified, both registered and deregistered on-premises instance names are listed. To list only registered or deregistered on-premises instance names, use the registration status parameter.
#
# POST /
# Returns: record<instanceNames: list<string>, nextToken: string>
# operationId: ListOnPremisesInstances
export def "list-on-premises-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --registration-status: string@registration-status-completer # The registration status of the on-premises instances: Deregistered: Include deregistered on-premises instances in the resulting list. Registered: Include registered on-premises instances in the resulting list.
  --tag-filters: list # The on-premises instance tags that are used to restrict the on-premises instance names returned. — item shape: {Key?: string, Value?: string, Type?: "KEY_ONLY"|"VALUE_ONLY"|"KEY_AND_VALUE"}
  --next-token: string # An identifier returned from the previous list on-premises instances call. It can be used to return the next set of on-premises instances in the list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.ListOnPremisesInstances"}]
    body: {content_type: "application/json", kind: json, fields: [{name: registrationStatus, var: registration_status}, {name: tagFilters, var: tag_filters}, {name: nextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, registration_status: $registration_status, tag_filters: $tag_filters, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of tags for the resource identified by a specified Amazon Resource Name (ARN). Tags are used to organize and categorize your CodeDeploy resources.
#
# POST /
# Returns: record<Tags: table<Key: string, Value: string>, NextToken: string>
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  resource_arn: string # The ARN of a CodeDeploy resource. ListTagsForResource returns all the tags associated with the resource that is identified by the ResourceArn.
  --next-token: string # An identifier returned from the previous ListTagsForResource call. It can be used to return the next set of applications in the list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the result of a Lambda validation function. The function validates lifecycle hooks during a deployment that uses the Lambda or Amazon ECS compute platform. For Lambda deployments, the available lifecycle hooks are BeforeAllowTraffic and AfterAllowTraffic. For Amazon ECS deployments, the available lifecycle hooks are BeforeInstall, AfterInstall, AfterAllowTestTraffic, BeforeAllowTraffic, and AfterAllowTraffic. Lambda validation functions return Succeeded or Failed. For more information, see AppSpec 'hooks' Section for an Lambda Deployment (https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html#appspec-hooks-lambda) and AppSpec 'hooks' Section for an Amazon ECS Deployment (https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html#appspec-hooks-ecs).
#
# POST /
# Returns: record<lifecycleEventHookExecutionId: string>
# operationId: PutLifecycleEventHookExecutionStatus
export def "put-lifecycle-event-hook-execution-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --deployment-id: string # The unique ID of a deployment. Pass this ID to a Lambda function that validates a deployment lifecycle event.
  --lifecycle-event-hook-execution-id: string # The execution ID of a deployment's lifecycle hook. A deployment lifecycle hook is specified in the hooks section of the AppSpec file.
  --status: string@status-completer # The result of a Lambda function that validates a deployment lifecycle event. The values listed in Valid Values are valid for lifecycle statuses in general; however, only Succeeded and Failed can be passed successfully in your API call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.PutLifecycleEventHookExecutionStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentId, var: deployment_id}, {name: lifecycleEventHookExecutionId, var: lifecycle_event_hook_execution_id}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deployment_id: $deployment_id, lifecycle_event_hook_execution_id: $lifecycle_event_hook_execution_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers with CodeDeploy a revision for the specified application.
#
# POST /
# operationId: RegisterApplicationRevision
export def "register-application-revision" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  application_name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account.
  --description: string # A comment about the revision.
  revision: record # Information about the location of an application revision. — shape: {revisionType?: "S3"|"GitHub"|"String"|"AppSpecContent", s3Location?: record, gitHubLocation?: record, string?: record, appSpecContent?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.RegisterApplicationRevision"}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationName, var: application_name}, {name: description, var: description}, {name: revision, var: revision}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, application_name: $application_name, description: $description, revision: $revision
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers an on-premises instance. Only one IAM ARN (an IAM session ARN or IAM user ARN) is supported in the request. You cannot use both.
#
# POST /
# operationId: RegisterOnPremisesInstance
export def "register-on-premises-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_name: string # The name of the on-premises instance to register.
  --iam-session-arn: string # The ARN of the IAM session to associate with the on-premises instance.
  --iam-user-arn: string # The ARN of the IAM user to associate with the on-premises instance.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.RegisterOnPremisesInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceName, var: instance_name}, {name: iamSessionArn, var: iam_session_arn}, {name: iamUserArn, var: iam_user_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_name: $instance_name, iam_session_arn: $iam_session_arn, iam_user_arn: $iam_user_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes one or more tags from one or more on-premises instances.
#
# POST /
# operationId: RemoveTagsFromOnPremisesInstances
export def "remove-tags-from-on-premises-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  tags: list # The tag key-value pairs to remove from the on-premises instances. — item shape: {Key?: string, Value?: string}
  instance_names: list<string> # The names of the on-premises instances from which to remove tags.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.RemoveTagsFromOnPremisesInstances"}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}, {name: instanceNames, var: instance_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, tags: $tags, instance_names: $instance_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# In a blue/green deployment, overrides any specified wait time and starts terminating instances immediately after the traffic routing is complete.
#
# POST /
# DEPRECATED
# operationId: SkipWaitTimeForInstanceTermination
@deprecated
export def "skip-wait-time-for-instance-termination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --deployment-id: string # The unique ID of a blue/green deployment for which you want to skip the instance termination wait time.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.SkipWaitTimeForInstanceTermination"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentId, var: deployment_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deployment_id: $deployment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attempts to stop an ongoing deployment.
#
# POST /
# Returns: record<status: string, statusMessage: string>
# operationId: StopDeployment
export def "stop-deployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  deployment_id: string # The unique ID of a deployment.
  --auto-rollback-enabled: oneof<nothing, bool> # Indicates, when a deployment is stopped, whether instances that have been updated should be rolled back to the previous version of the application revision.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.StopDeployment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentId, var: deployment_id}, {name: autoRollbackEnabled, var: auto_rollback_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deployment_id: $deployment_id, auto_rollback_enabled: $auto_rollback_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates the list of tags in the input Tags parameter with the resource identified by the ResourceArn input parameter.
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
  --x-amz-target: string@x-amz-target-completer-43 # required
  resource_arn: string # The ARN of a resource, such as a CodeDeploy application or deployment group.
  tags: list # A list of tags that TagResource associates with a resource. The resource is identified by the ResourceArn input parameter. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates a resource from a list of tags. The resource is identified by the ResourceArn input parameter. The tags are identified by the list of keys in the TagKeys input parameter.
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
  --x-amz-target: string@x-amz-target-completer-44 # required
  resource_arn: string # The Amazon Resource Name (ARN) that specifies from which resource to disassociate the tags with the keys in the TagKeys input parameter.
  tag_keys: list<string> # A list of keys of Tag objects. The Tag objects identified by the keys are disassociated from the resource specified by the ResourceArn input parameter.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes the name of an application.
#
# POST /
# operationId: UpdateApplication
export def "update-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --application-name: string # The current name of the application you want to change.
  --new-application-name: string # The new name to give the application.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.UpdateApplication"}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationName, var: application_name}, {name: newApplicationName, var: new_application_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, application_name: $application_name, new_application_name: $new_application_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes information about a deployment group.
#
# POST /
# Returns: record<hooksNotCleanedUp: table<name: string, hook: string>>
# operationId: UpdateDeploymentGroup
export def "update-deployment-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  application_name: string # The application name that corresponds to the deployment group to update.
  current_deployment_group_name: string # The current name of the deployment group.
  --new-deployment-group-name: string # The new name of the deployment group, if you want to change it.
  --deployment-config-name: string # The replacement deployment configuration name to use, if you want to change it.
  --ec2-tag-filters: list # The replacement set of Amazon EC2 tags on which to filter, if you want to change them. To keep the existing tags, enter their names. To remove tags, do not enter any tag names. — item shape: {Key?: string, Value?: string, Type?: "KEY_ONLY"|"VALUE_ONLY"|"KEY_AND_VALUE"}
  --on-premises-instance-tag-filters: list # The replacement set of on-premises instance tags on which to filter, if you want to change them. To keep the existing tags, enter their names. To remove tags, do not enter any tag names. — item shape: {Key?: string, Value?: string, Type?: "KEY_ONLY"|"VALUE_ONLY"|"KEY_AND_VALUE"}
  --auto-scaling-groups: list<string> # The replacement list of Auto Scaling groups to be included in the deployment group, if you want to change them. To keep the Auto Scaling groups, enter their names or do not specify this parameter. To remove Auto Scaling groups, specify a non-null empty list of Auto Scaling group names to detach all CodeDeploy-managed Auto Scaling lifecycle hooks. For examples, see Amazon EC2 instances in an Amazon EC2 Auto Scaling group fail to launch and receive the error "Heartbeat Timeout" (https://docs.aws.amazon.com/https:/docs.aws.amazon.com/codedeploy/latest/userguide/troubleshooting-auto-scaling.html#troubleshooting-auto-scaling-heartbeat) in the CodeDeploy User Guide.
  --service-role-arn: string # A replacement ARN for the service role, if you want to change it.
  --trigger-configurations: list # Information about triggers to change when the deployment group is updated. For examples, see Edit a Trigger in a CodeDeploy Deployment Group (https://docs.aws.amazon.com/codedeploy/latest/userguide/how-to-notify-edit.html) in the CodeDeploy User Guide. — item shape: {triggerName?: string, triggerTargetArn?: string, triggerEvents?: list<string>}
  --alarm-configuration: record # Information about alarms associated with a deployment or deployment group. — shape: {enabled?: bool, ignorePollAlarmFailure?: bool, alarms?: list}
  --auto-rollback-configuration: record # Information about a configuration for automatically rolling back to a previous version of an application revision when a deployment is not completed successfully. — shape: {enabled?: bool, events?: list<string>}
  --outdated-instances-strategy: string@outdated-instances-strategy-completer # Indicates what happens when new Amazon EC2 instances are launched mid-deployment and do not receive the deployed application revision. If this option is set to UPDATE or is unspecified, CodeDeploy initiates one or more 'auto-update outdated instances' deployments to apply the deployed application revision to the new Amazon EC2 instances. If this option is set to IGNORE, CodeDeploy does not initiate a deployment to update the new Amazon EC2 instances. This may result in instances having different revisions.
  --deployment-style: record # Information about the type of deployment, either in-place or blue/green, you want to run and whether to route deployment traffic behind a load balancer. — shape: {deploymentType?: "IN_PLACE"|"BLUE_GREEN", deploymentOption?: "WITH_TRAFFIC_CONTROL"|"WITHOUT_TRAFFIC_CONTROL"}
  --blue-green-deployment-configuration: record # Information about blue/green deployment options for a deployment group. — shape: {terminateBlueInstancesOnDeploymentSuccess?: record, deploymentReadyOption?: record, greenFleetProvisioningOption?: record}
  --load-balancer-info: record # Information about the Elastic Load Balancing load balancer or target group used in a deployment. — shape: {elbInfoList?: list, targetGroupInfoList?: list, targetGroupPairInfoList?: list}
  --ec2-tag-set: record # Information about groups of Amazon EC2 instance tags. — shape: {ec2TagSetList?: list}
  --ecs-services: list # The target Amazon ECS services in the deployment group. This applies only to deployment groups that use the Amazon ECS compute platform. A target Amazon ECS service is specified as an Amazon ECS cluster and service name pair using the format <clustername>:<servicename>. — item shape: {serviceName?: string, clusterName?: string}
  --on-premises-tag-set: record # Information about groups of on-premises instance tags. — shape: {onPremisesTagSetList?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeDeploy_20141006.UpdateDeploymentGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationName, var: application_name}, {name: currentDeploymentGroupName, var: current_deployment_group_name}, {name: newDeploymentGroupName, var: new_deployment_group_name}, {name: deploymentConfigName, var: deployment_config_name}, {name: ec2TagFilters, var: ec2_tag_filters}, {name: onPremisesInstanceTagFilters, var: on_premises_instance_tag_filters}, {name: autoScalingGroups, var: auto_scaling_groups}, {name: serviceRoleArn, var: service_role_arn}, {name: triggerConfigurations, var: trigger_configurations}, {name: alarmConfiguration, var: alarm_configuration}, {name: autoRollbackConfiguration, var: auto_rollback_configuration}, {name: outdatedInstancesStrategy, var: outdated_instances_strategy}, {name: deploymentStyle, var: deployment_style}, {name: blueGreenDeploymentConfiguration, var: blue_green_deployment_configuration}, {name: loadBalancerInfo, var: load_balancer_info}, {name: ec2TagSet, var: ec2_tag_set}, {name: ecsServices, var: ecs_services}, {name: onPremisesTagSet, var: on_premises_tag_set}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, application_name: $application_name, current_deployment_group_name: $current_deployment_group_name, new_deployment_group_name: $new_deployment_group_name, deployment_config_name: $deployment_config_name, ec2_tag_filters: $ec2_tag_filters, on_premises_instance_tag_filters: $on_premises_instance_tag_filters, auto_scaling_groups: $auto_scaling_groups, service_role_arn: $service_role_arn, trigger_configurations: $trigger_configurations, alarm_configuration: $alarm_configuration, auto_rollback_configuration: $auto_rollback_configuration, outdated_instances_strategy: $outdated_instances_strategy, deployment_style: $deployment_style, blue_green_deployment_configuration: $blue_green_deployment_configuration, load_balancer_info: $load_balancer_info, ec2_tag_set: $ec2_tag_set, ecs_services: $ecs_services, on_premises_tag_set: $on_premises_tag_set
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
