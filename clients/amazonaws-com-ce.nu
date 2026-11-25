# Auto-generated client for AWS Cost Explorer Service v2017-10-25
# Source: https://api.apis.guru/v2/specs/amazonaws.com/ce/2017-10-25/openapi.json
# Auth: --token flag or $env.AWS_COST_EXPLORER_SERVICE_TOKEN

const CLIENT = {
  base_url: "http://ce.us-east-1.amazonaws.com"
  token_env_var: "AWS_COST_EXPLORER_SERVICE_TOKEN"
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

def base-url-completer [] { ["http://ce.us-east-1.amazonaws.com" "http://ce.us-east-2.amazonaws.com" "http://ce.us-west-1.amazonaws.com" "http://ce.us-west-2.amazonaws.com" "http://ce.us-gov-west-1.amazonaws.com" "http://ce.us-gov-east-1.amazonaws.com" "http://ce.ca-central-1.amazonaws.com" "http://ce.eu-north-1.amazonaws.com" "http://ce.eu-west-1.amazonaws.com" "http://ce.eu-west-2.amazonaws.com" "http://ce.eu-west-3.amazonaws.com" "http://ce.eu-central-1.amazonaws.com" "http://ce.eu-south-1.amazonaws.com" "http://ce.af-south-1.amazonaws.com" "http://ce.ap-northeast-1.amazonaws.com" "http://ce.ap-northeast-2.amazonaws.com" "http://ce.ap-northeast-3.amazonaws.com" "http://ce.ap-southeast-1.amazonaws.com" "http://ce.ap-southeast-2.amazonaws.com" "http://ce.ap-east-1.amazonaws.com" "http://ce.ap-south-1.amazonaws.com" "http://ce.sa-east-1.amazonaws.com" "http://ce.me-south-1.amazonaws.com" "https://ce.us-east-1.amazonaws.com" "https://ce.us-east-2.amazonaws.com" "https://ce.us-west-1.amazonaws.com" "https://ce.us-west-2.amazonaws.com" "https://ce.us-gov-west-1.amazonaws.com" "https://ce.us-gov-east-1.amazonaws.com" "https://ce.ca-central-1.amazonaws.com" "https://ce.eu-north-1.amazonaws.com" "https://ce.eu-west-1.amazonaws.com" "https://ce.eu-west-2.amazonaws.com" "https://ce.eu-west-3.amazonaws.com" "https://ce.eu-central-1.amazonaws.com" "https://ce.eu-south-1.amazonaws.com" "https://ce.af-south-1.amazonaws.com" "https://ce.ap-northeast-1.amazonaws.com" "https://ce.ap-northeast-2.amazonaws.com" "https://ce.ap-northeast-3.amazonaws.com" "https://ce.ap-southeast-1.amazonaws.com" "https://ce.ap-southeast-2.amazonaws.com" "https://ce.ap-east-1.amazonaws.com" "https://ce.ap-south-1.amazonaws.com" "https://ce.sa-east-1.amazonaws.com" "https://ce.me-south-1.amazonaws.com" "http://ce.cn-north-1.amazonaws.com.cn" "http://ce.cn-northwest-1.amazonaws.com.cn" "https://ce.cn-north-1.amazonaws.com.cn" "https://ce.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWSInsightsIndexService.CreateAnomalyMonitor"] }
def x-amz-target-completer-1 [] { ["AWSInsightsIndexService.CreateAnomalySubscription"] }
def rule-version-completer [] { ["CostCategoryExpression.v1"] }
def x-amz-target-completer-2 [] { ["AWSInsightsIndexService.CreateCostCategoryDefinition"] }
def x-amz-target-completer-3 [] { ["AWSInsightsIndexService.DeleteAnomalyMonitor"] }
def x-amz-target-completer-4 [] { ["AWSInsightsIndexService.DeleteAnomalySubscription"] }
def x-amz-target-completer-5 [] { ["AWSInsightsIndexService.DeleteCostCategoryDefinition"] }
def x-amz-target-completer-6 [] { ["AWSInsightsIndexService.DescribeCostCategoryDefinition"] }
def feedback-completer [] { ["NO" "PLANNED_ACTIVITY" "YES"] }
def x-amz-target-completer-7 [] { ["AWSInsightsIndexService.GetAnomalies"] }
def x-amz-target-completer-8 [] { ["AWSInsightsIndexService.GetAnomalyMonitors"] }
def x-amz-target-completer-9 [] { ["AWSInsightsIndexService.GetAnomalySubscriptions"] }
def granularity-completer [] { ["DAILY" "HOURLY" "MONTHLY"] }
def x-amz-target-completer-10 [] { ["AWSInsightsIndexService.GetCostAndUsage"] }
def x-amz-target-completer-11 [] { ["AWSInsightsIndexService.GetCostAndUsageWithResources"] }
def x-amz-target-completer-12 [] { ["AWSInsightsIndexService.GetCostCategories"] }
def metric-completer [] { ["AMORTIZED_COST" "BLENDED_COST" "NET_AMORTIZED_COST" "NET_UNBLENDED_COST" "NORMALIZED_USAGE_AMOUNT" "UNBLENDED_COST" "USAGE_QUANTITY"] }
def x-amz-target-completer-13 [] { ["AWSInsightsIndexService.GetCostForecast"] }
def dimension-completer [] { ["AGREEMENT_END_DATE_TIME_AFTER" "AGREEMENT_END_DATE_TIME_BEFORE" "ANOMALY_TOTAL_IMPACT_ABSOLUTE" "ANOMALY_TOTAL_IMPACT_PERCENTAGE" "AZ" "BILLING_ENTITY" "CACHE_ENGINE" "DATABASE_ENGINE" "DEPLOYMENT_OPTION" "INSTANCE_TYPE" "INSTANCE_TYPE_FAMILY" "INVOICING_ENTITY" "LEGAL_ENTITY_NAME" "LINKED_ACCOUNT" "LINKED_ACCOUNT_NAME" "OPERATING_SYSTEM" "OPERATION" "PAYMENT_OPTION" "PLATFORM" "PURCHASE_TYPE" "RECORD_TYPE" "REGION" "RESERVATION_ID" "RESOURCE_ID" "RIGHTSIZING_TYPE" "SAVINGS_PLANS_TYPE" "SAVINGS_PLAN_ARN" "SCOPE" "SERVICE" "SERVICE_CODE" "SUBSCRIPTION_ID" "TENANCY" "USAGE_TYPE" "USAGE_TYPE_GROUP"] }
def context-completer [] { ["COST_AND_USAGE" "RESERVATIONS" "SAVINGS_PLANS"] }
def x-amz-target-completer-14 [] { ["AWSInsightsIndexService.GetDimensionValues"] }
def x-amz-target-completer-15 [] { ["AWSInsightsIndexService.GetReservationCoverage"] }
def account-scope-completer [] { ["LINKED" "PAYER"] }
def lookback-period-in-days-completer [] { ["SEVEN_DAYS" "SIXTY_DAYS" "THIRTY_DAYS"] }
def term-in-years-completer [] { ["ONE_YEAR" "THREE_YEARS"] }
def payment-option-completer [] { ["ALL_UPFRONT" "HEAVY_UTILIZATION" "LIGHT_UTILIZATION" "MEDIUM_UTILIZATION" "NO_UPFRONT" "PARTIAL_UPFRONT"] }
def x-amz-target-completer-16 [] { ["AWSInsightsIndexService.GetReservationPurchaseRecommendation"] }
def x-amz-target-completer-17 [] { ["AWSInsightsIndexService.GetReservationUtilization"] }
def x-amz-target-completer-18 [] { ["AWSInsightsIndexService.GetRightsizingRecommendation"] }
def x-amz-target-completer-19 [] { ["AWSInsightsIndexService.GetSavingsPlansCoverage"] }
def savings-plans-type-completer [] { ["COMPUTE_SP" "EC2_INSTANCE_SP" "SAGEMAKER_SP"] }
def x-amz-target-completer-20 [] { ["AWSInsightsIndexService.GetSavingsPlansPurchaseRecommendation"] }
def x-amz-target-completer-21 [] { ["AWSInsightsIndexService.GetSavingsPlansUtilization"] }
def x-amz-target-completer-22 [] { ["AWSInsightsIndexService.GetSavingsPlansUtilizationDetails"] }
def x-amz-target-completer-23 [] { ["AWSInsightsIndexService.GetTags"] }
def x-amz-target-completer-24 [] { ["AWSInsightsIndexService.GetUsageForecast"] }
def status-completer [] { ["Active" "Inactive"] }
def type-completer [] { ["AWSGenerated" "UserDefined"] }
def x-amz-target-completer-25 [] { ["AWSInsightsIndexService.ListCostAllocationTags"] }
def x-amz-target-completer-26 [] { ["AWSInsightsIndexService.ListCostCategoryDefinitions"] }
def generation-status-completer [] { ["FAILED" "PROCESSING" "SUCCEEDED"] }
def x-amz-target-completer-27 [] { ["AWSInsightsIndexService.ListSavingsPlansPurchaseRecommendationGeneration"] }
def x-amz-target-completer-28 [] { ["AWSInsightsIndexService.ListTagsForResource"] }
def x-amz-target-completer-29 [] { ["AWSInsightsIndexService.ProvideAnomalyFeedback"] }
def x-amz-target-completer-30 [] { ["AWSInsightsIndexService.StartSavingsPlansPurchaseRecommendationGeneration"] }
def x-amz-target-completer-31 [] { ["AWSInsightsIndexService.TagResource"] }
def x-amz-target-completer-32 [] { ["AWSInsightsIndexService.UntagResource"] }
def x-amz-target-completer-33 [] { ["AWSInsightsIndexService.UpdateAnomalyMonitor"] }
def frequency-completer [] { ["DAILY" "IMMEDIATE" "WEEKLY"] }
def x-amz-target-completer-34 [] { ["AWSInsightsIndexService.UpdateAnomalySubscription"] }
def x-amz-target-completer-35 [] { ["AWSInsightsIndexService.UpdateCostAllocationTagsStatus"] }
def x-amz-target-completer-36 [] { ["AWSInsightsIndexService.UpdateCostCategoryDefinition"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-anomaly-monitor: "record<MonitorArn: string>"
    create-anomaly-subscription: "record<SubscriptionArn: string>"
    create-cost-category-definition: "record<CostCategoryArn: string, EffectiveStart: string>"
    delete-anomaly-monitor: "record"
    delete-anomaly-subscription: "record"
    delete-cost-category-definition: "record<CostCategoryArn: string, EffectiveEnd: string>"
    describe-cost-category-definition: "record<CostCategory: record<CostCategoryArn: string, EffectiveStart: string, EffectiveEnd: string, Name: string, RuleVersion: string, Rules: list<record>, SplitChargeRules: list<record>, ProcessingStatus: list<record>, DefaultValue: string>>"
    get-anomalies: "record<Anomalies: table<AnomalyId: string, AnomalyStartDate: string, AnomalyEndDate: string, DimensionValue: string, RootCauses: list, AnomalyScore: record, Impact: record, MonitorArn: string, Feedback: string>, NextPageToken: string>"
    get-anomaly-monitors: "record<AnomalyMonitors: table<MonitorArn: string, MonitorName: string, CreationDate: string, LastUpdatedDate: string, LastEvaluatedDate: string, MonitorType: string, MonitorDimension: string, MonitorSpecification: record, DimensionalValueCount: int>, NextPageToken: string>"
    get-anomaly-subscriptions: "record<AnomalySubscriptions: table<SubscriptionArn: string, AccountId: string, MonitorArnList: list, Subscribers: list, Threshold: float, Frequency: string, SubscriptionName: string, ThresholdExpression: record>, NextPageToken: string>"
    get-cost-and-usage: "record<NextPageToken: string, GroupDefinitions: table<Type: string, Key: string>, ResultsByTime: table<TimePeriod: record, Total: record, Groups: list, Estimated: bool>, DimensionValueAttributes: table<Value: string, Attributes: record>>"
    get-cost-and-usage-with-resources: "record<NextPageToken: string, GroupDefinitions: table<Type: string, Key: string>, ResultsByTime: table<TimePeriod: record, Total: record, Groups: list, Estimated: bool>, DimensionValueAttributes: table<Value: string, Attributes: record>>"
    get-cost-categories: "record<NextPageToken: string, CostCategoryNames: list<string>, CostCategoryValues: list<string>, ReturnSize: int, TotalSize: int>"
    get-cost-forecast: "record<Total: record<Amount: string, Unit: string>, ForecastResultsByTime: table<TimePeriod: record, MeanValue: string, PredictionIntervalLowerBound: string, PredictionIntervalUpperBound: string>>"
    get-dimension-values: "record<DimensionValues: table<Value: string, Attributes: record>, ReturnSize: int, TotalSize: int, NextPageToken: string>"
    get-reservation-coverage: "record<CoveragesByTime: table<TimePeriod: record, Groups: list, Total: record>, Total: record<CoverageHours: record<OnDemandHours: string, ReservedHours: string, TotalRunningHours: string, CoverageHoursPercentage: string>, CoverageNormalizedUnits: record<OnDemandNormalizedUnits: string, ReservedNormalizedUnits: string, TotalRunningNormalizedUnits: string, CoverageNormalizedUnitsPercentage: string>, CoverageCost: record<OnDemandCost: string>>, NextPageToken: string>"
    get-reservation-purchase-recommendation: "record<Metadata: record<RecommendationId: string, GenerationTimestamp: string>, Recommendations: table<AccountScope: string, LookbackPeriodInDays: string, TermInYears: string, PaymentOption: string, ServiceSpecification: record, RecommendationDetails: list, RecommendationSummary: record>, NextPageToken: string>"
    get-reservation-utilization: "record<UtilizationsByTime: table<TimePeriod: record, Groups: list, Total: record>, Total: record<UtilizationPercentage: string, UtilizationPercentageInUnits: string, PurchasedHours: string, PurchasedUnits: string, TotalActualHours: string, TotalActualUnits: string, UnusedHours: string, UnusedUnits: string, OnDemandCostOfRIHoursUsed: string, NetRISavings: string, TotalPotentialRISavings: string, AmortizedUpfrontFee: string, AmortizedRecurringFee: string, TotalAmortizedFee: string, RICostForUnusedHours: string, RealizedSavings: string, UnrealizedSavings: string>, NextPageToken: string>"
    get-rightsizing-recommendation: "record<Metadata: record<RecommendationId: string, GenerationTimestamp: string, LookbackPeriodInDays: string, AdditionalMetadata: string>, Summary: record<TotalRecommendationCount: string, EstimatedTotalMonthlySavingsAmount: string, SavingsCurrencyCode: string, SavingsPercentage: string>, RightsizingRecommendations: table<AccountId: string, CurrentInstance: record, RightsizingType: string, ModifyRecommendationDetail: record, TerminateRecommendationDetail: record, FindingReasonCodes: list>, NextPageToken: string, Configuration: record<RecommendationTarget: string, BenefitsConsidered: bool>>"
    get-savings-plans-coverage: "record<SavingsPlansCoverages: table<Attributes: record, Coverage: record, TimePeriod: record>, NextToken: string>"
    get-savings-plans-purchase-recommendation: "record<Metadata: record<RecommendationId: string, GenerationTimestamp: string, AdditionalMetadata: string>, SavingsPlansPurchaseRecommendation: record<AccountScope: string, SavingsPlansType: string, TermInYears: string, PaymentOption: string, LookbackPeriodInDays: string, SavingsPlansPurchaseRecommendationDetails: list<record>, SavingsPlansPurchaseRecommendationSummary: record<EstimatedROI: string, CurrencyCode: string, EstimatedTotalCost: string, CurrentOnDemandSpend: string, EstimatedSavingsAmount: string, TotalRecommendationCount: string, DailyCommitmentToPurchase: string, HourlyCommitmentToPurchase: string, EstimatedSavingsPercentage: string, EstimatedMonthlySavingsAmount: string, EstimatedOnDemandCostWithCurrentCommitment: string>>, NextPageToken: string>"
    get-savings-plans-utilization: "record<SavingsPlansUtilizationsByTime: table<TimePeriod: record, Utilization: record, Savings: record, AmortizedCommitment: record>, Total: record<Utilization: record<TotalCommitment: string, UsedCommitment: string, UnusedCommitment: string, UtilizationPercentage: string>, Savings: record<NetSavings: string, OnDemandCostEquivalent: string>, AmortizedCommitment: record<AmortizedRecurringCommitment: string, AmortizedUpfrontCommitment: string, TotalAmortizedCommitment: string>>>"
    get-savings-plans-utilization-details: "record<SavingsPlansUtilizationDetails: table<SavingsPlanArn: string, Attributes: record, Utilization: record, Savings: record, AmortizedCommitment: record>, Total: record<Utilization: record<TotalCommitment: string, UsedCommitment: string, UnusedCommitment: string, UtilizationPercentage: string>, Savings: record<NetSavings: string, OnDemandCostEquivalent: string>, AmortizedCommitment: record<AmortizedRecurringCommitment: string, AmortizedUpfrontCommitment: string, TotalAmortizedCommitment: string>>, TimePeriod: record<Start: string, End: string>, NextToken: string>"
    get-tags: "record<NextPageToken: string, Tags: list<string>, ReturnSize: int, TotalSize: int>"
    get-usage-forecast: "record<Total: record<Amount: string, Unit: string>, ForecastResultsByTime: table<TimePeriod: record, MeanValue: string, PredictionIntervalLowerBound: string, PredictionIntervalUpperBound: string>>"
    list-cost-allocation-tags: "record<CostAllocationTags: table<TagKey: string, Type: string, Status: string>, NextToken: string>"
    list-cost-category-definitions: "record<CostCategoryReferences: table<CostCategoryArn: string, Name: string, EffectiveStart: string, EffectiveEnd: string, NumberOfRules: int, ProcessingStatus: list, Values: list, DefaultValue: string>, NextToken: string>"
    list-savings-plans-purchase-recommendation-generation: "record<GenerationSummaryList: table<RecommendationId: string, GenerationStatus: string, GenerationStartedTime: string, GenerationCompletionTime: string, EstimatedCompletionTime: string>, NextPageToken: string>"
    list-tags-for-resource: "record<ResourceTags: table<Key: string, Value: string>>"
    provide-anomaly-feedback: "record<AnomalyId: string>"
    start-savings-plans-purchase-recommendation-generation: "record<RecommendationId: string, GenerationStartedTime: string, EstimatedCompletionTime: string>"
    tag-resource: "record"
    untag-resource: "record"
    update-anomaly-monitor: "record<MonitorArn: string>"
    update-anomaly-subscription: "record<SubscriptionArn: string>"
    update-cost-allocation-tags-status: "record<Errors: table<TagKey: string, Code: string, Message: string>>"
    update-cost-category-definition: "record<CostCategoryArn: string, EffectiveStart: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-anomaly-monitor" "create-anomaly-subscription" "create-cost-category-definition" "delete-anomaly-monitor" "delete-anomaly-subscription" "delete-cost-category-definition" "describe-cost-category-definition" "get-anomalies" "get-anomaly-monitors" "get-anomaly-subscriptions" "get-cost-and-usage" "get-cost-and-usage-with-resources" "get-cost-categories" "get-cost-forecast" "get-dimension-values" "get-reservation-coverage" "get-reservation-purchase-recommendation" "get-reservation-utilization" "get-rightsizing-recommendation" "get-savings-plans-coverage" "get-savings-plans-purchase-recommendation" "get-savings-plans-utilization" "get-savings-plans-utilization-details" "get-tags" "get-usage-forecast" "list-cost-allocation-tags" "list-cost-category-definitions" "list-savings-plans-purchase-recommendation-generation" "list-tags-for-resource" "provide-anomaly-feedback" "start-savings-plans-purchase-recommendation-generation" "tag-resource" "untag-resource" "update-anomaly-monitor" "update-anomaly-subscription" "update-cost-allocation-tags-status" "update-cost-category-definition" "commands"] | sort) } | get name | first)
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

