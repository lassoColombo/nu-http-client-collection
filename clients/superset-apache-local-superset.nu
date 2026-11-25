# Auto-generated client for Superset v1
# Source: https://api.apis.guru/v2/specs/superset.apache.local/superset/v1/openapi.json
# Auth: --token flag or $env.SUPERSET_TOKEN

const CLIENT = {
  base_url: "http://superset.apache.local"
  token_env_var: "SUPERSET_TOKEN"
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

def base-url-completer [] { ["http://superset.apache.local" "https://api.apis.guru/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def datasource-type-completer [] { ["druid" "table" "view"] }
def accept-completer [] { ["application/json" "image/*"] }
def report-format-completer [] { ["CSV" "PNG" "TEXT"] }
def type-completer [] { ["Alert" "Report"] }
def validator-type-completer [] { ["not null" "operator"] }
def provider-completer [] { ["db" "ldap"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    delete-annotation-layer: "record<message: string>"
    get-annotation-layer: "record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<changed_by: record, changed_on: string, changed_on_delta_humanized: any, created_by: record, created_on: string, descr: string, id: int, name: string>>"
    post-annotation-layer: "record<id: float, result: record<descr: string, name: string>>"
    get-annotation-layer-info: "record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>>"
    get-annotation-layer-related-column-name: "record<count: int, result: table<text: string, value: int>>"
    delete-annotation-layer-pk: "record<message: string>"
    get-annotation-layer-pk: "record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<descr: string, id: int, name: string>, show_columns: list<string>, show_title: string>"
    put-annotation-layer-pk: "record<id: float, result: record<descr: string, name: string>>"
    delete-annotation-layer-pk-annotation: "record<message: string>"
    get-annotation-layer-pk-annotation: "record<count: float, ids: list<string>, result: table<changed_by: record, changed_on_delta_humanized: any, created_by: record, end_dttm: string, id: int, long_descr: string, short_descr: string, start_dttm: string>>"
    post-annotation-layer-pk-annotation: "record<id: float, result: record<end_dttm: string, json_metadata: string, long_descr: string, short_descr: string, start_dttm: string>>"
    delete-annotation-layer-pk-annotation-annotation-id: "record<message: string>"
    get-annotation-layer-pk-annotation-annotation-id: "record<id: string, result: record<end_dttm: string, id: int, json_metadata: string, layer: record<id: int, name: string>, long_descr: string, short_descr: string, start_dttm: string>>"
    put-annotation-layer-pk-annotation-annotation-id: "record<id: float, result: record<end_dttm: string, json_metadata: string, long_descr: string, short_descr: string, start_dttm: string>>"
    get-async-event: "record<result: table<channel_id: string, errors: list, id: string, job_id: string, result_url: string, status: string, user_id: int>>"
    delete-chart: "record<message: string>"
    get-chart: "record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<cache_timeout: int, changed_by: record, changed_by_name: any, changed_by_url: any, changed_on_delta_humanized: any, changed_on_utc: any, created_by: record, datasource_id: int, datasource_name_text: any, datasource_type: string, datasource_url: any, description: string, description_markeddown: any, edit_url: any, id: int, owners: record, params: string, slice_name: string, table: record, thumbnail_url: any, url: any, viz_type: string>>"
    post-chart: "record<id: float, result: record<cache_timeout: int, dashboards: list<int>, datasource_id: int, datasource_name: string, datasource_type: string, description: string, owners: list<int>, params: string, query_context: string, slice_name: string, viz_type: string>>"
    get-chart-info: "record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>>"
    post-chart-data: "record<result: table<annotation_data: list, applied_filters: list, cache_key: string, cache_timeout: int, cached_dttm: string, data: list, error: string, is_cached: bool, query: string, rejected_filters: list, rowcount: int, stacktrace: string, status: string>>"
    get-chart-data-cache-key: "record<result: table<annotation_data: list, applied_filters: list, cache_key: string, cache_timeout: int, cached_dttm: string, data: list, error: string, is_cached: bool, query: string, rejected_filters: list, rowcount: int, stacktrace: string, status: string>>"
    get-chart-export: "binary"
    get-chart-favorite-status: "record<result: table<id: int, value: bool>>"
    post-chart-import: "record<message: string>"
    get-chart-related-column-name: "record<count: int, result: table<text: string, value: int>>"
    delete-chart-pk: "record<message: string>"
    get-chart-pk: "record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<cache_timeout: int, dashboards: record<dashboard_title: string, id: int>, description: string, owners: record<first_name: string, id: int, last_name: string, username: string>, params: string, query_context: string, slice_name: string, viz_type: string>, show_columns: list<string>, show_title: string>"
    put-chart-pk: "record<id: float, result: record<cache_timeout: int, dashboards: list<int>, datasource_id: int, datasource_type: string, description: string, owners: list<int>, params: string, query_context: string, slice_name: string, viz_type: string>>"
    get-chart-pk-cache-screenshot: "record<cache_key: string, chart_url: string, image_url: string>"
    get-chart-pk-data: "record<result: table<annotation_data: list, applied_filters: list, cache_key: string, cache_timeout: int, cached_dttm: string, data: list, error: string, is_cached: bool, query: string, rejected_filters: list, rowcount: int, stacktrace: string, status: string>>"
    get-chart-pk-screenshot-digest: "binary"
    get-chart-pk-thumbnail-digest: "binary"
    delete-css-template: "record<message: string>"
    get-css-template: "record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<changed_by: record, changed_on_delta_humanized: any, created_by: record, created_on: string, css: string, id: int, template_name: string>>"
    post-css-template: "record<id: string, result: record<css: string, template_name: string>>"
    get-css-template-info: "record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>>"
    get-css-template-related-column-name: "record<count: int, result: table<text: string, value: int>>"
    delete-css-template-pk: "record<message: string>"
    get-css-template-pk: "record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<created_by: record<first_name: string, id: int, last_name: string>, css: string, id: int, template_name: string>, show_columns: list<string>, show_title: string>"
    put-css-template-pk: "record<result: record<css: string, template_name: string>>"
    delete-dashboard: "record<message: string>"
    get-dashboard: "record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<changed_by: record, changed_by_name: any, changed_by_url: any, changed_on_delta_humanized: any, changed_on_utc: any, created_by: record, css: string, dashboard_title: string, id: int, json_metadata: string, owners: record, position_json: string, published: bool, roles: record, slug: string, status: any, thumbnail_url: any, url: any>>"
    post-dashboard: "record<id: float, result: record<css: string, dashboard_title: string, json_metadata: string, owners: list<int>, position_json: string, published: bool, roles: list<int>, slug: string>>"
    get-dashboard-info: "record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>>"
    get-dashboard-export: "string"
    get-dashboard-favorite-status: "record<result: table<id: int, value: bool>>"
    post-dashboard-import: "record<message: string>"
    get-dashboard-related-column-name: "record<count: int, result: table<text: string, value: int>>"
    get-dashboard-id-or-slug: "record<result: record<changed_by: record<first_name: string, id: int, last_name: string, username: string>, changed_by_name: string, changed_by_url: string, changed_on: string, changed_on_delta_humanized: string, charts: list<string>, css: string, dashboard_title: string, id: int, json_metadata: string, owners: list<record>, position_json: string, published: bool, roles: list<record>, slug: string, table_names: string, thumbnail_url: string, url: string>>"
    get-dashboard-id-or-slug-charts: "record<result: table<cache_timeout: int, changed_on: string, datasource: string, description: string, description_markeddown: string, form_data: record, modified: string, slice_id: int, slice_name: string, slice_url: string>>"
    get-dashboard-id-or-slug-datasets: "record<result: table<cache_timeout: int, column_formats: record, column_types: list, columns: list, database: record, datasource_name: string, default_endpoint: string, edit_url: string, fetch_values_predicate: string, filter_select: bool, filter_select_enabled: bool, granularity_sqla: list, health_check_message: string, id: int, is_sqllab_view: bool, main_dttm_col: string, metrics: list, name: string, offset: int, order_by_choices: list, owners: list, params: string, perm: string, schema: string, select_star: string, sql: string, table_name: string, template_params: string, time_grain_sqla: list, type: string, uid: string, verbose_map: record>>"
    delete-dashboard-pk: "record<message: string>"
    put-dashboard-pk: "record<id: float, result: record<css: string, dashboard_title: string, json_metadata: string, owners: list<int>, position_json: string, published: bool, roles: list<int>, slug: string>>"
    get-dashboard-pk-thumbnail-digest: "binary"
    get-database: "record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<allow_csv_upload: bool, allow_ctas: bool, allow_cvas: bool, allow_dml: bool, allow_multi_schema_metadata_fetch: bool, allow_run_async: bool, allows_cost_estimate: any, allows_subquery: any, allows_virtual_table_explore: any, backend: any, changed_on: string, changed_on_delta_humanized: any, created_by: record, database_name: string, explore_database_id: any, expose_in_sqllab: bool, extra: string, force_ctas_schema: string, id: int>>"
    post-database: "record<id: float, result: record<allow_csv_upload: bool, allow_ctas: bool, allow_cvas: bool, allow_dml: bool, allow_multi_schema_metadata_fetch: bool, allow_run_async: bool, cache_timeout: int, configuration_method: any, database_name: string, encrypted_extra: string, engine: string, expose_in_sqllab: bool, extra: string, force_ctas_schema: string, impersonate_user: bool, parameters: record, server_cert: string, sqlalchemy_uri: string>>"
    get-database-info: "record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>>"
    get-database-available: "table<available_drivers: list<string>, default_driver: string, engine: string, name: string, parameters: record, preferred: bool, sqlalchemy_uri_placeholder: string>"
    get-database-export: "binary"
    post-database-import: "record<message: string>"
    post-database-test-connection: "record<message: string>"
    post-database-validate-parameters: "record<message: string>"
    delete-database-pk: "record<message: string>"
    get-database-pk: "record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<allow_csv_upload: bool, allow_ctas: bool, allow_cvas: bool, allow_dml: bool, allow_multi_schema_metadata_fetch: bool, allow_run_async: bool, backend: any, cache_timeout: int, configuration_method: string, database_name: string, encrypted_extra: string, expose_in_sqllab: bool, extra: string, force_ctas_schema: string, id: int, impersonate_user: bool, parameters: any, server_cert: string, sqlalchemy_uri: string>, show_columns: list<string>, show_title: string>"
    put-database-pk: "record<id: float, result: record<allow_csv_upload: bool, allow_ctas: bool, allow_cvas: bool, allow_dml: bool, allow_multi_schema_metadata_fetch: bool, allow_run_async: bool, cache_timeout: int, configuration_method: any, database_name: string, encrypted_extra: string, engine: string, expose_in_sqllab: bool, extra: string, force_ctas_schema: string, impersonate_user: bool, parameters: record, server_cert: string, sqlalchemy_uri: string>>"
    get-database-pk-function-names: "record<function_names: list<string>>"
    get-database-pk-related-objects: "record<charts: record<count: int, result: list<record>>, dashboards: record<count: int, result: list<record>>>"
    get-database-pk-schemas: "record<result: list<string>>"
    get-database-pk-select-star-table-name: "record<result: string>"
    get-database-pk-select-star-table-name-schema-name: "record<result: string>"
    get-database-pk-table-table-name-schema-name: "record<columns: table<duplicates_constraint: string, keys: list, longType: string, name: string, type: string>, foreignKeys: table<column_names: list, name: string, options: record, referred_columns: list, referred_schema: string, referred_table: string, type: string>, indexes: table<column_names: list, name: string, options: record, referred_columns: list, referred_schema: string, referred_table: string, type: string>, name: string, primaryKey: record<column_names: list<string>, name: string, type: string>, selectStar: string>"
    delete-dataset: "record<message: string>"
    get-dataset: "record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<changed_by: record, changed_by_name: any, changed_by_url: any, changed_on_delta_humanized: any, changed_on_utc: any, database: record, default_endpoint: string, explore_url: any, extra: string, id: int, kind: any, owners: record, schema: string, sql: string, table_name: string>>"
    post-dataset: "record<id: float, result: record<database: int, owners: list<int>, schema: string, table_name: string>>"
    get-dataset-info: "record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>>"
    get-dataset-distinct-column-name: "record<count: int, result: table<text: string>>"
    get-dataset-export: "string"
    post-dataset-import: "record<message: string>"
    get-dataset-related-column-name: "record<count: int, result: table<text: string, value: int>>"
    delete-dataset-pk: "record<message: string>"
    get-dataset-pk: "record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<cache_timeout: int, columns: record<changed_on: string, column_name: string, created_on: string, description: string, expression: string, filterable: bool, groupby: bool, id: int, is_active: bool, is_dttm: bool, python_date_format: string, type: string, type_generic: any, uuid: string, verbose_name: string>, database: record<database_name: string, id: int>, datasource_type: any, default_endpoint: string, description: string, extra: string, fetch_values_predicate: string, filter_select_enabled: bool, id: int, is_sqllab_view: bool, main_dttm_col: string, metrics: record<changed_on: string, created_on: string, d3format: string, description: string, expression: string, extra: string, id: int, metric_name: string, metric_type: string, uuid: string, verbose_name: string, warning_text: string>, offset: int, owners: record<first_name: string, id: int, last_name: string, username: string>, schema: string, sql: string, table_name: string, template_params: string, url: any>, show_columns: list<string>, show_title: string>"
    put-dataset-pk: "record<id: float, result: record<cache_timeout: int, columns: list<record>, database_id: int, default_endpoint: string, description: string, extra: string, fetch_values_predicate: string, filter_select_enabled: bool, is_sqllab_view: bool, main_dttm_col: string, metrics: list<record>, offset: int, owners: list<int>, schema: string, sql: string, table_name: string, template_params: string>>"
    delete-dataset-pk-column-column-id: "record<message: string>"
    delete-dataset-pk-metric-metric-id: "record<message: string>"
    put-dataset-pk-refresh: "record<message: string>"
    get-dataset-pk-related-objects: "record<charts: record<count: int, result: list<record>>, dashboards: record<count: int, result: list<record>>>"
    get-log: "record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<action: string, dashboard_id: int, dttm: string, duration_ms: int, json: string, referrer: string, slice_id: int, user: record, user_id: int>>"
    post-log: "record<id: string, result: record<id: int>>"
    get-log-pk: "record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<action: string, dashboard_id: int, dttm: string, duration_ms: int, json: string, referrer: string, slice_id: int, user: record<username: string>, user_id: int>, show_columns: list<string>, show_title: string>"
    get-menu: "record<result: table<childs: list, icon: string, label: string, name: string, url: string>>"
    get-openapi-version-openapi: "record"
    get-query: "record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<changed_on: string, database: record, end_time: float, executed_sql: string, id: int, rows: int, schema: string, sql: string, sql_tables: any, start_time: float, status: string, tab_name: string, tmp_table_name: string, tracking_url: string, user: record>>"
    get-query-distinct-column-name: "record<count: int, result: table<text: string>>"
    get-query-related-column-name: "record<count: int, result: table<text: string, value: int>>"
    get-query-pk: "record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<changed_on: string, client_id: string, database: record<id: int>, end_result_backend_time: float, end_time: float, error_message: string, executed_sql: string, id: int, limit: int, progress: int, results_key: string, rows: int, schema: string, select_as_cta: bool, select_as_cta_used: bool, select_sql: string, sql: string, sql_editor_id: string, start_running_time: float, start_time: float, status: string, tab_name: string, tmp_schema_name: string, tmp_table_name: string, tracking_url: string>, show_columns: list<string>, show_title: string>"
    delete-report: "record<message: string>"
    get-report: "record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<active: bool, changed_by: record, changed_on: string, changed_on_delta_humanized: any, created_by: record, created_on: string, creation_method: string, crontab: string, crontab_humanized: any, description: string, id: int, last_eval_dttm: string, last_state: string, name: string, owners: record, recipients: record, timezone: string, type: string>>"
    post-report: "record<id: float, result: record<active: bool, chart: int, context_markdown: string, creation_method: any, crontab: string, dashboard: int, database: int, description: string, grace_period: int, log_retention: int, name: string, owners: list<int>, recipients: list<record>, report_format: string, sql: string, timezone: string, type: string, validator_config_json: record<op: string, threshold: int>, validator_type: string, working_timeout: int>>"
    get-report-info: "record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>>"
    get-report-related-column-name: "record<count: int, result: table<text: string, value: int>>"
    delete-report-pk: "record<message: string>"
    get-report-pk: "record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<active: bool, chart: record<id: int, slice_name: string, viz_type: string>, context_markdown: string, creation_method: string, crontab: string, dashboard: record<dashboard_title: string, id: int>, database: record<database_name: string, id: int>, description: string, grace_period: int, id: int, last_eval_dttm: string, last_state: string, last_value: float, last_value_row_json: string, log_retention: int, name: string, owners: record<first_name: string, id: int, last_name: string>, recipients: record<id: int, recipient_config_json: string, type: string>, report_format: string, sql: string, timezone: string, type: string, validator_config_json: string, validator_type: string, working_timeout: int>, show_columns: list<string>, show_title: string>"
    put-report-pk: "record<id: float, result: record<active: bool, chart: int, context_markdown: string, creation_method: any, crontab: string, dashboard: int, database: int, description: string, grace_period: int, log_retention: int, name: string, owners: list<int>, recipients: list<record>, report_format: string, sql: string, timezone: string, type: string, validator_config_json: record<op: string, threshold: int>, validator_type: string, working_timeout: int>>"
    get-report-pk-log: "record<count: float, ids: list<string>, result: table<end_dttm: string, error_message: string, id: int, scheduled_dttm: string, start_dttm: string, state: string, uuid: string, value: float, value_row_json: string>>"
    get-report-pk-log-log-id: "record<id: string, result: record<end_dttm: string, error_message: string, id: int, scheduled_dttm: string, start_dttm: string, state: string, uuid: string, value: float, value_row_json: string>>"
    delete-saved-query: "record<message: string>"
    get-saved-query: "record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<changed_on_delta_humanized: any, created_by: record, created_on: string, database: record, db_id: int, description: string, extra: any, id: int, label: string, last_run_delta_humanized: any, rows: int, schema: string, sql: string, sql_tables: any>>"
    post-saved-query: "record<id: string, result: record<db_id: int, description: string, label: string, schema: string, sql: string>>"
    get-saved-query-info: "record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>>"
    get-saved-query-distinct-column-name: "record<count: int, result: table<text: string>>"
    get-saved-query-export: "binary"
    post-saved-query-import: "record<message: string>"
    get-saved-query-related-column-name: "record<count: int, result: table<text: string, value: int>>"
    delete-saved-query-pk: "record<message: string>"
    get-saved-query-pk: "record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<created_by: record<first_name: string, id: int, last_name: string>, database: record<database_name: string, id: int>, description: string, id: int, label: string, schema: string, sql: string, sql_tables: any>, show_columns: list<string>, show_title: string>"
    put-saved-query-pk: "record<result: record<db_id: int, description: string, label: string, schema: string, sql: string>>"
    get-security-csrf-token: "record<result: string>"
    post-security-login: "record<access_token: string, refresh_token: string>"
    post-security-refresh: "record<access_token: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["delete-annotation-layer" "get-annotation-layer" "post-annotation-layer" "get-annotation-layer-info" "get-annotation-layer-related-column-name" "delete-annotation-layer-pk" "get-annotation-layer-pk" "put-annotation-layer-pk" "delete-annotation-layer-pk-annotation" "get-annotation-layer-pk-annotation" "post-annotation-layer-pk-annotation" "delete-annotation-layer-pk-annotation-annotation-id" "get-annotation-layer-pk-annotation-annotation-id" "put-annotation-layer-pk-annotation-annotation-id" "get-async-event" "post-cachekey-invalidate" "delete-chart" "get-chart" "post-chart" "get-chart-info" "post-chart-data" "get-chart-data-cache-key" "get-chart-export" "get-chart-favorite-status" "post-chart-import" "get-chart-related-column-name" "delete-chart-pk" "get-chart-pk" "put-chart-pk" "get-chart-pk-cache-screenshot" "get-chart-pk-data" "get-chart-pk-screenshot-digest" "get-chart-pk-thumbnail-digest" "delete-css-template" "get-css-template" "post-css-template" "get-css-template-info" "get-css-template-related-column-name" "delete-css-template-pk" "get-css-template-pk" "put-css-template-pk" "delete-dashboard" "get-dashboard" "post-dashboard" "get-dashboard-info" "get-dashboard-export" "get-dashboard-favorite-status" "post-dashboard-import" "get-dashboard-related-column-name" "get-dashboard-id-or-slug" "get-dashboard-id-or-slug-charts" "get-dashboard-id-or-slug-datasets" "delete-dashboard-pk" "put-dashboard-pk" "get-dashboard-pk-thumbnail-digest" "get-database" "post-database" "get-database-info" "get-database-available" "get-database-export" "post-database-import" "post-database-test-connection" "post-database-validate-parameters" "delete-database-pk" "get-database-pk" "put-database-pk" "get-database-pk-function-names" "get-database-pk-related-objects" "get-database-pk-schemas" "get-database-pk-select-star-table-name" "get-database-pk-select-star-table-name-schema-name" "get-database-pk-table-table-name-schema-name" "delete-dataset" "get-dataset" "post-dataset" "get-dataset-info" "get-dataset-distinct-column-name" "get-dataset-export" "post-dataset-import" "get-dataset-related-column-name" "delete-dataset-pk" "get-dataset-pk" "put-dataset-pk" "delete-dataset-pk-column-column-id" "delete-dataset-pk-metric-metric-id" "put-dataset-pk-refresh" "get-dataset-pk-related-objects" "get-log" "post-log" "get-log-pk" "get-menu" "get-openapi-version-openapi" "get-query" "get-query-distinct-column-name" "get-query-related-column-name" "get-query-pk" "delete-report" "get-report" "post-report" "get-report-info" "get-report-related-column-name" "delete-report-pk" "get-report-pk" "put-report-pk" "get-report-pk-log" "get-report-pk-log-log-id" "delete-saved-query" "get-saved-query" "post-saved-query" "get-saved-query-info" "get-saved-query-distinct-column-name" "get-saved-query-export" "post-saved-query-import" "get-saved-query-related-column-name" "delete-saved-query-pk" "get-saved-query-pk" "put-saved-query-pk" "get-security-csrf-token" "post-security-login" "post-security-refresh" "commands"] | sort) } | get name | first)
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

# Deletes multiple annotation layers in a bulk operation.
#
# DELETE /annotation_layer/
# Returns: record<message: string>
export def "delete-annotation-layer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/annotation_layer/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of Annotation layers, use Rison or JSON query parameters for filtering, sorting, pagination and for selecting specific columns and metadata.
#
# GET /annotation_layer/
# Returns: record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<changed_by: record, changed_on: string, changed_on_delta_humanized: any, created_by: record, created_on: string, descr: string, id: int, name: string>>
export def "get-annotation-layer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/annotation_layer/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Annotation layer
#
# POST /annotation_layer/
# Returns: record<id: float, result: record<descr: string, name: string>>
export def "post-annotation-layer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --descr: string # Give a description for this annotation layer (nullable)
  --name: string # The annotation layer name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/annotation_layer/"
    body: {content_type: "application/json", kind: json, fields: [{name: descr, var: descr}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    descr: $descr, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata information about this API resource
#
# GET /annotation_layer/_info
# Returns: record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>>
export def "get-annotation-layer-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/annotation_layer/_info"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /annotation_layer/related/{column_name}
#
# Returns: record<count: int, result: table<text: string, value: int>>
export def "get-annotation-layer-related-column-name" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/annotation_layer/related/{column_name}"
    path_params: [{name: column_name, var: column_name}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    column_name: $column_name, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Annotation layer
#
# DELETE /annotation_layer/{pk}
# Returns: record<message: string>
export def "delete-annotation-layer-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/annotation_layer/{pk}"
    path_params: [{name: pk, var: pk}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Annotation layer
#
# GET /annotation_layer/{pk}
# Returns: record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<descr: string, id: int, name: string>, show_columns: list<string>, show_title: string>
export def "get-annotation-layer-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/annotation_layer/{pk}"
    path_params: [{name: pk, var: pk}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an Annotation layer
#
# PUT /annotation_layer/{pk}
# Returns: record<id: float, result: record<descr: string, name: string>>
export def "put-annotation-layer-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --descr: string # Give a description for this annotation layer
  --name: string # The annotation layer name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/annotation_layer/{pk}"
    path_params: [{name: pk, var: pk}]
    body: {content_type: "application/json", kind: json, fields: [{name: descr, var: descr}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, descr: $descr, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes multiple annotation in a bulk operation.
#
# DELETE /annotation_layer/{pk}/annotation/
# Returns: record<message: string>
export def "delete-annotation-layer-pk-annotation" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/annotation_layer/{pk}/annotation/"
    path_params: [{name: pk, var: pk}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of Annotation layers, use Rison or JSON query parameters for filtering, sorting, pagination and for selecting specific columns and metadata.
#
# GET /annotation_layer/{pk}/annotation/
# Returns: record<count: float, ids: list<string>, result: table<changed_by: record, changed_on_delta_humanized: any, created_by: record, end_dttm: string, id: int, long_descr: string, short_descr: string, start_dttm: string>>
export def "get-annotation-layer-pk-annotation" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/annotation_layer/{pk}/annotation/"
    path_params: [{name: pk, var: pk}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Annotation layer
#
# POST /annotation_layer/{pk}/annotation/
# Returns: record<id: float, result: record<end_dttm: string, json_metadata: string, long_descr: string, short_descr: string, start_dttm: string>>
export def "post-annotation-layer-pk-annotation" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-dttm: string # The annotation end date time (format: date-time)
  --json-metadata: string # JSON metadata (nullable)
  --long-descr: string # A long description (nullable)
  --short-descr: string # A short description
  --start-dttm: string # The annotation start date time (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/annotation_layer/{pk}/annotation/"
    path_params: [{name: pk, var: pk}]
    body: {content_type: "application/json", kind: json, fields: [{name: end_dttm, var: end_dttm}, {name: json_metadata, var: json_metadata}, {name: long_descr, var: long_descr}, {name: short_descr, var: short_descr}, {name: start_dttm, var: start_dttm}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    pk: $pk, end_dttm: $end_dttm, json_metadata: $json_metadata, long_descr: $long_descr, short_descr: $short_descr, start_dttm: $start_dttm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Annotation layer
#
# DELETE /annotation_layer/{pk}/annotation/{annotation_id}
# Returns: record<message: string>
export def "delete-annotation-layer-pk-annotation-annotation-id" [
  pk: int
  annotation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/annotation_layer/{pk}/annotation/{annotation_id}"
    path_params: [{name: pk, var: pk}, {name: annotation_id, var: annotation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, annotation_id: $annotation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Annotation layer
#
# GET /annotation_layer/{pk}/annotation/{annotation_id}
# Returns: record<id: string, result: record<end_dttm: string, id: int, json_metadata: string, layer: record<id: int, name: string>, long_descr: string, short_descr: string, start_dttm: string>>
export def "get-annotation-layer-pk-annotation-annotation-id" [
  pk: int
  annotation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/annotation_layer/{pk}/annotation/{annotation_id}"
    path_params: [{name: pk, var: pk}, {name: annotation_id, var: annotation_id}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, annotation_id: $annotation_id, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an Annotation layer
#
# PUT /annotation_layer/{pk}/annotation/{annotation_id}
# Returns: record<id: float, result: record<end_dttm: string, json_metadata: string, long_descr: string, short_descr: string, start_dttm: string>>
export def "put-annotation-layer-pk-annotation-annotation-id" [
  pk: int
  annotation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-dttm: string # The annotation end date time (format: date-time)
  --json-metadata: string # JSON metadata
  --long-descr: string # A long description
  --short-descr: string # A short description
  --start-dttm: string # The annotation start date time (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/annotation_layer/{pk}/annotation/{annotation_id}"
    path_params: [{name: pk, var: pk}, {name: annotation_id, var: annotation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: end_dttm, var: end_dttm}, {name: json_metadata, var: json_metadata}, {name: long_descr, var: long_descr}, {name: short_descr, var: short_descr}, {name: start_dttm, var: start_dttm}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, annotation_id: $annotation_id, end_dttm: $end_dttm, json_metadata: $json_metadata, long_descr: $long_descr, short_descr: $short_descr, start_dttm: $start_dttm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reads off of the Redis events stream, using the user's JWT token and optional query params for last event received.
#
# GET /async_event/
# Returns: record<result: table<channel_id: string, errors: list, id: string, job_id: string, result_url: string, status: string, user_id: int>>
export def "get-async-event" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-id: string # Last ID received by the client
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/async_event/"
    query: [{name: last_id, var: last_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    last_id: $last_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Takes a list of datasources, finds the associated cache records and invalidates them and removes the database records
#
# POST /cachekey/invalidate
export def "post-cachekey-invalidate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource-uids: list<string> # The uid of the dataset/datasource this new chart will use. A complete datasource identification needs `datasouce_uid`
  --datasources: list # A list of the data source and database names — item shape: {database_name?: string, datasource_name?: string, datasource_type: "druid"|"table"|"view", schema?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/cachekey/invalidate"
    body: {content_type: "application/json", kind: json, fields: [{name: datasource_uids, var: datasource_uids}, {name: datasources, var: datasources}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    datasource_uids: $datasource_uids, datasources: $datasources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes multiple Charts in a bulk operation.
#
# DELETE /chart/
# Returns: record<message: string>
export def "delete-chart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/chart/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of charts, use Rison or JSON query parameters for filtering, sorting, pagination and for selecting specific columns and metadata.
#
# GET /chart/
# Returns: record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<cache_timeout: int, changed_by: record, changed_by_name: any, changed_by_url: any, changed_on_delta_humanized: any, changed_on_utc: any, created_by: record, datasource_id: int, datasource_name_text: any, datasource_type: string, datasource_url: any, description: string, description_markeddown: any, edit_url: any, id: int, owners: record, params: string, slice_name: string, table: record, thumbnail_url: any, url: any, viz_type: string>>
export def "get-chart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/chart/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Chart.
#
# POST /chart/
# Returns: record<id: float, result: record<cache_timeout: int, dashboards: list<int>, datasource_id: int, datasource_name: string, datasource_type: string, description: string, owners: list<int>, params: string, query_context: string, slice_name: string, viz_type: string>>
export def "post-chart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-timeout: int # Duration (in seconds) of the caching timeout for this chart. Note this defaults to the datasource/table timeout if undefined. (nullable, format: int32)
  --dashboards: list<int>
  datasource_id: int # The id of the dataset/datasource this new chart will use. A complete datasource identification needs `datasouce_id` and `datasource_type`. (format: int32)
  --datasource-name: string # The datasource name. (nullable)
  datasource_type: string@datasource-type-completer # The type of dataset/datasource identified on `datasource_id`.
  --description: string # A description of the chart propose. (nullable)
  --owners: list<int>
  --params: string # Parameters are generated dynamically when clicking the save or overwrite button in the explore view. This JSON object for power users who may want to alter specific parameters. (nullable)
  --query-context: string # The query context represents the queries that need to run in order to generate the data the visualization, and in what format the data should be returned. (nullable)
  slice_name: string # The name of the chart.
  --viz-type: string # The type of chart visualization used. (e.g. [bar, line_multi, area, table])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/chart/"
    body: {content_type: "application/json", kind: json, fields: [{name: cache_timeout, var: cache_timeout}, {name: dashboards, var: dashboards}, {name: datasource_id, var: datasource_id}, {name: datasource_name, var: datasource_name}, {name: datasource_type, var: datasource_type}, {name: description, var: description}, {name: owners, var: owners}, {name: params, var: params}, {name: query_context, var: query_context}, {name: slice_name, var: slice_name}, {name: viz_type, var: viz_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    cache_timeout: $cache_timeout, dashboards: $dashboards, datasource_id: $datasource_id, datasource_name: $datasource_name, datasource_type: $datasource_type, description: $description, owners: $owners, params: $params, query_context: $query_context, slice_name: $slice_name, viz_type: $viz_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Several metadata information about chart API endpoints.
#
# GET /chart/_info
# Returns: record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>>
export def "get-chart-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/chart/_info"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Takes a query context constructed in the client and returns payload data response for the given query.
#
# POST /chart/data
# Returns: record<result: table<annotation_data: list, applied_filters: list, cache_key: string, cache_timeout: int, cached_dttm: string, data: list, error: string, is_cached: bool, query: string, rejected_filters: list, rowcount: int, stacktrace: string, status: string>>
export def "post-chart-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: record # shape: {id: int, type?: "druid"|"table"}
  --force: oneof<nothing, bool> # Should the queries be forced to load from the source. Default: `false`
  --queries: list # item shape: {annotation_layers?: list, applied_time_extras?: record, apply_fetch_values_predicate?: bool, columns?: list<string>, datasource?: record, druid_time_origin?: string, extras?: record, filters?: list, granularity?: string, granularity_sqla?: string, groupby?: list<string>, having?: string, having_filters?: list, is_rowcount?: bool, is_timeseries?: bool, metrics?: list, order_desc?: bool, orderby?: list, post_processing?: list, result_type?: any, row_limit?: int, row_offset?: int, ... (7 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/chart/data"
    body: {content_type: "application/json", kind: json, fields: [{name: datasource, var: datasource}, {name: force, var: force}, {name: queries, var: queries}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    datasource: $datasource, force: $force, queries: $queries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Takes a query context cache key and returns payload data response for the given query.
#
# GET /chart/data/{cache_key}
# Returns: record<result: table<annotation_data: list, applied_filters: list, cache_key: string, cache_timeout: int, cached_dttm: string, data: list, error: string, is_cached: bool, query: string, rejected_filters: list, rowcount: int, stacktrace: string, status: string>>
export def "get-chart-data-cache-key" [
  cache_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/chart/data/{cache_key}"
    path_params: [{name: cache_key, var: cache_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cache_key: $cache_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports multiple charts and downloads them as YAML files
#
# GET /chart/export/
# Returns: binary
export def "get-chart-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> any {
  http-request {
    method: get
    path: "/chart/export/"
    query: [{name: q, var: q}]
    accept: ["application/zip"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check favorited dashboards for current user
#
# GET /chart/favorite_status/
# Returns: record<result: table<id: int, value: bool>>
export def "get-chart-favorite-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/chart/favorite_status/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /chart/import/
#
# Returns: record<message: string>
export def "post-chart-import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-data: string # upload file (ZIP) (format: binary)
  --overwrite: oneof<nothing, bool> # overwrite existing databases?
  --passwords: string # JSON map of passwords for each file
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/chart/import/"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: formData, var: form_data}, {name: overwrite, var: overwrite}, {name: passwords, var: passwords}], files: [formData]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    form_data: $form_data, overwrite: $overwrite, passwords: $passwords
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all possible owners for a chart. Use `owners` has the `column_name` parameter
#
# GET /chart/related/{column_name}
# Returns: record<count: int, result: table<text: string, value: int>>
export def "get-chart-related-column-name" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/chart/related/{column_name}"
    path_params: [{name: column_name, var: column_name}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    column_name: $column_name, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Chart.
#
# DELETE /chart/{pk}
# Returns: record<message: string>
export def "delete-chart-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/chart/{pk}"
    path_params: [{name: pk, var: pk}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a chart detail information.
#
# GET /chart/{pk}
# Returns: record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<cache_timeout: int, dashboards: record<dashboard_title: string, id: int>, description: string, owners: record<first_name: string, id: int, last_name: string, username: string>, params: string, query_context: string, slice_name: string, viz_type: string>, show_columns: list<string>, show_title: string>
export def "get-chart-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/chart/{pk}"
    path_params: [{name: pk, var: pk}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes a Chart.
#
# PUT /chart/{pk}
# Returns: record<id: float, result: record<cache_timeout: int, dashboards: list<int>, datasource_id: int, datasource_type: string, description: string, owners: list<int>, params: string, query_context: string, slice_name: string, viz_type: string>>
export def "put-chart-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-timeout: int # Duration (in seconds) of the caching timeout for this chart. Note this defaults to the datasource/table timeout if undefined. (nullable, format: int32)
  --dashboards: list<int>
  --datasource-id: int # The id of the dataset/datasource this new chart will use. A complete datasource identification needs `datasouce_id` and `datasource_type`. (nullable, format: int32)
  --datasource-type: string@datasource-type-completer # The type of dataset/datasource identified on `datasource_id`. (nullable)
  --description: string # A description of the chart propose. (nullable)
  --owners: list<int>
  --params: string # Parameters are generated dynamically when clicking the save or overwrite button in the explore view. This JSON object for power users who may want to alter specific parameters. (nullable)
  --query-context: string # The query context represents the queries that need to run in order to generate the data the visualization, and in what format the data should be returned. (nullable)
  --slice-name: string # The name of the chart. (nullable)
  --viz-type: string # The type of chart visualization used. (nullable, e.g. [bar, line_multi, area, table])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/chart/{pk}"
    path_params: [{name: pk, var: pk}]
    body: {content_type: "application/json", kind: json, fields: [{name: cache_timeout, var: cache_timeout}, {name: dashboards, var: dashboards}, {name: datasource_id, var: datasource_id}, {name: datasource_type, var: datasource_type}, {name: description, var: description}, {name: owners, var: owners}, {name: params, var: params}, {name: query_context, var: query_context}, {name: slice_name, var: slice_name}, {name: viz_type, var: viz_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, cache_timeout: $cache_timeout, dashboards: $dashboards, datasource_id: $datasource_id, datasource_type: $datasource_type, description: $description, owners: $owners, params: $params, query_context: $query_context, slice_name: $slice_name, viz_type: $viz_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compute and cache a screenshot.
#
# GET /chart/{pk}/cache_screenshot/
# Returns: record<cache_key: string, chart_url: string, image_url: string>
export def "get-chart-pk-cache-screenshot" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/chart/{pk}/cache_screenshot/"
    path_params: [{name: pk, var: pk}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200, 302]
    auth: bearer
  } {
    pk: $pk, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Takes a chart ID and uses the query context stored when the chart was saved to return payload data response.
#
# GET /chart/{pk}/data/
# Returns: record<result: table<annotation_data: list, applied_filters: list, cache_key: string, cache_timeout: int, cached_dttm: string, data: list, error: string, is_cached: bool, query: string, rejected_filters: list, rowcount: int, stacktrace: string, status: string>>
export def "get-chart-pk-data" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # The format in which the data should be returned
  --type: string # The type in which the data should be returned
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/chart/{pk}/data/"
    path_params: [{name: pk, var: pk}]
    query: [{name: format, var: format}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    pk: $pk, format: $format, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a computed screenshot from cache.
#
# GET /chart/{pk}/screenshot/{digest}/
# Returns: binary
export def "get-chart-pk-screenshot-digest" [
  pk: int
  digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/chart/{pk}/screenshot/{digest}/"
    path_params: [{name: pk, var: pk}, {name: digest, var: digest}]
    accept: ["image/*"]
    ok: [200, 302]
    auth: bearer
  } {
    pk: $pk, digest: $digest
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compute or get already computed chart thumbnail from cache.
#
# GET /chart/{pk}/thumbnail/{digest}/
# Returns: binary
export def "get-chart-pk-thumbnail-digest" [
  pk: int
  digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/chart/{pk}/thumbnail/{digest}/"
    path_params: [{name: pk, var: pk}, {name: digest, var: digest}]
    accept: ["image/*"]
    ok: [200, 302]
    auth: bearer
  } {
    pk: $pk, digest: $digest
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes multiple css templates in a bulk operation.
#
# DELETE /css_template/
# Returns: record<message: string>
export def "delete-css-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/css_template/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of CSS templates, use Rison or JSON query parameters for filtering, sorting, pagination and for selecting specific columns and metadata.
#
# GET /css_template/
# Returns: record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<changed_by: record, changed_on_delta_humanized: any, created_by: record, created_on: string, css: string, id: int, template_name: string>>
export def "get-css-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/css_template/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a CSS template
#
# POST /css_template/
# Returns: record<id: string, result: record<css: string, template_name: string>>
export def "post-css-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --css: string # nullable
  --template-name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/css_template/"
    body: {content_type: "application/json", kind: json, fields: [{name: css, var: css}, {name: template_name, var: template_name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    css: $css, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata information about this API resource
#
# GET /css_template/_info
# Returns: record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>>
export def "get-css-template-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/css_template/_info"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /css_template/related/{column_name}
#
# Returns: record<count: int, result: table<text: string, value: int>>
export def "get-css-template-related-column-name" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/css_template/related/{column_name}"
    path_params: [{name: column_name, var: column_name}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    column_name: $column_name, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete CSS template
#
# DELETE /css_template/{pk}
# Returns: record<message: string>
export def "delete-css-template-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/css_template/{pk}"
    path_params: [{name: pk, var: pk}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a CSS template
#
# GET /css_template/{pk}
# Returns: record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<created_by: record<first_name: string, id: int, last_name: string>, css: string, id: int, template_name: string>, show_columns: list<string>, show_title: string>
export def "get-css-template-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/css_template/{pk}"
    path_params: [{name: pk, var: pk}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a CSS template
#
# PUT /css_template/{pk}
# Returns: record<result: record<css: string, template_name: string>>
export def "put-css-template-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --css: string # nullable
  --template-name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/css_template/{pk}"
    path_params: [{name: pk, var: pk}]
    body: {content_type: "application/json", kind: json, fields: [{name: css, var: css}, {name: template_name, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, css: $css, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes multiple Dashboards in a bulk operation.
#
# DELETE /dashboard/
# Returns: record<message: string>
export def "delete-dashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/dashboard/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of dashboards, use Rison or JSON query parameters for filtering, sorting, pagination and for selecting specific columns and metadata.
#
# GET /dashboard/
# Returns: record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<changed_by: record, changed_by_name: any, changed_by_url: any, changed_on_delta_humanized: any, changed_on_utc: any, created_by: record, css: string, dashboard_title: string, id: int, json_metadata: string, owners: record, position_json: string, published: bool, roles: record, slug: string, status: any, thumbnail_url: any, url: any>>
export def "get-dashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dashboard/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Dashboard.
#
# POST /dashboard/
# Returns: record<id: float, result: record<css: string, dashboard_title: string, json_metadata: string, owners: list<int>, position_json: string, published: bool, roles: list<int>, slug: string>>
export def "post-dashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --css: string
  --dashboard-title: string # A title for the dashboard. (nullable)
  --json-metadata: string # This JSON object is generated dynamically when clicking the save or overwrite button in the dashboard view. It is exposed here for reference and for power users who may want to alter specific parameters.
  --owners: list<int>
  --position-json: string # This json object describes the positioning of the widgets in the dashboard. It is dynamically generated when adjusting the widgets size and positions by using drag & drop in the dashboard view
  --published: oneof<nothing, bool> # Determines whether or not this dashboard is visible in the list of all dashboards.
  --roles: list<int>
  --slug: string # Unique identifying part for the web address of the dashboard. (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dashboard/"
    body: {content_type: "application/json", kind: json, fields: [{name: css, var: css}, {name: dashboard_title, var: dashboard_title}, {name: json_metadata, var: json_metadata}, {name: owners, var: owners}, {name: position_json, var: position_json}, {name: published, var: published}, {name: roles, var: roles}, {name: slug, var: slug}]}
    accept: ["application/json"]
    ok: [201, 302]
    auth: bearer
  } {
    css: $css, dashboard_title: $dashboard_title, json_metadata: $json_metadata, owners: $owners, position_json: $position_json, published: $published, roles: $roles, slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Several metadata information about dashboard API endpoints.
#
# GET /dashboard/_info
# Returns: record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>>
export def "get-dashboard-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dashboard/_info"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports multiple Dashboards and downloads them as YAML files.
#
# GET /dashboard/export/
# Returns: string
export def "get-dashboard-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> any {
  http-request {
    method: get
    path: "/dashboard/export/"
    query: [{name: q, var: q}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check favorited dashboards for current user
#
# GET /dashboard/favorite_status/
# Returns: record<result: table<id: int, value: bool>>
export def "get-dashboard-favorite-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dashboard/favorite_status/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /dashboard/import/
#
# Returns: record<message: string>
export def "post-dashboard-import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-data: string # upload file (ZIP or JSON) (format: binary)
  --overwrite: oneof<nothing, bool> # overwrite existing databases?
  --passwords: string # JSON map of passwords for each file
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dashboard/import/"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: formData, var: form_data}, {name: overwrite, var: overwrite}, {name: passwords, var: passwords}], files: [formData]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    form_data: $form_data, overwrite: $overwrite, passwords: $passwords
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all possible owners for a dashboard.
#
# GET /dashboard/related/{column_name}
# Returns: record<count: int, result: table<text: string, value: int>>
export def "get-dashboard-related-column-name" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dashboard/related/{column_name}"
    path_params: [{name: column_name, var: column_name}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    column_name: $column_name, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a dashboard detail information.
#
# GET /dashboard/{id_or_slug}
# Returns: record<result: record<changed_by: record<first_name: string, id: int, last_name: string, username: string>, changed_by_name: string, changed_by_url: string, changed_on: string, changed_on_delta_humanized: string, charts: list<string>, css: string, dashboard_title: string, id: int, json_metadata: string, owners: list<record>, position_json: string, published: bool, roles: list<record>, slug: string, table_names: string, thumbnail_url: string, url: string>>
export def "get-dashboard-id-or-slug" [
  id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dashboard/{id_or_slug}"
    path_params: [{name: id_or_slug, var: id_or_slug}]
    accept: ["application/json"]
    ok: [200, 302]
    auth: bearer
  } {
    id_or_slug: $id_or_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the chart definitions for a given dashboard
#
# GET /dashboard/{id_or_slug}/charts
# Returns: record<result: table<cache_timeout: int, changed_on: string, datasource: string, description: string, description_markeddown: string, form_data: record, modified: string, slice_id: int, slice_name: string, slice_url: string>>
export def "get-dashboard-id-or-slug-charts" [
  id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dashboard/{id_or_slug}/charts"
    path_params: [{name: id_or_slug, var: id_or_slug}]
    accept: ["application/json"]
    ok: [200, 302]
    auth: bearer
  } {
    id_or_slug: $id_or_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of a dashboard's datasets. Each dataset includes only the information necessary to render the dashboard's charts.
#
# GET /dashboard/{id_or_slug}/datasets
# Returns: record<result: table<cache_timeout: int, column_formats: record, column_types: list, columns: list, database: record, datasource_name: string, default_endpoint: string, edit_url: string, fetch_values_predicate: string, filter_select: bool, filter_select_enabled: bool, granularity_sqla: list, health_check_message: string, id: int, is_sqllab_view: bool, main_dttm_col: string, metrics: list, name: string, offset: int, order_by_choices: list, owners: list, params: string, perm: string, schema: string, select_star: string, sql: string, table_name: string, template_params: string, time_grain_sqla: list, type: string, uid: string, verbose_map: record>>
export def "get-dashboard-id-or-slug-datasets" [
  id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dashboard/{id_or_slug}/datasets"
    path_params: [{name: id_or_slug, var: id_or_slug}]
    accept: ["application/json"]
    ok: [200, 302]
    auth: bearer
  } {
    id_or_slug: $id_or_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Dashboard.
#
# DELETE /dashboard/{pk}
# Returns: record<message: string>
export def "delete-dashboard-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/dashboard/{pk}"
    path_params: [{name: pk, var: pk}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes a Dashboard.
#
# PUT /dashboard/{pk}
# Returns: record<id: float, result: record<css: string, dashboard_title: string, json_metadata: string, owners: list<int>, position_json: string, published: bool, roles: list<int>, slug: string>>
export def "put-dashboard-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --css: string # Override CSS for the dashboard. (nullable)
  --dashboard-title: string # A title for the dashboard. (nullable)
  --json-metadata: string # This JSON object is generated dynamically when clicking the save or overwrite button in the dashboard view. It is exposed here for reference and for power users who may want to alter specific parameters. (nullable)
  --owners: list<int>
  --position-json: string # This json object describes the positioning of the widgets in the dashboard. It is dynamically generated when adjusting the widgets size and positions by using drag & drop in the dashboard view (nullable)
  --published: oneof<nothing, bool> # Determines whether or not this dashboard is visible in the list of all dashboards. (nullable)
  --roles: list<int>
  --slug: string # Unique identifying part for the web address of the dashboard. (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/dashboard/{pk}"
    path_params: [{name: pk, var: pk}]
    body: {content_type: "application/json", kind: json, fields: [{name: css, var: css}, {name: dashboard_title, var: dashboard_title}, {name: json_metadata, var: json_metadata}, {name: owners, var: owners}, {name: position_json, var: position_json}, {name: published, var: published}, {name: roles, var: roles}, {name: slug, var: slug}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, css: $css, dashboard_title: $dashboard_title, json_metadata: $json_metadata, owners: $owners, position_json: $position_json, published: $published, roles: $roles, slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compute async or get already computed dashboard thumbnail from cache.
#
# GET /dashboard/{pk}/thumbnail/{digest}/
# Returns: binary
export def "get-dashboard-pk-thumbnail-digest" [
  pk: int
  digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --q: string
]: nothing -> any {
  http-request {
    method: get
    path: "/dashboard/{pk}/thumbnail/{digest}/"
    path_params: [{name: pk, var: pk}, {name: digest, var: digest}]
    query: [{name: q, var: q}]
    accept: ["image/*", "application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    pk: $pk, digest: $digest, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of models
#
# GET /database/
# Returns: record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<allow_csv_upload: bool, allow_ctas: bool, allow_cvas: bool, allow_dml: bool, allow_multi_schema_metadata_fetch: bool, allow_run_async: bool, allows_cost_estimate: any, allows_subquery: any, allows_virtual_table_explore: any, backend: any, changed_on: string, changed_on_delta_humanized: any, created_by: record, database_name: string, explore_database_id: any, expose_in_sqllab: bool, extra: string, force_ctas_schema: string, id: int>>
export def "get-database" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/database/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Database.
#
# POST /database/
# Returns: record<id: float, result: record<allow_csv_upload: bool, allow_ctas: bool, allow_cvas: bool, allow_dml: bool, allow_multi_schema_metadata_fetch: bool, allow_run_async: bool, cache_timeout: int, configuration_method: any, database_name: string, encrypted_extra: string, engine: string, expose_in_sqllab: bool, extra: string, force_ctas_schema: string, impersonate_user: bool, parameters: record, server_cert: string, sqlalchemy_uri: string>>
export def "post-database" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-csv-upload: oneof<nothing, bool> # Allow to upload CSV file data into this databaseIf selected, please set the schemas allowed for csv upload in Extra.
  --allow-ctas: oneof<nothing, bool> # Allow CREATE TABLE AS option in SQL Lab
  --allow-cvas: oneof<nothing, bool> # Allow CREATE VIEW AS option in SQL Lab
  --allow-dml: oneof<nothing, bool> # Allow users to run non-SELECT statements (UPDATE, DELETE, CREATE, ...) in SQL Lab
  --allow-multi-schema-metadata-fetch: oneof<nothing, bool> # Allow SQL Lab to fetch a list of all tables and all views across all database schemas. For large data warehouse with thousands of tables, this can be expensive and put strain on the system.
  --allow-run-async: oneof<nothing, bool> # Operate the database in asynchronous mode, meaning that the queries are executed on remote workers as opposed to on the web server itself. This assumes that you have a Celery worker setup as well as a results backend. Refer to the installation docs for more information.
  --cache-timeout: int # Duration (in seconds) of the caching timeout for charts of this database. A timeout of 0 indicates that the cache never expires. Note this defaults to the global timeout if undefined. (nullable, format: int32)
  --configuration-method: any # Configuration_method is used on the frontend to inform the backend whether to explode parameters or to provide only a sqlalchemy_uri. (default: sqlalchemy_form)
  database_name: string # A database name to identify this connection.
  --encrypted-extra: string # JSON string containing additional connection configuration.This is used to provide connection information for systems like Hive, Presto, and BigQuery, which do not conform to the username:password syntax normally used by SQLAlchemy. (nullable)
  --engine: string # SQLAlchemy engine to use (nullable)
  --expose-in-sqllab: oneof<nothing, bool> # Expose this database to SQLLab
  --extra: string # JSON string containing extra configuration elements.1. The engine_params object gets unpacked into the sqlalchemy.create_engine (https://docs.sqlalchemy.org/en/latest/core/engines.html#sqlalchemy.create_engine) call, while the metadata_params gets unpacked into the sqlalchemy.MetaData (https://docs.sqlalchemy.org/en/rel_1_0/core/metadata.html#sqlalchemy.schema.MetaData) call.2. The metadata_cache_timeout is a cache timeout setting in seconds for metadata fetch of this database. Specify it as "metadata_cache_timeout": {"schema_cache_timeout": 600, "table_cache_timeout": 600}. If unset, cache will not be enabled for the functionality. A timeout of 0 indicates that the cache never expires.3. The schemas_allowed_for_csv_upload is a comma separated list of schemas that CSVs are allowed to upload to. Specify it as "schemas_allowed_for_csv_upload": ["public", "csv_upload"]. If database flavor does not support schema or any schema is allowed to be accessed, just leave the list empty4. the version field is a string specifying the this db's version. This should be used with Presto DBs so that the syntax is correct5. The allows_virtual_table_explore field is a boolean specifying whether or not the Explore button in SQL Lab results is shown.
  --force-ctas-schema: string # When allowing CREATE TABLE AS option in SQL Lab, this option forces the table to be created in this schema (nullable)
  --impersonate-user: oneof<nothing, bool> # If Presto, all the queries in SQL Lab are going to be executed as the currently logged on user who must have permission to run them.If Hive and hive.server2.enable.doAs is enabled, will run the queries as service account, but impersonate the currently logged on user via hive.server2.proxy.user property.
  --parameters: record # DB-specific parameters for configuration
  --server-cert: string # Optional CA_BUNDLE contents to validate HTTPS requests. Only available on certain database engines. (nullable)
  --sqlalchemy-uri: string # Refer to the SqlAlchemy docs (https://docs.sqlalchemy.org/en/rel_1_2/core/engines.html#database-urls) for more information on how to structure your URI.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/database/"
    body: {content_type: "application/json", kind: json, fields: [{name: allow_csv_upload, var: allow_csv_upload}, {name: allow_ctas, var: allow_ctas}, {name: allow_cvas, var: allow_cvas}, {name: allow_dml, var: allow_dml}, {name: allow_multi_schema_metadata_fetch, var: allow_multi_schema_metadata_fetch}, {name: allow_run_async, var: allow_run_async}, {name: cache_timeout, var: cache_timeout}, {name: configuration_method, var: configuration_method}, {name: database_name, var: database_name}, {name: encrypted_extra, var: encrypted_extra}, {name: engine, var: engine}, {name: expose_in_sqllab, var: expose_in_sqllab}, {name: extra, var: extra}, {name: force_ctas_schema, var: force_ctas_schema}, {name: impersonate_user, var: impersonate_user}, {name: parameters, var: parameters}, {name: server_cert, var: server_cert}, {name: sqlalchemy_uri, var: sqlalchemy_uri}]}
    accept: ["application/json"]
    ok: [201, 302]
    auth: bearer
  } {
    allow_csv_upload: $allow_csv_upload, allow_ctas: $allow_ctas, allow_cvas: $allow_cvas, allow_dml: $allow_dml, allow_multi_schema_metadata_fetch: $allow_multi_schema_metadata_fetch, allow_run_async: $allow_run_async, cache_timeout: $cache_timeout, configuration_method: $configuration_method, database_name: $database_name, encrypted_extra: $encrypted_extra, engine: $engine, expose_in_sqllab: $expose_in_sqllab, extra: $extra, force_ctas_schema: $force_ctas_schema, impersonate_user: $impersonate_user, parameters: $parameters, server_cert: $server_cert, sqlalchemy_uri: $sqlalchemy_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata information about this API resource
#
# GET /database/_info
# Returns: record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>>
export def "get-database-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/database/_info"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get names of databases currently available
#
# GET /database/available/
# Returns: table<available_drivers: list<string>, default_driver: string, engine: string, name: string, parameters: record, preferred: bool, sqlalchemy_uri_placeholder: string>
export def "get-database-available" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/database/available/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download database(s) and associated dataset(s) as a zip file
#
# GET /database/export/
# Returns: binary
export def "get-database-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> any {
  http-request {
    method: get
    path: "/database/export/"
    query: [{name: q, var: q}]
    accept: ["application/zip"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /database/import/
#
# Returns: record<message: string>
export def "post-database-import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-data: string # upload file (ZIP) (format: binary)
  --overwrite: oneof<nothing, bool> # overwrite existing databases?
  --passwords: string # JSON map of passwords for each file
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/database/import/"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: formData, var: form_data}, {name: overwrite, var: overwrite}, {name: passwords, var: passwords}], files: [formData]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    form_data: $form_data, overwrite: $overwrite, passwords: $passwords
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tests a database connection
#
# POST /database/test_connection
# Returns: record<message: string>
export def "post-database-test-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --configuration-method: any # Configuration_method is used on the frontend to inform the backend whether to explode parameters or to provide only a sqlalchemy_uri. (default: sqlalchemy_form)
  --database-name: string # A database name to identify this connection. (nullable)
  --encrypted-extra: string # JSON string containing additional connection configuration.This is used to provide connection information for systems like Hive, Presto, and BigQuery, which do not conform to the username:password syntax normally used by SQLAlchemy. (nullable)
  --engine: string # SQLAlchemy engine to use (nullable)
  --extra: string # JSON string containing extra configuration elements.1. The engine_params object gets unpacked into the sqlalchemy.create_engine (https://docs.sqlalchemy.org/en/latest/core/engines.html#sqlalchemy.create_engine) call, while the metadata_params gets unpacked into the sqlalchemy.MetaData (https://docs.sqlalchemy.org/en/rel_1_0/core/metadata.html#sqlalchemy.schema.MetaData) call.2. The metadata_cache_timeout is a cache timeout setting in seconds for metadata fetch of this database. Specify it as "metadata_cache_timeout": {"schema_cache_timeout": 600, "table_cache_timeout": 600}. If unset, cache will not be enabled for the functionality. A timeout of 0 indicates that the cache never expires.3. The schemas_allowed_for_csv_upload is a comma separated list of schemas that CSVs are allowed to upload to. Specify it as "schemas_allowed_for_csv_upload": ["public", "csv_upload"]. If database flavor does not support schema or any schema is allowed to be accessed, just leave the list empty4. the version field is a string specifying the this db's version. This should be used with Presto DBs so that the syntax is correct5. The allows_virtual_table_explore field is a boolean specifying whether or not the Explore button in SQL Lab results is shown.
  --impersonate-user: oneof<nothing, bool> # If Presto, all the queries in SQL Lab are going to be executed as the currently logged on user who must have permission to run them.If Hive and hive.server2.enable.doAs is enabled, will run the queries as service account, but impersonate the currently logged on user via hive.server2.proxy.user property.
  --parameters: record # DB-specific parameters for configuration
  --server-cert: string # Optional CA_BUNDLE contents to validate HTTPS requests. Only available on certain database engines. (nullable)
  --sqlalchemy-uri: string # Refer to the SqlAlchemy docs (https://docs.sqlalchemy.org/en/rel_1_2/core/engines.html#database-urls) for more information on how to structure your URI.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/database/test_connection"
    body: {content_type: "application/json", kind: json, fields: [{name: configuration_method, var: configuration_method}, {name: database_name, var: database_name}, {name: encrypted_extra, var: encrypted_extra}, {name: engine, var: engine}, {name: extra, var: extra}, {name: impersonate_user, var: impersonate_user}, {name: parameters, var: parameters}, {name: server_cert, var: server_cert}, {name: sqlalchemy_uri, var: sqlalchemy_uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    configuration_method: $configuration_method, database_name: $database_name, encrypted_extra: $encrypted_extra, engine: $engine, extra: $extra, impersonate_user: $impersonate_user, parameters: $parameters, server_cert: $server_cert, sqlalchemy_uri: $sqlalchemy_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates parameters used to connect to a database
#
# POST /database/validate_parameters
# Returns: record<message: string>
export def "post-database-validate-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  configuration_method: any # Configuration_method is used on the frontend to inform the backend whether to explode parameters or to provide only a sqlalchemy_uri.
  --database-name: string # A database name to identify this connection. (nullable)
  --encrypted-extra: string # JSON string containing additional connection configuration.This is used to provide connection information for systems like Hive, Presto, and BigQuery, which do not conform to the username:password syntax normally used by SQLAlchemy. (nullable)
  engine: string # SQLAlchemy engine to use
  --extra: string # JSON string containing extra configuration elements.1. The engine_params object gets unpacked into the sqlalchemy.create_engine (https://docs.sqlalchemy.org/en/latest/core/engines.html#sqlalchemy.create_engine) call, while the metadata_params gets unpacked into the sqlalchemy.MetaData (https://docs.sqlalchemy.org/en/rel_1_0/core/metadata.html#sqlalchemy.schema.MetaData) call.2. The metadata_cache_timeout is a cache timeout setting in seconds for metadata fetch of this database. Specify it as "metadata_cache_timeout": {"schema_cache_timeout": 600, "table_cache_timeout": 600}. If unset, cache will not be enabled for the functionality. A timeout of 0 indicates that the cache never expires.3. The schemas_allowed_for_csv_upload is a comma separated list of schemas that CSVs are allowed to upload to. Specify it as "schemas_allowed_for_csv_upload": ["public", "csv_upload"]. If database flavor does not support schema or any schema is allowed to be accessed, just leave the list empty4. the version field is a string specifying the this db's version. This should be used with Presto DBs so that the syntax is correct5. The allows_virtual_table_explore field is a boolean specifying whether or not the Explore button in SQL Lab results is shown.
  --impersonate-user: oneof<nothing, bool> # If Presto, all the queries in SQL Lab are going to be executed as the currently logged on user who must have permission to run them.If Hive and hive.server2.enable.doAs is enabled, will run the queries as service account, but impersonate the currently logged on user via hive.server2.proxy.user property.
  --parameters: record # DB-specific parameters for configuration
  --server-cert: string # Optional CA_BUNDLE contents to validate HTTPS requests. Only available on certain database engines. (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/database/validate_parameters"
    body: {content_type: "application/json", kind: json, fields: [{name: configuration_method, var: configuration_method}, {name: database_name, var: database_name}, {name: encrypted_extra, var: encrypted_extra}, {name: engine, var: engine}, {name: extra, var: extra}, {name: impersonate_user, var: impersonate_user}, {name: parameters, var: parameters}, {name: server_cert, var: server_cert}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    configuration_method: $configuration_method, database_name: $database_name, encrypted_extra: $encrypted_extra, engine: $engine, extra: $extra, impersonate_user: $impersonate_user, parameters: $parameters, server_cert: $server_cert
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Database.
#
# DELETE /database/{pk}
# Returns: record<message: string>
export def "delete-database-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/database/{pk}"
    path_params: [{name: pk, var: pk}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an item model
#
# GET /database/{pk}
# Returns: record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<allow_csv_upload: bool, allow_ctas: bool, allow_cvas: bool, allow_dml: bool, allow_multi_schema_metadata_fetch: bool, allow_run_async: bool, backend: any, cache_timeout: int, configuration_method: string, database_name: string, encrypted_extra: string, expose_in_sqllab: bool, extra: string, force_ctas_schema: string, id: int, impersonate_user: bool, parameters: any, server_cert: string, sqlalchemy_uri: string>, show_columns: list<string>, show_title: string>
export def "get-database-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/database/{pk}"
    path_params: [{name: pk, var: pk}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes a Database.
#
# PUT /database/{pk}
# Returns: record<id: float, result: record<allow_csv_upload: bool, allow_ctas: bool, allow_cvas: bool, allow_dml: bool, allow_multi_schema_metadata_fetch: bool, allow_run_async: bool, cache_timeout: int, configuration_method: any, database_name: string, encrypted_extra: string, engine: string, expose_in_sqllab: bool, extra: string, force_ctas_schema: string, impersonate_user: bool, parameters: record, server_cert: string, sqlalchemy_uri: string>>
export def "put-database-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-csv-upload: oneof<nothing, bool> # Allow to upload CSV file data into this databaseIf selected, please set the schemas allowed for csv upload in Extra.
  --allow-ctas: oneof<nothing, bool> # Allow CREATE TABLE AS option in SQL Lab
  --allow-cvas: oneof<nothing, bool> # Allow CREATE VIEW AS option in SQL Lab
  --allow-dml: oneof<nothing, bool> # Allow users to run non-SELECT statements (UPDATE, DELETE, CREATE, ...) in SQL Lab
  --allow-multi-schema-metadata-fetch: oneof<nothing, bool> # Allow SQL Lab to fetch a list of all tables and all views across all database schemas. For large data warehouse with thousands of tables, this can be expensive and put strain on the system.
  --allow-run-async: oneof<nothing, bool> # Operate the database in asynchronous mode, meaning that the queries are executed on remote workers as opposed to on the web server itself. This assumes that you have a Celery worker setup as well as a results backend. Refer to the installation docs for more information.
  --cache-timeout: int # Duration (in seconds) of the caching timeout for charts of this database. A timeout of 0 indicates that the cache never expires. Note this defaults to the global timeout if undefined. (nullable, format: int32)
  --configuration-method: any # Configuration_method is used on the frontend to inform the backend whether to explode parameters or to provide only a sqlalchemy_uri. (default: sqlalchemy_form)
  --database-name: string # A database name to identify this connection. (nullable)
  --encrypted-extra: string # JSON string containing additional connection configuration.This is used to provide connection information for systems like Hive, Presto, and BigQuery, which do not conform to the username:password syntax normally used by SQLAlchemy. (nullable)
  --engine: string # SQLAlchemy engine to use (nullable)
  --expose-in-sqllab: oneof<nothing, bool> # Expose this database to SQLLab
  --extra: string # JSON string containing extra configuration elements.1. The engine_params object gets unpacked into the sqlalchemy.create_engine (https://docs.sqlalchemy.org/en/latest/core/engines.html#sqlalchemy.create_engine) call, while the metadata_params gets unpacked into the sqlalchemy.MetaData (https://docs.sqlalchemy.org/en/rel_1_0/core/metadata.html#sqlalchemy.schema.MetaData) call.2. The metadata_cache_timeout is a cache timeout setting in seconds for metadata fetch of this database. Specify it as "metadata_cache_timeout": {"schema_cache_timeout": 600, "table_cache_timeout": 600}. If unset, cache will not be enabled for the functionality. A timeout of 0 indicates that the cache never expires.3. The schemas_allowed_for_csv_upload is a comma separated list of schemas that CSVs are allowed to upload to. Specify it as "schemas_allowed_for_csv_upload": ["public", "csv_upload"]. If database flavor does not support schema or any schema is allowed to be accessed, just leave the list empty4. the version field is a string specifying the this db's version. This should be used with Presto DBs so that the syntax is correct5. The allows_virtual_table_explore field is a boolean specifying whether or not the Explore button in SQL Lab results is shown.
  --force-ctas-schema: string # When allowing CREATE TABLE AS option in SQL Lab, this option forces the table to be created in this schema (nullable)
  --impersonate-user: oneof<nothing, bool> # If Presto, all the queries in SQL Lab are going to be executed as the currently logged on user who must have permission to run them.If Hive and hive.server2.enable.doAs is enabled, will run the queries as service account, but impersonate the currently logged on user via hive.server2.proxy.user property.
  --parameters: record # DB-specific parameters for configuration
  --server-cert: string # Optional CA_BUNDLE contents to validate HTTPS requests. Only available on certain database engines. (nullable)
  --sqlalchemy-uri: string # Refer to the SqlAlchemy docs (https://docs.sqlalchemy.org/en/rel_1_2/core/engines.html#database-urls) for more information on how to structure your URI.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/database/{pk}"
    path_params: [{name: pk, var: pk}]
    body: {content_type: "application/json", kind: json, fields: [{name: allow_csv_upload, var: allow_csv_upload}, {name: allow_ctas, var: allow_ctas}, {name: allow_cvas, var: allow_cvas}, {name: allow_dml, var: allow_dml}, {name: allow_multi_schema_metadata_fetch, var: allow_multi_schema_metadata_fetch}, {name: allow_run_async, var: allow_run_async}, {name: cache_timeout, var: cache_timeout}, {name: configuration_method, var: configuration_method}, {name: database_name, var: database_name}, {name: encrypted_extra, var: encrypted_extra}, {name: engine, var: engine}, {name: expose_in_sqllab, var: expose_in_sqllab}, {name: extra, var: extra}, {name: force_ctas_schema, var: force_ctas_schema}, {name: impersonate_user, var: impersonate_user}, {name: parameters, var: parameters}, {name: server_cert, var: server_cert}, {name: sqlalchemy_uri, var: sqlalchemy_uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, allow_csv_upload: $allow_csv_upload, allow_ctas: $allow_ctas, allow_cvas: $allow_cvas, allow_dml: $allow_dml, allow_multi_schema_metadata_fetch: $allow_multi_schema_metadata_fetch, allow_run_async: $allow_run_async, cache_timeout: $cache_timeout, configuration_method: $configuration_method, database_name: $database_name, encrypted_extra: $encrypted_extra, engine: $engine, expose_in_sqllab: $expose_in_sqllab, extra: $extra, force_ctas_schema: $force_ctas_schema, impersonate_user: $impersonate_user, parameters: $parameters, server_cert: $server_cert, sqlalchemy_uri: $sqlalchemy_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get function names supported by a database
#
# GET /database/{pk}/function_names/
# Returns: record<function_names: list<string>>
export def "get-database-pk-function-names" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/database/{pk}/function_names/"
    path_params: [{name: pk, var: pk}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get charts and dashboards count associated to a database
#
# GET /database/{pk}/related_objects/
# Returns: record<charts: record<count: int, result: list<record>>, dashboards: record<count: int, result: list<record>>>
export def "get-database-pk-related-objects" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/database/{pk}/related_objects/"
    path_params: [{name: pk, var: pk}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all schemas from a database
#
# GET /database/{pk}/schemas/
# Returns: record<result: list<string>>
export def "get-database-pk-schemas" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/database/{pk}/schemas/"
    path_params: [{name: pk, var: pk}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get database select star for table
#
# GET /database/{pk}/select_star/{table_name}/
# Returns: record<result: string>
export def "get-database-pk-select-star-table-name" [
  pk: int
  table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema-name: string # Table schema (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/database/{pk}/select_star/{table_name}/"
    path_params: [{name: pk, var: pk}, {name: table_name, var: table_name}]
    query: [{name: schema_name, var: schema_name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, table_name: $table_name, schema_name: $schema_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get database select star for table
#
# GET /database/{pk}/select_star/{table_name}/{schema_name}/
# Returns: record<result: string>
export def "get-database-pk-select-star-table-name-schema-name" [
  pk: int
  table_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/database/{pk}/select_star/{table_name}/{schema_name}/"
    path_params: [{name: pk, var: pk}, {name: table_name, var: table_name}, {name: schema_name, var: schema_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, table_name: $table_name, schema_name: $schema_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get database table metadata
#
# GET /database/{pk}/table/{table_name}/{schema_name}/
# Returns: record<columns: table<duplicates_constraint: string, keys: list, longType: string, name: string, type: string>, foreignKeys: table<column_names: list, name: string, options: record, referred_columns: list, referred_schema: string, referred_table: string, type: string>, indexes: table<column_names: list, name: string, options: record, referred_columns: list, referred_schema: string, referred_table: string, type: string>, name: string, primaryKey: record<column_names: list<string>, name: string, type: string>, selectStar: string>
export def "get-database-pk-table-table-name-schema-name" [
  pk: int
  table_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/database/{pk}/table/{table_name}/{schema_name}/"
    path_params: [{name: pk, var: pk}, {name: table_name, var: table_name}, {name: schema_name, var: schema_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, table_name: $table_name, schema_name: $schema_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes multiple Datasets in a bulk operation.
#
# DELETE /dataset/
# Returns: record<message: string>
export def "delete-dataset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/dataset/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of models
#
# GET /dataset/
# Returns: record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<changed_by: record, changed_by_name: any, changed_by_url: any, changed_on_delta_humanized: any, changed_on_utc: any, database: record, default_endpoint: string, explore_url: any, extra: string, id: int, kind: any, owners: record, schema: string, sql: string, table_name: string>>
export def "get-dataset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dataset/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Dataset
#
# POST /dataset/
# Returns: record<id: float, result: record<database: int, owners: list<int>, schema: string, table_name: string>>
export def "post-dataset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  database: int # format: int32
  --owners: list<int>
  --schema: string
  table_name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dataset/"
    body: {content_type: "application/json", kind: json, fields: [{name: database, var: database}, {name: owners, var: owners}, {name: schema, var: schema}, {name: table_name, var: table_name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    database: $database, owners: $owners, schema: $schema, table_name: $table_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata information about this API resource
#
# GET /dataset/_info
# Returns: record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>>
export def "get-dataset-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dataset/_info"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /dataset/distinct/{column_name}
#
# Returns: record<count: int, result: table<text: string>>
export def "get-dataset-distinct-column-name" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dataset/distinct/{column_name}"
    path_params: [{name: column_name, var: column_name}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    column_name: $column_name, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports multiple datasets and downloads them as YAML files
#
# GET /dataset/export/
# Returns: string
export def "get-dataset-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> any {
  http-request {
    method: get
    path: "/dataset/export/"
    query: [{name: q, var: q}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /dataset/import/
#
# Returns: record<message: string>
export def "post-dataset-import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-data: string # upload file (ZIP or YAML) (format: binary)
  --overwrite: oneof<nothing, bool> # overwrite existing datasets?
  --passwords: string # JSON map of passwords for each file
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dataset/import/"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: formData, var: form_data}, {name: overwrite, var: overwrite}, {name: passwords, var: passwords}], files: [formData]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    form_data: $form_data, overwrite: $overwrite, passwords: $passwords
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /dataset/related/{column_name}
#
# Returns: record<count: int, result: table<text: string, value: int>>
export def "get-dataset-related-column-name" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dataset/related/{column_name}"
    path_params: [{name: column_name, var: column_name}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    column_name: $column_name, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Dataset
#
# DELETE /dataset/{pk}
# Returns: record<message: string>
export def "delete-dataset-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/dataset/{pk}"
    path_params: [{name: pk, var: pk}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an item model
#
# GET /dataset/{pk}
# Returns: record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<cache_timeout: int, columns: record<changed_on: string, column_name: string, created_on: string, description: string, expression: string, filterable: bool, groupby: bool, id: int, is_active: bool, is_dttm: bool, python_date_format: string, type: string, type_generic: any, uuid: string, verbose_name: string>, database: record<database_name: string, id: int>, datasource_type: any, default_endpoint: string, description: string, extra: string, fetch_values_predicate: string, filter_select_enabled: bool, id: int, is_sqllab_view: bool, main_dttm_col: string, metrics: record<changed_on: string, created_on: string, d3format: string, description: string, expression: string, extra: string, id: int, metric_name: string, metric_type: string, uuid: string, verbose_name: string, warning_text: string>, offset: int, owners: record<first_name: string, id: int, last_name: string, username: string>, schema: string, sql: string, table_name: string, template_params: string, url: any>, show_columns: list<string>, show_title: string>
export def "get-dataset-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dataset/{pk}"
    path_params: [{name: pk, var: pk}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes a Dataset
#
# PUT /dataset/{pk}
# Returns: record<id: float, result: record<cache_timeout: int, columns: list<record>, database_id: int, default_endpoint: string, description: string, extra: string, fetch_values_predicate: string, filter_select_enabled: bool, is_sqllab_view: bool, main_dttm_col: string, metrics: list<record>, offset: int, owners: list<int>, schema: string, sql: string, table_name: string, template_params: string>>
export def "put-dataset-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --override-columns: oneof<nothing, bool>
  --cache-timeout: int # nullable, format: int32
  --columns: list # item shape: {column_name: string, description?: string, expression?: string, filterable?: bool, groupby?: bool, id?: int, is_active?: bool, is_dttm?: bool, python_date_format?: string, type?: string, uuid?: string, verbose_name?: string}
  --database-id: int # format: int32
  --default-endpoint: string # nullable
  --description: string # nullable
  --extra: string # nullable
  --fetch-values-predicate: string # nullable
  --filter-select-enabled: oneof<nothing, bool> # nullable
  --is-sqllab-view: oneof<nothing, bool> # nullable
  --main-dttm-col: string # nullable
  --metrics: list # item shape: {d3format?: string, description?: string, expression: string, id?: int, metric_name: string, metric_type?: string, warning_text?: string}
  --offset: int # nullable, format: int32
  --owners: list<int>
  --schema: string # nullable
  --sql: string # nullable
  --table-name: string # nullable
  --template-params: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/dataset/{pk}"
    path_params: [{name: pk, var: pk}]
    query: [{name: override_columns, var: override_columns}]
    body: {content_type: "application/json", kind: json, fields: [{name: cache_timeout, var: cache_timeout}, {name: columns, var: columns}, {name: database_id, var: database_id}, {name: default_endpoint, var: default_endpoint}, {name: description, var: description}, {name: extra, var: extra}, {name: fetch_values_predicate, var: fetch_values_predicate}, {name: filter_select_enabled, var: filter_select_enabled}, {name: is_sqllab_view, var: is_sqllab_view}, {name: main_dttm_col, var: main_dttm_col}, {name: metrics, var: metrics}, {name: offset, var: offset}, {name: owners, var: owners}, {name: schema, var: schema}, {name: sql, var: sql}, {name: table_name, var: table_name}, {name: template_params, var: template_params}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, override_columns: $override_columns, cache_timeout: $cache_timeout, columns: $columns, database_id: $database_id, default_endpoint: $default_endpoint, description: $description, extra: $extra, fetch_values_predicate: $fetch_values_predicate, filter_select_enabled: $filter_select_enabled, is_sqllab_view: $is_sqllab_view, main_dttm_col: $main_dttm_col, metrics: $metrics, offset: $offset, owners: $owners, schema: $schema, sql: $sql, table_name: $table_name, template_params: $template_params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Dataset column
#
# DELETE /dataset/{pk}/column/{column_id}
# Returns: record<message: string>
export def "delete-dataset-pk-column-column-id" [
  pk: int
  column_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/dataset/{pk}/column/{column_id}"
    path_params: [{name: pk, var: pk}, {name: column_id, var: column_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, column_id: $column_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Dataset metric
#
# DELETE /dataset/{pk}/metric/{metric_id}
# Returns: record<message: string>
export def "delete-dataset-pk-metric-metric-id" [
  pk: int
  metric_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/dataset/{pk}/metric/{metric_id}"
    path_params: [{name: pk, var: pk}, {name: metric_id, var: metric_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, metric_id: $metric_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refreshes and updates columns of a dataset
#
# PUT /dataset/{pk}/refresh
# Returns: record<message: string>
export def "put-dataset-pk-refresh" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/dataset/{pk}/refresh"
    path_params: [{name: pk, var: pk}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get charts and dashboards count associated to a dataset
#
# GET /dataset/{pk}/related_objects
# Returns: record<charts: record<count: int, result: list<record>>, dashboards: record<count: int, result: list<record>>>
export def "get-dataset-pk-related-objects" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dataset/{pk}/related_objects"
    path_params: [{name: pk, var: pk}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of models
#
# GET /log/
# Returns: record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<action: string, dashboard_id: int, dttm: string, duration_ms: int, json: string, referrer: string, slice_id: int, user: record, user_id: int>>
export def "get-log" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/log/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /log/
#
# Returns: record<id: string, result: record<id: int>>
export def "post-log" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/log/"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an item model
#
# GET /log/{pk}
# Returns: record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<action: string, dashboard_id: int, dttm: string, duration_ms: int, json: string, referrer: string, slice_id: int, user: record<username: string>, user_id: int>, show_columns: list<string>, show_title: string>
export def "get-log-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/log/{pk}"
    path_params: [{name: pk, var: pk}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the menu data structure. Returns a forest like structure with the menu the user has access to
#
# GET /menu/
# Returns: record<result: table<childs: list, icon: string, label: string, name: string, url: string>>
export def "get-menu" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/menu/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the OpenAPI spec for a specific API version
#
# GET /openapi/{version}/_openapi
# Returns: record
export def "get-openapi-version-openapi" [
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/openapi/{version}/_openapi"
    path_params: [{name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of queries, use Rison or JSON query parameters for filtering, sorting, pagination and for selecting specific columns and metadata.
#
# GET /query/
# Returns: record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<changed_on: string, database: record, end_time: float, executed_sql: string, id: int, rows: int, schema: string, sql: string, sql_tables: any, start_time: float, status: string, tab_name: string, tmp_table_name: string, tracking_url: string, user: record>>
export def "get-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/query/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /query/distinct/{column_name}
#
# Returns: record<count: int, result: table<text: string>>
export def "get-query-distinct-column-name" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/query/distinct/{column_name}"
    path_params: [{name: column_name, var: column_name}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    column_name: $column_name, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /query/related/{column_name}
#
# Returns: record<count: int, result: table<text: string, value: int>>
export def "get-query-related-column-name" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/query/related/{column_name}"
    path_params: [{name: column_name, var: column_name}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    column_name: $column_name, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get query detail information.
#
# GET /query/{pk}
# Returns: record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<changed_on: string, client_id: string, database: record<id: int>, end_result_backend_time: float, end_time: float, error_message: string, executed_sql: string, id: int, limit: int, progress: int, results_key: string, rows: int, schema: string, select_as_cta: bool, select_as_cta_used: bool, select_sql: string, sql: string, sql_editor_id: string, start_running_time: float, start_time: float, status: string, tab_name: string, tmp_schema_name: string, tmp_table_name: string, tracking_url: string>, show_columns: list<string>, show_title: string>
export def "get-query-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/query/{pk}"
    path_params: [{name: pk, var: pk}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes multiple report schedules in a bulk operation.
#
# DELETE /report/
# Returns: record<message: string>
export def "delete-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/report/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of report schedules, use Rison or JSON query parameters for filtering, sorting, pagination and for selecting specific columns and metadata.
#
# GET /report/
# Returns: record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<active: bool, changed_by: record, changed_on: string, changed_on_delta_humanized: any, created_by: record, created_on: string, creation_method: string, crontab: string, crontab_humanized: any, description: string, id: int, last_eval_dttm: string, last_state: string, name: string, owners: record, recipients: record, timezone: string, type: string>>
export def "get-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/report/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a report schedule
#
# POST /report/
# Returns: record<id: float, result: record<active: bool, chart: int, context_markdown: string, creation_method: any, crontab: string, dashboard: int, database: int, description: string, grace_period: int, log_retention: int, name: string, owners: list<int>, recipients: list<record>, report_format: string, sql: string, timezone: string, type: string, validator_config_json: record<op: string, threshold: int>, validator_type: string, working_timeout: int>>
export def "post-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --chart: int # nullable, format: int32
  --context-markdown: string # Markdown description (nullable)
  --creation-method: any # Creation method is used to inform the frontend whether the report/alert was created in the dashboard, chart, or alerts and reports UI.
  crontab: string # A CRON expression.[Crontab Guru](https://crontab.guru/) is a helpful resource that can help you craft a CRON expression. (e.g. */5 * * * *)
  --dashboard: int # nullable, format: int32
  --database: int # format: int32
  --description: string # Use a nice description to give context to this Alert/Report (nullable, e.g. Daily sales dashboard to marketing)
  --grace-period: int # Once an alert is triggered, how long, in seconds, before Superset nags you again. (in seconds) (format: int32, e.g. 14400)
  --log-retention: int # How long to keep the logs around for this report (in days) (format: int32, e.g. 90)
  name: string # The report schedule name. (e.g. Daily dashboard email)
  --owners: list<int>
  --recipients: list # item shape: {recipient_config_json?: record, type: "Email"|"Slack"}
  --report-format: string@report-format-completer
  --sql: string # A SQL statement that defines whether the alert should get triggered or not. The query is expected to return either NULL or a number value. (e.g. SELECT value FROM time_series_table)
  --timezone: string # A timezone string that represents the location of the timezone.
  type: string@type-completer # The report schedule type
  --validator-config-json: record # shape: {op?: "<"|"<="|">"|">="|"=="|"!=", threshold?: int}
  --validator-type: string@validator-type-completer # Determines when to trigger alert based off value from alert query. Alerts will be triggered with these validator types: - Not Null - When the return value is Not NULL, Empty, or 0 - Operator - When `sql_return_value comparison_operator threshold` is True e.g. `50 <= 75`Supports the comparison operators <, <=, >, >=, ==, and !=
  --working-timeout: int # If an alert is staled at a working state, how long until it's state is reseted to error (format: int32, e.g. 3600)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/report/"
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: chart, var: chart}, {name: context_markdown, var: context_markdown}, {name: creation_method, var: creation_method}, {name: crontab, var: crontab}, {name: dashboard, var: dashboard}, {name: database, var: database}, {name: description, var: description}, {name: grace_period, var: grace_period}, {name: log_retention, var: log_retention}, {name: name, var: name}, {name: owners, var: owners}, {name: recipients, var: recipients}, {name: report_format, var: report_format}, {name: sql, var: sql}, {name: timezone, var: timezone}, {name: type, var: type}, {name: validator_config_json, var: validator_config_json}, {name: validator_type, var: validator_type}, {name: working_timeout, var: working_timeout}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    active: $active, chart: $chart, context_markdown: $context_markdown, creation_method: $creation_method, crontab: $crontab, dashboard: $dashboard, database: $database, description: $description, grace_period: $grace_period, log_retention: $log_retention, name: $name, owners: $owners, recipients: $recipients, report_format: $report_format, sql: $sql, timezone: $timezone, type: $type, validator_config_json: $validator_config_json, validator_type: $validator_type, working_timeout: $working_timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata information about this API resource
#
# GET /report/_info
# Returns: record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>>
export def "get-report-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/report/_info"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /report/related/{column_name}
#
# Returns: record<count: int, result: table<text: string, value: int>>
export def "get-report-related-column-name" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/report/related/{column_name}"
    path_params: [{name: column_name, var: column_name}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    column_name: $column_name, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a report schedule
#
# DELETE /report/{pk}
# Returns: record<message: string>
export def "delete-report-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/report/{pk}"
    path_params: [{name: pk, var: pk}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a report schedule
#
# GET /report/{pk}
# Returns: record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<active: bool, chart: record<id: int, slice_name: string, viz_type: string>, context_markdown: string, creation_method: string, crontab: string, dashboard: record<dashboard_title: string, id: int>, database: record<database_name: string, id: int>, description: string, grace_period: int, id: int, last_eval_dttm: string, last_state: string, last_value: float, last_value_row_json: string, log_retention: int, name: string, owners: record<first_name: string, id: int, last_name: string>, recipients: record<id: int, recipient_config_json: string, type: string>, report_format: string, sql: string, timezone: string, type: string, validator_config_json: string, validator_type: string, working_timeout: int>, show_columns: list<string>, show_title: string>
export def "get-report-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/report/{pk}"
    path_params: [{name: pk, var: pk}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a report schedule
#
# PUT /report/{pk}
# Returns: record<id: float, result: record<active: bool, chart: int, context_markdown: string, creation_method: any, crontab: string, dashboard: int, database: int, description: string, grace_period: int, log_retention: int, name: string, owners: list<int>, recipients: list<record>, report_format: string, sql: string, timezone: string, type: string, validator_config_json: record<op: string, threshold: int>, validator_type: string, working_timeout: int>>
export def "put-report-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --chart: int # nullable, format: int32
  --context-markdown: string # Markdown description (nullable)
  --creation-method: any # Creation method is used to inform the frontend whether the report/alert was created in the dashboard, chart, or alerts and reports UI. (nullable)
  --crontab: string # A CRON expression.[Crontab Guru](https://crontab.guru/) is a helpful resource that can help you craft a CRON expression.
  --dashboard: int # nullable, format: int32
  --database: int # format: int32
  --description: string # Use a nice description to give context to this Alert/Report (nullable, e.g. Daily sales dashboard to marketing)
  --grace-period: int # Once an alert is triggered, how long, in seconds, before Superset nags you again. (in seconds) (format: int32, e.g. 14400)
  --log-retention: int # How long to keep the logs around for this report (in days) (format: int32, e.g. 90)
  --name: string # The report schedule name.
  --owners: list<int>
  --recipients: list # item shape: {recipient_config_json?: record, type: "Email"|"Slack"}
  --report-format: string@report-format-completer
  --sql: string # A SQL statement that defines whether the alert should get triggered or not. The query is expected to return either NULL or a number value. (nullable, e.g. SELECT value FROM time_series_table)
  --timezone: string # A timezone string that represents the location of the timezone.
  --type: string@type-completer # The report schedule type
  --validator-config-json: record # shape: {op?: "<"|"<="|">"|">="|"=="|"!=", threshold?: int}
  --validator-type: string@validator-type-completer # Determines when to trigger alert based off value from alert query. Alerts will be triggered with these validator types: - Not Null - When the return value is Not NULL, Empty, or 0 - Operator - When `sql_return_value comparison_operator threshold` is True e.g. `50 <= 75`Supports the comparison operators <, <=, >, >=, ==, and != (nullable)
  --working-timeout: int # If an alert is staled at a working state, how long until it's state is reseted to error (nullable, format: int32, e.g. 3600)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/report/{pk}"
    path_params: [{name: pk, var: pk}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: chart, var: chart}, {name: context_markdown, var: context_markdown}, {name: creation_method, var: creation_method}, {name: crontab, var: crontab}, {name: dashboard, var: dashboard}, {name: database, var: database}, {name: description, var: description}, {name: grace_period, var: grace_period}, {name: log_retention, var: log_retention}, {name: name, var: name}, {name: owners, var: owners}, {name: recipients, var: recipients}, {name: report_format, var: report_format}, {name: sql, var: sql}, {name: timezone, var: timezone}, {name: type, var: type}, {name: validator_config_json, var: validator_config_json}, {name: validator_type, var: validator_type}, {name: working_timeout, var: working_timeout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, active: $active, chart: $chart, context_markdown: $context_markdown, creation_method: $creation_method, crontab: $crontab, dashboard: $dashboard, database: $database, description: $description, grace_period: $grace_period, log_retention: $log_retention, name: $name, owners: $owners, recipients: $recipients, report_format: $report_format, sql: $sql, timezone: $timezone, type: $type, validator_config_json: $validator_config_json, validator_type: $validator_type, working_timeout: $working_timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of report schedule logs, use Rison or JSON query parameters for filtering, sorting, pagination and for selecting specific columns and metadata.
#
# GET /report/{pk}/log/
# Returns: record<count: float, ids: list<string>, result: table<end_dttm: string, error_message: string, id: int, scheduled_dttm: string, start_dttm: string, state: string, uuid: string, value: float, value_row_json: string>>
export def "get-report-pk-log" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/report/{pk}/log/"
    path_params: [{name: pk, var: pk}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a report schedule log
#
# GET /report/{pk}/log/{log_id}
# Returns: record<id: string, result: record<end_dttm: string, error_message: string, id: int, scheduled_dttm: string, start_dttm: string, state: string, uuid: string, value: float, value_row_json: string>>
export def "get-report-pk-log-log-id" [
  pk: int
  log_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/report/{pk}/log/{log_id}"
    path_params: [{name: pk, var: pk}, {name: log_id, var: log_id}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, log_id: $log_id, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes multiple saved queries in a bulk operation.
#
# DELETE /saved_query/
# Returns: record<message: string>
export def "delete-saved-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/saved_query/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of saved queries, use Rison or JSON query parameters for filtering, sorting, pagination and for selecting specific columns and metadata.
#
# GET /saved_query/
# Returns: record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<changed_on_delta_humanized: any, created_by: record, created_on: string, database: record, db_id: int, description: string, extra: any, id: int, label: string, last_run_delta_humanized: any, rows: int, schema: string, sql: string, sql_tables: any>>
export def "get-saved-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/saved_query/"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a saved query
#
# POST /saved_query/
# Returns: record<id: string, result: record<db_id: int, description: string, label: string, schema: string, sql: string>>
export def "post-saved-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-id: int # nullable, format: int32
  --description: string # nullable
  --label: string # nullable
  --schema: string # nullable
  --sql: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/saved_query/"
    body: {content_type: "application/json", kind: json, fields: [{name: db_id, var: db_id}, {name: description, var: description}, {name: label, var: label}, {name: schema, var: schema}, {name: sql, var: sql}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    db_id: $db_id, description: $description, label: $label, schema: $schema, sql: $sql
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata information about this API resource
#
# GET /saved_query/_info
# Returns: record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>>
export def "get-saved-query-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/saved_query/_info"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /saved_query/distinct/{column_name}
#
# Returns: record<count: int, result: table<text: string>>
export def "get-saved-query-distinct-column-name" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/saved_query/distinct/{column_name}"
    path_params: [{name: column_name, var: column_name}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    column_name: $column_name, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports multiple saved queries and downloads them as YAML files
#
# GET /saved_query/export/
# Returns: binary
export def "get-saved-query-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> any {
  http-request {
    method: get
    path: "/saved_query/export/"
    query: [{name: q, var: q}]
    accept: ["application/zip"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /saved_query/import/
#
# Returns: record<message: string>
export def "post-saved-query-import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-data: string # upload file (ZIP) (format: binary)
  --overwrite: oneof<nothing, bool> # overwrite existing saved queries?
  --passwords: string # JSON map of passwords for each file
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/saved_query/import/"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: formData, var: form_data}, {name: overwrite, var: overwrite}, {name: passwords, var: passwords}], files: [formData]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    form_data: $form_data, overwrite: $overwrite, passwords: $passwords
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /saved_query/related/{column_name}
#
# Returns: record<count: int, result: table<text: string, value: int>>
export def "get-saved-query-related-column-name" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/saved_query/related/{column_name}"
    path_params: [{name: column_name, var: column_name}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    column_name: $column_name, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete saved query
#
# DELETE /saved_query/{pk}
# Returns: record<message: string>
export def "delete-saved-query-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/saved_query/{pk}"
    path_params: [{name: pk, var: pk}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a saved query
#
# GET /saved_query/{pk}
# Returns: record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<created_by: record<first_name: string, id: int, last_name: string>, database: record<database_name: string, id: int>, description: string, id: int, label: string, schema: string, sql: string, sql_tables: any>, show_columns: list<string>, show_title: string>
export def "get-saved-query-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/saved_query/{pk}"
    path_params: [{name: pk, var: pk}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a saved query
#
# PUT /saved_query/{pk}
# Returns: record<result: record<db_id: int, description: string, label: string, schema: string, sql: string>>
export def "put-saved-query-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-id: int # nullable, format: int32
  --description: string # nullable
  --label: string # nullable
  --schema: string # nullable
  --sql: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/saved_query/{pk}"
    path_params: [{name: pk, var: pk}]
    body: {content_type: "application/json", kind: json, fields: [{name: db_id, var: db_id}, {name: description, var: description}, {name: label, var: label}, {name: schema, var: schema}, {name: sql, var: sql}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pk: $pk, db_id: $db_id, description: $description, label: $label, schema: $schema, sql: $sql
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the CSRF token
#
# GET /security/csrf_token/
# Returns: record<result: string>
export def "get-security-csrf-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/security/csrf_token/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authenticate and get a JWT access and refresh token
#
# POST /security/login
# Returns: record<access_token: string, refresh_token: string>
export def "post-security-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # The password for authentication (e.g. complex-password)
  --provider: string@provider-completer # Choose an authentication provider (e.g. db)
  --refresh: oneof<nothing, bool> # If true a refresh token is provided also (e.g. true)
  --username: string # The username for authentication (e.g. admin)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/security/login"
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: provider, var: provider}, {name: refresh, var: refresh}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    password: $password, provider: $provider, refresh: $refresh, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use the refresh token to get a new JWT access token
#
# POST /security/refresh
# Returns: record<access_token: string>
export def "post-security-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/security/refresh"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