# Creates a new cost anomaly detection monitor with the requested type and monitor specification.
#
# POST /
# Returns: record<MonitorArn: string>
# operationId: CreateAnomalyMonitor
export def "create-anomaly-monitor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  anomaly_monitor: record # This object continuously inspects your account's cost data for anomalies. It's based on MonitorType and MonitorSpecification. The content consists of detailed metadata and the current status of the monitor object. — shape: {MonitorArn?: string, MonitorName: string, CreationDate?: string, LastUpdatedDate?: string, LastEvaluatedDate?: string, MonitorType: "DIMENSIONAL"|"CUSTOM", MonitorDimension?: "SERVICE", MonitorSpecification?: record, DimensionalValueCount?: int}
  --resource-tags: list # An optional list of tags to associate with the specified AnomalyMonitor (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_AnomalyMonitor.html). You can use resource tags to control access to your monitor using IAM policies. Each tag consists of a key and a value, and each key must be unique for the resource. The following restrictions apply to resource tags: Although the maximum number of array members is 200, you can assign a maximum of 50 user-tags to one resource. The remaining are reserved for Amazon Web Services use The maximum length of a key is 128 characters The maximum length of a value is 256 characters Keys and values can only contain alphanumeric characters, spaces, and any of the following: _.:/=+@- Keys and values are case sensitive Keys and values are trimmed for any leading or trailing whitespaces Don’t use aws: as a prefix for your keys. This prefix is reserved for Amazon Web Services use — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.CreateAnomalyMonitor"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AnomalyMonitor, var: anomaly_monitor}, {name: ResourceTags, var: resource_tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, anomaly_monitor: $anomaly_monitor, resource_tags: $resource_tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds an alert subscription to a cost anomaly detection monitor. You can use each subscription to define subscribers with email or SNS notifications. Email subscribers can set an absolute or percentage threshold and a time frequency for receiving notifications.
#
# POST /
# Returns: record<SubscriptionArn: string>
# operationId: CreateAnomalySubscription
export def "create-anomaly-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  anomaly_subscription: record # The association between a monitor, threshold, and list of subscribers used to deliver notifications about anomalies detected by a monitor that exceeds a threshold. The content consists of the detailed metadata and the current status of the AnomalySubscription object. — shape: {SubscriptionArn?: string, AccountId?: string, MonitorArnList: list<string>, Subscribers: list, Threshold?: float, Frequency: "DAILY"|"IMMEDIATE"|"WEEKLY", SubscriptionName: string, ThresholdExpression?: record}
  --resource-tags: list # An optional list of tags to associate with the specified AnomalySubscription (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_AnomalySubscription.html). You can use resource tags to control access to your subscription using IAM policies. Each tag consists of a key and a value, and each key must be unique for the resource. The following restrictions apply to resource tags: Although the maximum number of array members is 200, you can assign a maximum of 50 user-tags to one resource. The remaining are reserved for Amazon Web Services use The maximum length of a key is 128 characters The maximum length of a value is 256 characters Keys and values can only contain alphanumeric characters, spaces, and any of the following: _.:/=+@- Keys and values are case sensitive Keys and values are trimmed for any leading or trailing whitespaces Don’t use aws: as a prefix for your keys. This prefix is reserved for Amazon Web Services use — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.CreateAnomalySubscription"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AnomalySubscription, var: anomaly_subscription}, {name: ResourceTags, var: resource_tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, anomaly_subscription: $anomaly_subscription, resource_tags: $resource_tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Cost Category with the requested name and rules.
#
# POST /
# Returns: record<CostCategoryArn: string, EffectiveStart: string>
# operationId: CreateCostCategoryDefinition
export def "create-cost-category-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The unique name of the Cost Category.
  --effective-start: string # The period of time that you want the usage and costs for.
  rule_version: string@rule-version-completer # The rule schema version in this particular Cost Category.
  rules: list # The Cost Category rules used to categorize costs. For more information, see CostCategoryRule (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_CostCategoryRule.html). — item shape: {Value?: string, Rule?: record, InheritedValue?: record, Type?: "REGULAR"|"INHERITED_VALUE"}
  --default-value: string # The default value for the cost category.
  --split-charge-rules: list # The split charge rules used to allocate your charges between your Cost Category values. — item shape: {Source: string, Targets: list<string>, Method: "FIXED"|"PROPORTIONAL"|"EVEN", Parameters?: list}
  --resource-tags: list # An optional list of tags to associate with the specified CostCategory (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_CostCategory.html). You can use resource tags to control access to your cost category using IAM policies. Each tag consists of a key and a value, and each key must be unique for the resource. The following restrictions apply to resource tags: Although the maximum number of array members is 200, you can assign a maximum of 50 user-tags to one resource. The remaining are reserved for Amazon Web Services use The maximum length of a key is 128 characters The maximum length of a value is 256 characters Keys and values can only contain alphanumeric characters, spaces, and any of the following: _.:/=+@- Keys and values are case sensitive Keys and values are trimmed for any leading or trailing whitespaces Don’t use aws: as a prefix for your keys. This prefix is reserved for Amazon Web Services use — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.CreateCostCategoryDefinition"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: EffectiveStart, var: effective_start}, {name: RuleVersion, var: rule_version}, {name: Rules, var: rules}, {name: DefaultValue, var: default_value}, {name: SplitChargeRules, var: split_charge_rules}, {name: ResourceTags, var: resource_tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, effective_start: $effective_start, rule_version: $rule_version, rules: $rules, default_value: $default_value, split_charge_rules: $split_charge_rules, resource_tags: $resource_tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a cost anomaly monitor.
#
# POST /
# Returns: record
# operationId: DeleteAnomalyMonitor
export def "delete-anomaly-monitor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  monitor_arn: string # The unique identifier of the cost anomaly monitor that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.DeleteAnomalyMonitor"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MonitorArn, var: monitor_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, monitor_arn: $monitor_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a cost anomaly subscription.
#
# POST /
# Returns: record
# operationId: DeleteAnomalySubscription
export def "delete-anomaly-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  subscription_arn: string # The unique identifier of the cost anomaly subscription that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.DeleteAnomalySubscription"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SubscriptionArn, var: subscription_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subscription_arn: $subscription_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Cost Category. Expenses from this month going forward will no longer be categorized with this Cost Category.
#
# POST /
# Returns: record<CostCategoryArn: string, EffectiveEnd: string>
# operationId: DeleteCostCategoryDefinition
export def "delete-cost-category-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  cost_category_arn: string # The unique identifier for your Cost Category.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.DeleteCostCategoryDefinition"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CostCategoryArn, var: cost_category_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cost_category_arn: $cost_category_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the name, Amazon Resource Name (ARN), rules, definition, and effective dates of a Cost Category that's defined in the account. You have the option to use EffectiveOn to return a Cost Category that's active on a specific date. If there's no EffectiveOn specified, you see a Cost Category that's effective on the current date. If Cost Category is still effective, EffectiveEnd is omitted in the response.
#
# POST /
# Returns: record<CostCategory: record<CostCategoryArn: string, EffectiveStart: string, EffectiveEnd: string, Name: string, RuleVersion: string, Rules: list<record>, SplitChargeRules: list<record>, ProcessingStatus: list<record>, DefaultValue: string>>
# operationId: DescribeCostCategoryDefinition
export def "describe-cost-category-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  cost_category_arn: string # The unique identifier for your Cost Category.
  --effective-on: string # The period of time that you want the usage and costs for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.DescribeCostCategoryDefinition"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CostCategoryArn, var: cost_category_arn}, {name: EffectiveOn, var: effective_on}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cost_category_arn: $cost_category_arn, effective_on: $effective_on
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all of the cost anomalies detected on your account during the time period that's specified by the DateInterval object. Anomalies are available for up to 90 days.
#
# POST /
# Returns: record<Anomalies: table<AnomalyId: string, AnomalyStartDate: string, AnomalyEndDate: string, DimensionValue: string, RootCauses: list, AnomalyScore: record, Impact: record, MonitorArn: string, Feedback: string>, NextPageToken: string>
# operationId: GetAnomalies
export def "get-anomalies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --monitor-arn: string # Retrieves all of the cost anomalies detected for a specific cost anomaly monitor Amazon Resource Name (ARN).
  date_interval: record # The time period for an anomaly. — shape: {StartDate: string, EndDate?: string}
  --feedback: string@feedback-completer # Filters anomaly results by the feedback field on the anomaly object.
  --total-impact: record # Filters cost anomalies based on the total impact. — shape: {NumericOperator: "EQUAL"|"GREATER_THAN_OR_EQUAL"|"LESS_THAN_OR_EQUAL"|"GREATER_THAN"|"LESS_THAN"|"BETWEEN", StartValue: float, EndValue?: float}
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
  --max-results: int # The number of entries a paginated response contains.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.GetAnomalies"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MonitorArn, var: monitor_arn}, {name: DateInterval, var: date_interval}, {name: Feedback, var: feedback}, {name: TotalImpact, var: total_impact}, {name: NextPageToken, var: next_page_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, monitor_arn: $monitor_arn, date_interval: $date_interval, feedback: $feedback, total_impact: $total_impact, next_page_token: $next_page_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the cost anomaly monitor definitions for your account. You can filter using a list of cost anomaly monitor Amazon Resource Names (ARNs).
#
# POST /
# Returns: record<AnomalyMonitors: table<MonitorArn: string, MonitorName: string, CreationDate: string, LastUpdatedDate: string, LastEvaluatedDate: string, MonitorType: string, MonitorDimension: string, MonitorSpecification: record, DimensionalValueCount: int>, NextPageToken: string>
# operationId: GetAnomalyMonitors
export def "get-anomaly-monitors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --monitor-arn-list: list<string> # A list of cost anomaly monitor ARNs.
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
  --max-results: int # The number of entries that a paginated response contains.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.GetAnomalyMonitors"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MonitorArnList, var: monitor_arn_list}, {name: NextPageToken, var: next_page_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, monitor_arn_list: $monitor_arn_list, next_page_token: $next_page_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the cost anomaly subscription objects for your account. You can filter using a list of cost anomaly monitor Amazon Resource Names (ARNs).
#
# POST /
# Returns: record<AnomalySubscriptions: table<SubscriptionArn: string, AccountId: string, MonitorArnList: list, Subscribers: list, Threshold: float, Frequency: string, SubscriptionName: string, ThresholdExpression: record>, NextPageToken: string>
# operationId: GetAnomalySubscriptions
export def "get-anomaly-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --subscription-arn-list: list<string> # A list of cost anomaly subscription ARNs.
  --monitor-arn: string # Cost anomaly monitor ARNs.
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
  --max-results: int # The number of entries a paginated response contains.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.GetAnomalySubscriptions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SubscriptionArnList, var: subscription_arn_list}, {name: MonitorArn, var: monitor_arn}, {name: NextPageToken, var: next_page_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subscription_arn_list: $subscription_arn_list, monitor_arn: $monitor_arn, next_page_token: $next_page_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves cost and usage metrics for your account. You can specify which cost and usage-related metric that you want the request to return. For example, you can specify BlendedCosts or UsageQuantity. You can also filter and group your data by various dimensions, such as SERVICE or AZ, in a specific time range. For a complete list of valid dimensions, see the GetDimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetDimensionValues.html) operation. Management account in an organization in Organizations have access to all member accounts. For information about filter limitations, see Quotas and restrictions (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-limits.html) in the Billing and Cost Management User Guide.
#
# POST /
# Returns: record<NextPageToken: string, GroupDefinitions: table<Type: string, Key: string>, ResultsByTime: table<TimePeriod: record, Total: record, Groups: list, Estimated: bool>, DimensionValueAttributes: table<Value: string, Attributes: record>>
# operationId: GetCostAndUsage
export def "get-cost-and-usage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  granularity: string@granularity-completer # Sets the Amazon Web Services cost granularity to MONTHLY or DAILY, or HOURLY. If Granularity isn't set, the response object doesn't include the Granularity, either MONTHLY or DAILY, or HOURLY.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  metrics: list<string> # Which metrics are returned in the query. For more information about blended and unblended rates, see Why does the "blended" annotation appear on some line items in my bill? (http://aws.amazon.com/premiumsupport/knowledge-center/blended-rates-intro/). Valid values are AmortizedCost, BlendedCost, NetAmortizedCost, NetUnblendedCost, NormalizedUsageAmount, UnblendedCost, and UsageQuantity. If you return the UsageQuantity metric, the service aggregates all usage numbers without taking into account the units. For example, if you aggregate usageQuantity across all of Amazon EC2, the results aren't meaningful because Amazon EC2 compute hours and data transfer are measured in different units (for example, hours and GB). To get more meaningful UsageQuantity metrics, filter by UsageType or UsageTypeGroups. Metrics is required for GetCostAndUsage requests.
  --group-by: list # You can group Amazon Web Services costs using up to two different groups, either dimensions, tag keys, cost categories, or any two group by types. Valid values for the DIMENSION type are AZ, INSTANCE_TYPE, LEGAL_ENTITY_NAME, INVOICING_ENTITY, LINKED_ACCOUNT, OPERATION, PLATFORM, PURCHASE_TYPE, SERVICE, TENANCY, RECORD_TYPE, and USAGE_TYPE. When you group by the TAG type and include a valid tag key, you get all tag values, including empty strings. — item shape: {Type?: "DIMENSION"|"TAG"|"COST_CATEGORY", Key?: string}
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.GetCostAndUsage"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TimePeriod, var: time_period}, {name: Granularity, var: granularity}, {name: Filter, var: filter}, {name: Metrics, var: metrics}, {name: GroupBy, var: group_by}, {name: NextPageToken, var: next_page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, time_period: $time_period, granularity: $granularity, filter: $filter, metrics: $metrics, group_by: $group_by, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves cost and usage metrics with resources for your account. You can specify which cost and usage-related metric, such as BlendedCosts or UsageQuantity, that you want the request to return. You can also filter and group your data by various dimensions, such as SERVICE or AZ, in a specific time range. For a complete list of valid dimensions, see the GetDimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetDimensionValues.html) operation. Management account in an organization in Organizations have access to all member accounts. This API is currently available for the Amazon Elastic Compute Cloud – Compute service only. This is an opt-in only feature. You can enable this feature from the Cost Explorer Settings page. For information about how to access the Settings page, see Controlling Access for Cost Explorer (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-access.html) in the Billing and Cost Management User Guide.
#
# POST /
# Returns: record<NextPageToken: string, GroupDefinitions: table<Type: string, Key: string>, ResultsByTime: table<TimePeriod: record, Total: record, Groups: list, Estimated: bool>, DimensionValueAttributes: table<Value: string, Attributes: record>>
# operationId: GetCostAndUsageWithResources
export def "get-cost-and-usage-with-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  granularity: string@granularity-completer # Sets the Amazon Web Services cost granularity to MONTHLY, DAILY, or HOURLY. If Granularity isn't set, the response object doesn't include the Granularity, MONTHLY, DAILY, or HOURLY.
  filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --metrics: list<string> # Which metrics are returned in the query. For more information about blended and unblended rates, see Why does the "blended" annotation appear on some line items in my bill? (http://aws.amazon.com/premiumsupport/knowledge-center/blended-rates-intro/). Valid values are AmortizedCost, BlendedCost, NetAmortizedCost, NetUnblendedCost, NormalizedUsageAmount, UnblendedCost, and UsageQuantity. If you return the UsageQuantity metric, the service aggregates all usage numbers without taking the units into account. For example, if you aggregate usageQuantity across all of Amazon EC2, the results aren't meaningful because Amazon EC2 compute hours and data transfer are measured in different units (for example, hour or GB). To get more meaningful UsageQuantity metrics, filter by UsageType or UsageTypeGroups. Metrics is required for GetCostAndUsageWithResources requests.
  --group-by: list # You can group Amazon Web Services costs using up to two different groups: DIMENSION, TAG, COST_CATEGORY. — item shape: {Type?: "DIMENSION"|"TAG"|"COST_CATEGORY", Key?: string}
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.GetCostAndUsageWithResources"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TimePeriod, var: time_period}, {name: Granularity, var: granularity}, {name: Filter, var: filter}, {name: Metrics, var: metrics}, {name: GroupBy, var: group_by}, {name: NextPageToken, var: next_page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, time_period: $time_period, granularity: $granularity, filter: $filter, metrics: $metrics, group_by: $group_by, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an array of Cost Category names and values incurred cost. If some Cost Category names and values are not associated with any cost, they will not be returned by this API.
#
# POST /
# Returns: record<NextPageToken: string, CostCategoryNames: list<string>, CostCategoryValues: list<string>, ReturnSize: int, TotalSize: int>
# operationId: GetCostCategories
export def "get-cost-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --search-string: string # The value that you want to search the filter values for. If you don't specify a CostCategoryName, SearchString is used to filter Cost Category names that match the SearchString pattern. If you specify a CostCategoryName, SearchString is used to filter Cost Category values that match the SearchString pattern.
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  --cost-category-name: string # The unique name of the Cost Category.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --sort-by: list # The value that you sort the data by. The key represents the cost and usage metrics. The following values are supported: BlendedCost UnblendedCost AmortizedCost NetAmortizedCost NetUnblendedCost UsageQuantity NormalizedUsageAmount The supported key values for the SortOrder value are ASCENDING and DESCENDING. When you use the SortBy value, the NextPageToken and SearchString key values aren't supported. — item shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
  --max-results: int # This field is only used when the SortBy value is provided in the request. The maximum number of objects that are returned for this request. If MaxResults isn't specified with the SortBy value, the request returns 1000 results as the default value for this parameter. For GetCostCategories, MaxResults has an upper quota of 1000.
  --next-page-token: string # If the number of objects that are still available for retrieval exceeds the quota, Amazon Web Services returns a NextPageToken value in the response. To retrieve the next batch of objects, provide the NextPageToken from the previous call in your next request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.GetCostCategories"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SearchString, var: search_string}, {name: TimePeriod, var: time_period}, {name: CostCategoryName, var: cost_category_name}, {name: Filter, var: filter}, {name: SortBy, var: sort_by}, {name: MaxResults, var: max_results}, {name: NextPageToken, var: next_page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, search_string: $search_string, time_period: $time_period, cost_category_name: $cost_category_name, filter: $filter, sort_by: $sort_by, max_results: $max_results, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a forecast for how much Amazon Web Services predicts that you will spend over the forecast time period that you select, based on your past costs.
#
# POST /
# Returns: record<Total: record<Amount: string, Unit: string>, ForecastResultsByTime: table<TimePeriod: record, MeanValue: string, PredictionIntervalLowerBound: string, PredictionIntervalUpperBound: string>>
# operationId: GetCostForecast
export def "get-cost-forecast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  metric: string@metric-completer # Which metric Cost Explorer uses to create your forecast. For more information about blended and unblended rates, see Why does the "blended" annotation appear on some line items in my bill? (http://aws.amazon.com/premiumsupport/knowledge-center/blended-rates-intro/). Valid values for a GetCostForecast call are the following: AMORTIZED_COST BLENDED_COST NET_AMORTIZED_COST NET_UNBLENDED_COST UNBLENDED_COST
  granularity: string@granularity-completer # How granular you want the forecast to be. You can get 3 months of DAILY forecasts or 12 months of MONTHLY forecasts. The GetCostForecast operation supports only DAILY and MONTHLY granularities.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --prediction-interval-level: int # Cost Explorer always returns the mean forecast as a single point. You can request a prediction interval around the mean by specifying a confidence level. The higher the confidence level, the more confident Cost Explorer is about the actual value falling in the prediction interval. Higher confidence levels result in wider prediction intervals.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.GetCostForecast"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TimePeriod, var: time_period}, {name: Metric, var: metric}, {name: Granularity, var: granularity}, {name: Filter, var: filter}, {name: PredictionIntervalLevel, var: prediction_interval_level}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, time_period: $time_period, metric: $metric, granularity: $granularity, filter: $filter, prediction_interval_level: $prediction_interval_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all available filter values for a specified filter over a period of time. You can search the dimension values for an arbitrary string.
#
# POST /
# Returns: record<DimensionValues: table<Value: string, Attributes: record>, ReturnSize: int, TotalSize: int, NextPageToken: string>
# operationId: GetDimensionValues
export def "get-dimension-values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --search-string: string # The value that you want to search the filter values for.
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  dimension: string@dimension-completer # The name of the dimension. Each Dimension is available for a different Context. For more information, see Context. LINK_ACCOUNT_NAME and SERVICE_CODE can only be used in CostCategoryRule (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/AAPI_CostCategoryRule.html).
  --context: string@context-completer # The context for the call to GetDimensionValues. This can be RESERVATIONS or COST_AND_USAGE. The default value is COST_AND_USAGE. If the context is set to RESERVATIONS, the resulting dimension values can be used in the GetReservationUtilization operation. If the context is set to COST_AND_USAGE, the resulting dimension values can be used in the GetCostAndUsage operation. If you set the context to COST_AND_USAGE, you can use the following dimensions for searching: AZ - The Availability Zone. An example is us-east-1a. BILLING_ENTITY - The Amazon Web Services seller that your account is with. Possible values are the following: - Amazon Web Services(Amazon Web Services): The entity that sells Amazon Web Services. - AISPL (Amazon Internet Services Pvt. Ltd.): The local Indian entity that's an acting reseller for Amazon Web Services in India. - Amazon Web Services Marketplace: The entity that supports the sale of solutions that are built on Amazon Web Services by third-party software providers. CACHE_ENGINE - The Amazon ElastiCache operating system. Examples are Windows or Linux. DEPLOYMENT_OPTION - The scope of Amazon Relational Database Service deployments. Valid values are SingleAZ and MultiAZ. DATABASE_ENGINE - The Amazon Relational Database Service database. Examples are Aurora or MySQL. INSTANCE_TYPE - The type of Amazon EC2 instance. An example is m4.xlarge. INSTANCE_TYPE_FAMILY - A family of instance types optimized to fit different use cases. Examples are Compute Optimized (for example, C4, C5, C6g, and C7g), Memory Optimization (for example, R4, R5n, R5b, and R6g). INVOICING_ENTITY - The name of the entity that issues the Amazon Web Services invoice. LEGAL_ENTITY_NAME - The name of the organization that sells you Amazon Web Services services, such as Amazon Web Services. LINKED_ACCOUNT - The description in the attribute map that includes the full name of the member account. The value field contains the Amazon Web Services ID of the member account. OPERATING_SYSTEM - The operating system. Examples are Windows or Linux. OPERATION - The action performed. Examples include RunInstance and CreateBucket. PLATFORM - The Amazon EC2 operating system. Examples are Windows or Linux. PURCHASE_TYPE - The reservation type of the purchase that this usage is related to. Examples include On-Demand Instances and Standard Reserved Instances. RESERVATION_ID - The unique identifier for an Amazon Web Services Reservation Instance. SAVINGS_PLAN_ARN - The unique identifier for your Savings Plans. SAVINGS_PLANS_TYPE - Type of Savings Plans (EC2 Instance or Compute). SERVICE - The Amazon Web Services service such as Amazon DynamoDB. TENANCY - The tenancy of a resource. Examples are shared or dedicated. USAGE_TYPE - The type of usage. An example is DataTransfer-In-Bytes. The response for the GetDimensionValues operation includes a unit attribute. Examples include GB and Hrs. USAGE_TYPE_GROUP - The grouping of common usage types. An example is Amazon EC2: CloudWatch – Alarms. The response for this operation includes a unit attribute. REGION - The Amazon Web Services Region. RECORD_TYPE - The different types of charges such as Reserved Instance (RI) fees, usage costs, tax refunds, and credits. RESOURCE_ID - The unique identifier of the resource. ResourceId is an opt-in feature only available for last 14 days for EC2-Compute Service. If you set the context to RESERVATIONS, you can use the following dimensions for searching: AZ - The Availability Zone. An example is us-east-1a. CACHE_ENGINE - The Amazon ElastiCache operating system. Examples are Windows or Linux. DEPLOYMENT_OPTION - The scope of Amazon Relational Database Service deployments. Valid values are SingleAZ and MultiAZ. INSTANCE_TYPE - The type of Amazon EC2 instance. An example is m4.xlarge. LINKED_ACCOUNT - The description in the attribute map that includes the full name of the member account. The value field contains the Amazon Web Services ID of the member account. PLATFORM - The Amazon EC2 operating system. Examples are Windows or Linux. REGION - The Amazon Web Services Region. SCOPE (Utilization only) - The scope of a Reserved Instance (RI). Values are regional or a single Availability Zone. TAG (Coverage only) - The tags that are associated with a Reserved Instance (RI). TENANCY - The tenancy of a resource. Examples are shared or dedicated. If you set the context to SAVINGS_PLANS, you can use the following dimensions for searching: SAVINGS_PLANS_TYPE - Type of Savings Plans (EC2 Instance or Compute) PAYMENT_OPTION - The payment option for the given Savings Plans (for example, All Upfront) REGION - The Amazon Web Services Region. INSTANCE_TYPE_FAMILY - The family of instances (For example, m5) LINKED_ACCOUNT - The description in the attribute map that includes the full name of the member account. The value field contains the Amazon Web Services ID of the member account. SAVINGS_PLAN_ARN - The unique identifier for your Savings Plans.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --sort-by: list # The value that you want to sort the data by. The key represents cost and usage metrics. The following values are supported: BlendedCost UnblendedCost AmortizedCost NetAmortizedCost NetUnblendedCost UsageQuantity NormalizedUsageAmount The supported values for the SortOrder key are ASCENDING or DESCENDING. When you specify a SortBy paramater, the context must be COST_AND_USAGE. Further, when using SortBy, NextPageToken and SearchString aren't supported. — item shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
  --max-results: int # This field is only used when SortBy is provided in the request. The maximum number of objects that are returned for this request. If MaxResults isn't specified with SortBy, the request returns 1000 results as the default value for this parameter. For GetDimensionValues, MaxResults has an upper limit of 1000.
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.GetDimensionValues"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SearchString, var: search_string}, {name: TimePeriod, var: time_period}, {name: Dimension, var: dimension}, {name: Context, var: context}, {name: Filter, var: filter}, {name: SortBy, var: sort_by}, {name: MaxResults, var: max_results}, {name: NextPageToken, var: next_page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, search_string: $search_string, time_period: $time_period, dimension: $dimension, context: $context, filter: $filter, sort_by: $sort_by, max_results: $max_results, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the reservation coverage for your account, which you can use to see how much of your Amazon Elastic Compute Cloud, Amazon ElastiCache, Amazon Relational Database Service, or Amazon Redshift usage is covered by a reservation. An organization's management account can see the coverage of the associated member accounts. This supports dimensions, Cost Categories, and nested expressions. For any time period, you can filter data about reservation usage by the following dimensions: AZ CACHE_ENGINE DATABASE_ENGINE DEPLOYMENT_OPTION INSTANCE_TYPE LINKED_ACCOUNT OPERATING_SYSTEM PLATFORM REGION SERVICE TAG TENANCY To determine valid values for a dimension, use the GetDimensionValues operation.
#
# POST /
# Returns: record<CoveragesByTime: table<TimePeriod: record, Groups: list, Total: record>, Total: record<CoverageHours: record<OnDemandHours: string, ReservedHours: string, TotalRunningHours: string, CoverageHoursPercentage: string>, CoverageNormalizedUnits: record<OnDemandNormalizedUnits: string, ReservedNormalizedUnits: string, TotalRunningNormalizedUnits: string, CoverageNormalizedUnitsPercentage: string>, CoverageCost: record<OnDemandCost: string>>, NextPageToken: string>
# operationId: GetReservationCoverage
export def "get-reservation-coverage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  --group-by: list # You can group the data by the following attributes: AZ CACHE_ENGINE DATABASE_ENGINE DEPLOYMENT_OPTION INSTANCE_TYPE INVOICING_ENTITY LINKED_ACCOUNT OPERATING_SYSTEM PLATFORM REGION TENANCY — item shape: {Type?: "DIMENSION"|"TAG"|"COST_CATEGORY", Key?: string}
  --granularity: string@granularity-completer # The granularity of the Amazon Web Services cost data for the reservation. Valid values are MONTHLY and DAILY. If GroupBy is set, Granularity can't be set. If Granularity isn't set, the response object doesn't include Granularity, either MONTHLY or DAILY. The GetReservationCoverage operation supports only DAILY and MONTHLY granularities.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --metrics: list<string> # The measurement that you want your reservation coverage reported in. Valid values are Hour, Unit, and Cost. You can use multiple values in a request.
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
  --sort-by: record # The details for how to sort the data. — shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
  --max-results: int # The maximum number of objects that you returned for this request. If more objects are available, in the response, Amazon Web Services provides a NextPageToken value that you can use in a subsequent call to get the next batch of objects.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.GetReservationCoverage"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TimePeriod, var: time_period}, {name: GroupBy, var: group_by}, {name: Granularity, var: granularity}, {name: Filter, var: filter}, {name: Metrics, var: metrics}, {name: NextPageToken, var: next_page_token}, {name: SortBy, var: sort_by}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, time_period: $time_period, group_by: $group_by, granularity: $granularity, filter: $filter, metrics: $metrics, next_page_token: $next_page_token, sort_by: $sort_by, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets recommendations for reservation purchases. These recommendations might help you to reduce your costs. Reservations provide a discounted hourly rate (up to 75%) compared to On-Demand pricing. Amazon Web Services generates your recommendations by identifying your On-Demand usage during a specific time period and collecting your usage into categories that are eligible for a reservation. After Amazon Web Services has these categories, it simulates every combination of reservations in each category of usage to identify the best number of each type of Reserved Instance (RI) to purchase to maximize your estimated savings. For example, Amazon Web Services automatically aggregates your Amazon EC2 Linux, shared tenancy, and c4 family usage in the US West (Oregon) Region and recommends that you buy size-flexible regional reservations to apply to the c4 family usage. Amazon Web Services recommends the smallest size instance in an instance family. This makes it easier to purchase a size-flexible Reserved Instance (RI). Amazon Web Services also shows the equal number of normalized units. This way, you can purchase any instance size that you want. For this example, your RI recommendation is for c4.large because that is the smallest size instance in the c4 instance family.
#
# POST /
# Returns: record<Metadata: record<RecommendationId: string, GenerationTimestamp: string>, Recommendations: table<AccountScope: string, LookbackPeriodInDays: string, TermInYears: string, PaymentOption: string, ServiceSpecification: record, RecommendationDetails: list, RecommendationSummary: record>, NextPageToken: string>
# operationId: GetReservationPurchaseRecommendation
export def "get-reservation-purchase-recommendation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --account-id: string # The account ID that's associated with the recommendation.
  service: string # The specific service that you want recommendations for.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --account-scope: string@account-scope-completer # The account scope that you want your recommendations for. Amazon Web Services calculates recommendations including the management account and member accounts if the value is set to PAYER. If the value is LINKED, recommendations are calculated for individual member accounts only.
  --lookback-period-in-days: string@lookback-period-in-days-completer # The number of previous days that you want Amazon Web Services to consider when it calculates your recommendations.
  --term-in-years: string@term-in-years-completer # The reservation term that you want recommendations for.
  --payment-option: string@payment-option-completer # The reservation purchase option that you want recommendations for.
  --service-specification: record # Hardware specifications for the service that you want recommendations for. — shape: {EC2Specification?: record}
  --page-size: int # The number of recommendations that you want returned in a single response object.
  --next-page-token: string # The pagination token that indicates the next set of results that you want to retrieve.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.GetReservationPurchaseRecommendation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AccountId, var: account_id}, {name: Service, var: service}, {name: Filter, var: filter}, {name: AccountScope, var: account_scope}, {name: LookbackPeriodInDays, var: lookback_period_in_days}, {name: TermInYears, var: term_in_years}, {name: PaymentOption, var: payment_option}, {name: ServiceSpecification, var: service_specification}, {name: PageSize, var: page_size}, {name: NextPageToken, var: next_page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, account_id: $account_id, service: $service, filter: $filter, account_scope: $account_scope, lookback_period_in_days: $lookback_period_in_days, term_in_years: $term_in_years, payment_option: $payment_option, service_specification: $service_specification, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the reservation utilization for your account. Management account in an organization have access to member accounts. You can filter data by dimensions in a time period. You can use GetDimensionValues to determine the possible dimension values. Currently, you can group only by SUBSCRIPTION_ID.
#
# POST /
# Returns: record<UtilizationsByTime: table<TimePeriod: record, Groups: list, Total: record>, Total: record<UtilizationPercentage: string, UtilizationPercentageInUnits: string, PurchasedHours: string, PurchasedUnits: string, TotalActualHours: string, TotalActualUnits: string, UnusedHours: string, UnusedUnits: string, OnDemandCostOfRIHoursUsed: string, NetRISavings: string, TotalPotentialRISavings: string, AmortizedUpfrontFee: string, AmortizedRecurringFee: string, TotalAmortizedFee: string, RICostForUnusedHours: string, RealizedSavings: string, UnrealizedSavings: string>, NextPageToken: string>
# operationId: GetReservationUtilization
export def "get-reservation-utilization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  --group-by: list # Groups only by SUBSCRIPTION_ID. Metadata is included. — item shape: {Type?: "DIMENSION"|"TAG"|"COST_CATEGORY", Key?: string}
  --granularity: string@granularity-completer # If GroupBy is set, Granularity can't be set. If Granularity isn't set, the response object doesn't include Granularity, either MONTHLY or DAILY. If both GroupBy and Granularity aren't set, GetReservationUtilization defaults to DAILY. The GetReservationUtilization operation supports only DAILY and MONTHLY granularities.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --sort-by: record # The details for how to sort the data. — shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
  --max-results: int # The maximum number of objects that you returned for this request. If more objects are available, in the response, Amazon Web Services provides a NextPageToken value that you can use in a subsequent call to get the next batch of objects.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.GetReservationUtilization"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TimePeriod, var: time_period}, {name: GroupBy, var: group_by}, {name: Granularity, var: granularity}, {name: Filter, var: filter}, {name: SortBy, var: sort_by}, {name: NextPageToken, var: next_page_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, time_period: $time_period, group_by: $group_by, granularity: $granularity, filter: $filter, sort_by: $sort_by, next_page_token: $next_page_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates recommendations that help you save cost by identifying idle and underutilized Amazon EC2 instances. Recommendations are generated to either downsize or terminate instances, along with providing savings detail and metrics. For more information about calculation and function, see Optimizing Your Cost with Rightsizing Recommendations (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-rightsizing.html) in the Billing and Cost Management User Guide.
#
# POST /
# Returns: record<Metadata: record<RecommendationId: string, GenerationTimestamp: string, LookbackPeriodInDays: string, AdditionalMetadata: string>, Summary: record<TotalRecommendationCount: string, EstimatedTotalMonthlySavingsAmount: string, SavingsCurrencyCode: string, SavingsPercentage: string>, RightsizingRecommendations: table<AccountId: string, CurrentInstance: record, RightsizingType: string, ModifyRecommendationDetail: record, TerminateRecommendationDetail: record, FindingReasonCodes: list>, NextPageToken: string, Configuration: record<RecommendationTarget: string, BenefitsConsidered: bool>>
# operationId: GetRightsizingRecommendation
export def "get-rightsizing-recommendation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --configuration: record # You can use RightsizingRecommendationConfiguration to customize recommendations across two attributes. You can choose to view recommendations for instances within the same instance families or across different instance families. You can also choose to view your estimated savings that are associated with recommendations with consideration of existing Savings Plans or Reserved Instance (RI) benefits, or neither. — shape: {RecommendationTarget: "SAME_INSTANCE_FAMILY"|"CROSS_INSTANCE_FAMILY", BenefitsConsidered: bool}
  service: string # The specific service that you want recommendations for. The only valid value for GetRightsizingRecommendation is "AmazonEC2".
  --page-size: int # The number of recommendations that you want returned in a single response object.
  --next-page-token: string # The pagination token that indicates the next set of results that you want to retrieve.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.GetRightsizingRecommendation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: Configuration, var: configuration}, {name: Service, var: service}, {name: PageSize, var: page_size}, {name: NextPageToken, var: next_page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, configuration: $configuration, service: $service, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the Savings Plans covered for your account. This enables you to see how much of your cost is covered by a Savings Plan. An organization’s management account can see the coverage of the associated member accounts. This supports dimensions, Cost Categories, and nested expressions. For any time period, you can filter data for Savings Plans usage with the following dimensions: LINKED_ACCOUNT REGION SERVICE INSTANCE_FAMILY To determine valid values for a dimension, use the GetDimensionValues operation.
#
# POST /
# Returns: record<SavingsPlansCoverages: table<Attributes: record, Coverage: record, TimePeriod: record>, NextToken: string>
# operationId: GetSavingsPlansCoverage
export def "get-savings-plans-coverage" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  --group-by: list # You can group the data using the attributes INSTANCE_FAMILY, REGION, or SERVICE. — item shape: {Type?: "DIMENSION"|"TAG"|"COST_CATEGORY", Key?: string}
  --granularity: string@granularity-completer # The granularity of the Amazon Web Services cost data for your Savings Plans. Granularity can't be set if GroupBy is set. The GetSavingsPlansCoverage operation supports only DAILY and MONTHLY granularities.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --metrics: list<string> # The measurement that you want your Savings Plans coverage reported in. The only valid value is SpendCoveredBySavingsPlans.
  --body-next-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size. (spec name: NextToken)
  --body-max-results: int # The number of items to be returned in a response. The default is 20, with a minimum value of 1. (spec name: MaxResults)
  --sort-by: record # The details for how to sort the data. — shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.GetSavingsPlansCoverage"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TimePeriod, var: time_period}, {name: GroupBy, var: group_by}, {name: Granularity, var: granularity}, {name: Filter, var: filter}, {name: Metrics, var: metrics}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: SortBy, var: sort_by}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, time_period: $time_period, group_by: $group_by, granularity: $granularity, filter: $filter, metrics: $metrics, body_next_token: $body_next_token, body_max_results: $body_max_results, sort_by: $sort_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the Savings Plans recommendations for your account. First use StartSavingsPlansPurchaseRecommendationGeneration to generate a new set of recommendations, and then use GetSavingsPlansPurchaseRecommendation to retrieve them.
#
# POST /
# Returns: record<Metadata: record<RecommendationId: string, GenerationTimestamp: string, AdditionalMetadata: string>, SavingsPlansPurchaseRecommendation: record<AccountScope: string, SavingsPlansType: string, TermInYears: string, PaymentOption: string, LookbackPeriodInDays: string, SavingsPlansPurchaseRecommendationDetails: list<record>, SavingsPlansPurchaseRecommendationSummary: record<EstimatedROI: string, CurrencyCode: string, EstimatedTotalCost: string, CurrentOnDemandSpend: string, EstimatedSavingsAmount: string, TotalRecommendationCount: string, DailyCommitmentToPurchase: string, HourlyCommitmentToPurchase: string, EstimatedSavingsPercentage: string, EstimatedMonthlySavingsAmount: string, EstimatedOnDemandCostWithCurrentCommitment: string>>, NextPageToken: string>
# operationId: GetSavingsPlansPurchaseRecommendation
export def "get-savings-plans-purchase-recommendation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  savings_plans_type: string@savings-plans-type-completer # The Savings Plans recommendation type that's requested.
  term_in_years: string@term-in-years-completer # The savings plan recommendation term that's used to generate these recommendations.
  payment_option: string@payment-option-completer # The payment option that's used to generate these recommendations.
  --account-scope: string@account-scope-completer # The account scope that you want your recommendations for. Amazon Web Services calculates recommendations including the management account and member accounts if the value is set to PAYER. If the value is LINKED, recommendations are calculated for individual member accounts only.
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
  --page-size: int # The number of recommendations that you want returned in a single response object.
  lookback_period_in_days: string@lookback-period-in-days-completer # The lookback period that's used to generate the recommendation.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.GetSavingsPlansPurchaseRecommendation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SavingsPlansType, var: savings_plans_type}, {name: TermInYears, var: term_in_years}, {name: PaymentOption, var: payment_option}, {name: AccountScope, var: account_scope}, {name: NextPageToken, var: next_page_token}, {name: PageSize, var: page_size}, {name: LookbackPeriodInDays, var: lookback_period_in_days}, {name: Filter, var: filter}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, savings_plans_type: $savings_plans_type, term_in_years: $term_in_years, payment_option: $payment_option, account_scope: $account_scope, next_page_token: $next_page_token, page_size: $page_size, lookback_period_in_days: $lookback_period_in_days, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the Savings Plans utilization for your account across date ranges with daily or monthly granularity. Management account in an organization have access to member accounts. You can use GetDimensionValues in SAVINGS_PLANS to determine the possible dimension values. You can't group by any dimension values for GetSavingsPlansUtilization.
#
# POST /
# Returns: record<SavingsPlansUtilizationsByTime: table<TimePeriod: record, Utilization: record, Savings: record, AmortizedCommitment: record>, Total: record<Utilization: record<TotalCommitment: string, UsedCommitment: string, UnusedCommitment: string, UtilizationPercentage: string>, Savings: record<NetSavings: string, OnDemandCostEquivalent: string>, AmortizedCommitment: record<AmortizedRecurringCommitment: string, AmortizedUpfrontCommitment: string, TotalAmortizedCommitment: string>>>
# operationId: GetSavingsPlansUtilization
export def "get-savings-plans-utilization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  --granularity: string@granularity-completer # The granularity of the Amazon Web Services utillization data for your Savings Plans. The GetSavingsPlansUtilization operation supports only DAILY and MONTHLY granularities.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --sort-by: record # The details for how to sort the data. — shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.GetSavingsPlansUtilization"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TimePeriod, var: time_period}, {name: Granularity, var: granularity}, {name: Filter, var: filter}, {name: SortBy, var: sort_by}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, time_period: $time_period, granularity: $granularity, filter: $filter, sort_by: $sort_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves attribute data along with aggregate utilization and savings data for a given time period. This doesn't support granular or grouped data (daily/monthly) in response. You can't retrieve data by dates in a single response similar to GetSavingsPlanUtilization, but you have the option to make multiple calls to GetSavingsPlanUtilizationDetails by providing individual dates. You can use GetDimensionValues in SAVINGS_PLANS to determine the possible dimension values. GetSavingsPlanUtilizationDetails internally groups data by SavingsPlansArn.
#
# POST /
# Returns: record<SavingsPlansUtilizationDetails: table<SavingsPlanArn: string, Attributes: record, Utilization: record, Savings: record, AmortizedCommitment: record>, Total: record<Utilization: record<TotalCommitment: string, UsedCommitment: string, UnusedCommitment: string, UtilizationPercentage: string>, Savings: record<NetSavings: string, OnDemandCostEquivalent: string>, AmortizedCommitment: record<AmortizedRecurringCommitment: string, AmortizedUpfrontCommitment: string, TotalAmortizedCommitment: string>>, TimePeriod: record<Start: string, End: string>, NextToken: string>
# operationId: GetSavingsPlansUtilizationDetails
export def "get-savings-plans-utilization-details" [
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
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --data-type: list<string> # The data type.
  --body-next-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size. (spec name: NextToken)
  --body-max-results: int # The number of items to be returned in a response. The default is 20, with a minimum value of 1. (spec name: MaxResults)
  --sort-by: record # The details for how to sort the data. — shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.GetSavingsPlansUtilizationDetails"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TimePeriod, var: time_period}, {name: Filter, var: filter}, {name: DataType, var: data_type}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: SortBy, var: sort_by}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, time_period: $time_period, filter: $filter, data_type: $data_type, body_next_token: $body_next_token, body_max_results: $body_max_results, sort_by: $sort_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Queries for available tag keys and tag values for a specified period. You can search the tag values for an arbitrary string.
#
# POST /
# Returns: record<NextPageToken: string, Tags: list<string>, ReturnSize: int, TotalSize: int>
# operationId: GetTags
export def "get-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --search-string: string # The value that you want to search for.
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  --tag-key: string # The key of the tag that you want to return values for.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --sort-by: list # The value that you want to sort the data by. The key represents cost and usage metrics. The following values are supported: BlendedCost UnblendedCost AmortizedCost NetAmortizedCost NetUnblendedCost UsageQuantity NormalizedUsageAmount The supported values for SortOrder are ASCENDING and DESCENDING. When you use SortBy, NextPageToken and SearchString aren't supported. — item shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
  --max-results: int # This field is only used when SortBy is provided in the request. The maximum number of objects that are returned for this request. If MaxResults isn't specified with SortBy, the request returns 1000 results as the default value for this parameter. For GetTags, MaxResults has an upper quota of 1000.
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.GetTags"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SearchString, var: search_string}, {name: TimePeriod, var: time_period}, {name: TagKey, var: tag_key}, {name: Filter, var: filter}, {name: SortBy, var: sort_by}, {name: MaxResults, var: max_results}, {name: NextPageToken, var: next_page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, search_string: $search_string, time_period: $time_period, tag_key: $tag_key, filter: $filter, sort_by: $sort_by, max_results: $max_results, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a forecast for how much Amazon Web Services predicts that you will use over the forecast time period that you select, based on your past usage.
#
# POST /
# Returns: record<Total: record<Amount: string, Unit: string>, ForecastResultsByTime: table<TimePeriod: record, MeanValue: string, PredictionIntervalLowerBound: string, PredictionIntervalUpperBound: string>>
# operationId: GetUsageForecast
export def "get-usage-forecast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  metric: string@metric-completer # Which metric Cost Explorer uses to create your forecast. Valid values for a GetUsageForecast call are the following: USAGE_QUANTITY NORMALIZED_USAGE_AMOUNT
  granularity: string@granularity-completer # How granular you want the forecast to be. You can get 3 months of DAILY forecasts or 12 months of MONTHLY forecasts. The GetUsageForecast operation supports only DAILY and MONTHLY granularities.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --prediction-interval-level: int # Amazon Web Services Cost Explorer always returns the mean forecast as a single point. You can request a prediction interval around the mean by specifying a confidence level. The higher the confidence level, the more confident Cost Explorer is about the actual value falling in the prediction interval. Higher confidence levels result in wider prediction intervals.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.GetUsageForecast"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TimePeriod, var: time_period}, {name: Metric, var: metric}, {name: Granularity, var: granularity}, {name: Filter, var: filter}, {name: PredictionIntervalLevel, var: prediction_interval_level}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, time_period: $time_period, metric: $metric, granularity: $granularity, filter: $filter, prediction_interval_level: $prediction_interval_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of cost allocation tags. All inputs in the API are optional and serve as filters. By default, all cost allocation tags are returned.
#
# POST /
# Returns: record<CostAllocationTags: table<TagKey: string, Type: string, Status: string>, NextToken: string>
# operationId: ListCostAllocationTags
export def "list-cost-allocation-tags" [
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
  --status: string@status-completer # The status of cost allocation tag keys that are returned for this request.
  --tag-keys: list<string> # The list of cost allocation tag keys that are returned for this request.
  --type: string@type-completer # The type of CostAllocationTag object that are returned for this request. The AWSGenerated type tags are tags that Amazon Web Services defines and applies to support Amazon Web Services resources for cost allocation purposes. The UserDefined type tags are tags that you define, create, and apply to resources.
  --body-next-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size. (spec name: NextToken)
  --body-max-results: int # The maximum number of objects that are returned for this request. By default, the request returns 100 results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.ListCostAllocationTags"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Status, var: status}, {name: TagKeys, var: tag_keys}, {name: Type, var: type}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, status: $status, tag_keys: $tag_keys, type: $type, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the name, Amazon Resource Name (ARN), NumberOfRules and effective dates of all Cost Categories defined in the account. You have the option to use EffectiveOn to return a list of Cost Categories that were active on a specific date. If there is no EffectiveOn specified, you’ll see Cost Categories that are effective on the current date. If Cost Category is still effective, EffectiveEnd is omitted in the response. ListCostCategoryDefinitions supports pagination. The request can have a MaxResults range up to 100.
#
# POST /
# Returns: record<CostCategoryReferences: table<CostCategoryArn: string, Name: string, EffectiveStart: string, EffectiveEnd: string, NumberOfRules: int, ProcessingStatus: list, Values: list, DefaultValue: string>, NextToken: string>
# operationId: ListCostCategoryDefinitions
export def "list-cost-category-definitions" [
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
  --effective-on: string # The period of time that you want the usage and costs for.
  --body-next-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size. (spec name: NextToken)
  --body-max-results: int # The number of entries a paginated response contains. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.ListCostCategoryDefinitions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EffectiveOn, var: effective_on}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, effective_on: $effective_on, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of your historical recommendation generations within the past 30 days.
#
# POST /
# Returns: record<GenerationSummaryList: table<RecommendationId: string, GenerationStatus: string, GenerationStartedTime: string, GenerationCompletionTime: string, EstimatedCompletionTime: string>, NextPageToken: string>
# operationId: ListSavingsPlansPurchaseRecommendationGeneration
export def "list-savings-plans-purchase-recommendation-generation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --generation-status: string@generation-status-completer # The status of the recommendation generation.
  --recommendation-ids: list<string> # The IDs for each specific recommendation.
  --page-size: int # The number of recommendations that you want returned in a single response object.
  --next-page-token: string # The token to retrieve the next set of results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.ListSavingsPlansPurchaseRecommendationGeneration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GenerationStatus, var: generation_status}, {name: RecommendationIds, var: recommendation_ids}, {name: PageSize, var: page_size}, {name: NextPageToken, var: next_page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, generation_status: $generation_status, recommendation_ids: $recommendation_ids, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of resource tags associated with the resource specified by the Amazon Resource Name (ARN).
#
# POST /
# Returns: record<ResourceTags: table<Key: string, Value: string>>
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource. For a list of supported resources, see ResourceTag (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_ResourceTag.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the feedback property of a given cost anomaly.
#
# POST /
# Returns: record<AnomalyId: string>
# operationId: ProvideAnomalyFeedback
export def "provide-anomaly-feedback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  anomaly_id: string # A cost anomaly ID.
  feedback: string@feedback-completer # Describes whether the cost anomaly was a planned activity or you considered it an anomaly.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.ProvideAnomalyFeedback"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AnomalyId, var: anomaly_id}, {name: Feedback, var: feedback}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, anomaly_id: $anomaly_id, feedback: $feedback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests a Savings Plans recommendation generation. This enables you to calculate a fresh set of Savings Plans recommendations that takes your latest usage data and current Savings Plans inventory into account. You can refresh Savings Plans recommendations up to three times daily for a consolidated billing family. StartSavingsPlansPurchaseRecommendationGeneration has no request syntax because no input parameters are needed to support this operation.
#
# POST /
# Returns: record<RecommendationId: string, GenerationStartedTime: string, EstimatedCompletionTime: string>
# operationId: StartSavingsPlansPurchaseRecommendationGeneration
export def "start-savings-plans-purchase-recommendation-generation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.StartSavingsPlansPurchaseRecommendationGeneration"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# An API operation for adding one or more tags (key-value pairs) to a resource. You can use the TagResource operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value you specify replaces the previous value for that tag. Although the maximum number of array members is 200, user-tag maximum is 50. The remaining are reserved for Amazon Web Services use.
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
  --x-amz-target: string@x-amz-target-completer-31 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource. For a list of supported resources, see ResourceTag (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_ResourceTag.html).
  resource_tags: list # A list of tag key-value pairs to be added to the resource. Each tag consists of a key and a value, and each key must be unique for the resource. The following restrictions apply to resource tags: Although the maximum number of array members is 200, you can assign a maximum of 50 user-tags to one resource. The remaining are reserved for Amazon Web Services use The maximum length of a key is 128 characters The maximum length of a value is 256 characters Keys and values can only contain alphanumeric characters, spaces, and any of the following: _.:/=+@- Keys and values are case sensitive Keys and values are trimmed for any leading or trailing whitespaces Don’t use aws: as a prefix for your keys. This prefix is reserved for Amazon Web Services use — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: ResourceTags, var: resource_tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, resource_tags: $resource_tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes one or more tags from a resource. Specify only tag keys in your request. Don't specify the value.
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
  --x-amz-target: string@x-amz-target-completer-32 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource. For a list of supported resources, see ResourceTag (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_ResourceTag.html).
  resource_tag_keys: list<string> # A list of tag keys associated with tags that need to be removed from the resource. If you specify a tag key that doesn't exist, it's ignored. Although the maximum number of array members is 200, user-tag maximum is 50. The remaining are reserved for Amazon Web Services use.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: ResourceTagKeys, var: resource_tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, resource_tag_keys: $resource_tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing cost anomaly monitor. The changes made are applied going forward, and doesn't change anomalies detected in the past.
#
# POST /
# Returns: record<MonitorArn: string>
# operationId: UpdateAnomalyMonitor
export def "update-anomaly-monitor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  monitor_arn: string # Cost anomaly monitor Amazon Resource Names (ARNs).
  --monitor-name: string # The new name for the cost anomaly monitor.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.UpdateAnomalyMonitor"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MonitorArn, var: monitor_arn}, {name: MonitorName, var: monitor_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, monitor_arn: $monitor_arn, monitor_name: $monitor_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing cost anomaly monitor subscription.
#
# POST /
# Returns: record<SubscriptionArn: string>
# operationId: UpdateAnomalySubscription
export def "update-anomaly-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  subscription_arn: string # A cost anomaly subscription Amazon Resource Name (ARN).
  --threshold: float # (deprecated) The update to the threshold value for receiving notifications. This field has been deprecated. To update a threshold, use ThresholdExpression. Continued use of Threshold will be treated as shorthand syntax for a ThresholdExpression.Threshold has been deprecated in favor of ThresholdExpression (format: double)
  --frequency: string@frequency-completer # The update to the frequency value that subscribers receive notifications.
  --monitor-arn-list: list<string> # A list of cost anomaly monitor ARNs.
  --subscribers: list # The update to the subscriber list. — item shape: {Address?: string, Type?: "EMAIL"|"SNS", Status?: "CONFIRMED"|"DECLINED"}
  --subscription-name: string # The new name of the subscription.
  --threshold-expression: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.UpdateAnomalySubscription"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SubscriptionArn, var: subscription_arn}, {name: Threshold, var: threshold}, {name: Frequency, var: frequency}, {name: MonitorArnList, var: monitor_arn_list}, {name: Subscribers, var: subscribers}, {name: SubscriptionName, var: subscription_name}, {name: ThresholdExpression, var: threshold_expression}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subscription_arn: $subscription_arn, threshold: $threshold, frequency: $frequency, monitor_arn_list: $monitor_arn_list, subscribers: $subscribers, subscription_name: $subscription_name, threshold_expression: $threshold_expression
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates status for cost allocation tags in bulk, with maximum batch size of 20. If the tag status that's updated is the same as the existing tag status, the request doesn't fail. Instead, it doesn't have any effect on the tag status (for example, activating the active tag).
#
# POST /
# Returns: record<Errors: table<TagKey: string, Code: string, Message: string>>
# operationId: UpdateCostAllocationTagsStatus
export def "update-cost-allocation-tags-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  cost_allocation_tags_status: list # The list of CostAllocationTagStatusEntry objects that are used to update cost allocation tags status for this request. — item shape: {TagKey: string, Status: "Active"|"Inactive"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.UpdateCostAllocationTagsStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CostAllocationTagsStatus, var: cost_allocation_tags_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cost_allocation_tags_status: $cost_allocation_tags_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Cost Category. Changes made to the Cost Category rules will be used to categorize the current month’s expenses and future expenses. This won’t change categorization for the previous months.
#
# POST /
# Returns: record<CostCategoryArn: string, EffectiveStart: string>
# operationId: UpdateCostCategoryDefinition
export def "update-cost-category-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  cost_category_arn: string # The unique identifier for your Cost Category.
  --effective-start: string # The period of time that you want the usage and costs for.
  rule_version: string@rule-version-completer # The rule schema version in this particular Cost Category.
  rules: list # The Expression object used to categorize costs. For more information, see CostCategoryRule (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_CostCategoryRule.html). — item shape: {Value?: string, Rule?: record, InheritedValue?: record, Type?: "REGULAR"|"INHERITED_VALUE"}
  --default-value: string # The default value for the cost category.
  --split-charge-rules: list # The split charge rules used to allocate your charges between your Cost Category values. — item shape: {Source: string, Targets: list<string>, Method: "FIXED"|"PROPORTIONAL"|"EVEN", Parameters?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSInsightsIndexService.UpdateCostCategoryDefinition"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CostCategoryArn, var: cost_category_arn}, {name: EffectiveStart, var: effective_start}, {name: RuleVersion, var: rule_version}, {name: Rules, var: rules}, {name: DefaultValue, var: default_value}, {name: SplitChargeRules, var: split_charge_rules}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cost_category_arn: $cost_category_arn, effective_start: $effective_start, rule_version: $rule_version, rules: $rules, default_value: $default_value, split_charge_rules: $split_charge_rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
