# Auto-generated client for DaniWeb Connect API v4
# Source: https://api.apis.guru/v2/specs/daniweb.com/4/openapi.json
# Auth: --token flag or $env.DANIWEB_CONNECT_API_TOKEN

const CLIENT = {
  base_url: "https://www.daniweb.com/connect/api/v4"
  token_env_var: "DANIWEB_CONNECT_API_TOKEN"
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

def base-url-completer [] { ["https://www.daniweb.com/connect/api/v4"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["asc" "desc"] }
def filter-completer [] { ["introductions" "new" "notifications" "unreplied"] }
def metadata-0-privacy-completer [] { ["Bubbled" "Private" "Public" "User"] }
def metadata-1-privacy-completer [] { ["Bubbled" "Private" "Public" "User"] }
def metadata-2-privacy-completer [] { ["Bubbled" "Private" "Public" "User"] }
def privacy-completer [] { ["Private" "Public" "Unlisted"] }
def category-completer [] { ["Affiliations" "Awards" "Education" "Experience" "Portfolio"] }
def organization-size-completer [] { ["10 - 49 Employees" "100 - 499 Employees" "1000 - 4999 Employees" "2 - 9 Employees" "50 - 99 Employees" "500 - 999 Employees" "5000+ Employees" "Don't Know" "Self-employed"] }
def position-completer [] { ["Executive Management (C-level)" "IT Consultant" "Manager / Director / Supervisor" "Other non-technology related" "Other technology related" "Retired" "Sales" "Software Development" "Student" "Systems Development" "Technical Support" "VP-level Executive" "Web Developer"] }
def filter-completer-1 [] { ["connections" "matches" "muted" "skipped"] }
def order-by-completer [] { ["first_name" "id" "industry" "last_activity" "last_name"] }
def company-size-completer [] { ["10 - 49 Employees" "100 - 499 Employees" "1000 - 4999 Employees" "2 - 9 Employees" "50 - 99 Employees" "500 - 999 Employees" "5000+ Employees" "Don't Know" "Self-employed"] }
def goals-completer [] { ["Find a co-founder" "Find a job" "Find business partnerships" "Find prospective clients" "Hire employees" "Mentor others" "Receive mentorship from others"] }
def industry-completer [] { ["Accounting" "Airlines/Aviation" "Alternative Dispute Resolution" "Alternative Medicine" "Animation" "Apparel & Fashion" "Architecture & Planning" "Arts and Crafts" "Automotive" "Aviation & Aerospace" "Banking" "Biotechnology" "Broadcast Media" "Building Materials" "Business Supplies and Equipment" "Capital Markets" "Chemicals" "Civic & Social Organization" "Civil Engineering" "Commercial Real Estate" "Computer & Network Security" "Computer Games" "Computer Hardware" "Computer Networking" "Computer Software" "Construction" "Consumer Electronics" "Consumer Goods" "Consumer Services" "Cosmetics" "Dairy" "Defense & Space" "Design" "E-Learning" "Education Management" "Electrical/Electronic Manufacturing" "Entertainment" "Environmental Services" "Events Services" "Executive Office" "Facilities Services" "Farming" "Financial Services" "Fine Art" "Fishery" "Food & Beverages" "Food Production" "Fund-Raising" "Furniture" "Gambling & Casinos" "Glass, Ceramics & Concrete" "Government Administration" "Government Relations" "Graphic Design" "Health, Wellness and Fitness" "Higher Education" "Hospital & Health Care" "Hospitality" "Human Resources" "Import and Export" "Individual & Family Services" "Industrial Automation" "Information Services" "Information Technology and Services" "Insurance" "International Affairs" "International Trade and Development" "Internet" "Investment Banking" "Investment Management" "Judiciary" "Law Enforcement" "Law Practice" "Legal Services" "Legislative Office" "Leisure, Travel & Tourism" "Libraries" "Logistics and Supply Chain" "Luxury Goods & Jewelry" "Machinery" "Management Consulting" "Maritime" "Market Research" "Marketing and Advertising" "Mechanical or Industrial Engineering" "Media Production" "Medical Devices" "Medical Practice" "Mental Health Care" "Military" "Mining & Metals" "Motion Pictures and Film" "Museums and Institutions" "Music" "Nanotechnology" "Newspapers" "Non-Profit Organization Management" "Oil & Energy" "Online Media" "Outsourcing/Offshoring" "Package/Freight Delivery" "Packaging and Containers" "Paper & Forest Products" "Performing Arts" "Pharmaceuticals" "Philanthropy" "Photography" "Plastics" "Political Organization" "Primary/Secondary Education" "Printing" "Professional Training & Coaching" "Program Development" "Public Policy" "Public Relations and Communications" "Public Safety" "Publishing" "Railroad Manufacture" "Ranching" "Real Estate" "Recreational Facilities and Services" "Religious Institutions" "Renewables & Environment" "Research" "Restaurants" "Retail" "Security and Investigations" "Semiconductors" "Shipbuilding" "Sporting Goods" "Sports" "Staffing and Recruiting" "Supermarkets" "Telecommunications" "Textiles" "Think Tanks" "Tobacco" "Translation and Localization" "Transportation/Trucking/Railroad" "Utilities" "Venture Capital & Private Equity" "Veterinary" "Warehousing" "Wholesale" "Wine and Spirits" "Wireless" "Writing and Editing"] }
def job-position-completer [] { ["Executive Management (C-level)" "IT Consultant" "Manager / Director / Supervisor" "Other non-technology related" "Other technology related" "Retired" "Sales" "Software Development" "Student" "Systems Development" "Technical Support" "VP-level Executive" "Web Developer"] }
def location-importance-completer [] { ["No" "Somewhat" "Yes"] }
def targeted-industry-completer [] { ["Accounting" "Airlines/Aviation" "Alternative Dispute Resolution" "Alternative Medicine" "Animation" "Apparel & Fashion" "Architecture & Planning" "Arts and Crafts" "Automotive" "Aviation & Aerospace" "Banking" "Biotechnology" "Broadcast Media" "Building Materials" "Business Supplies and Equipment" "Capital Markets" "Chemicals" "Civic & Social Organization" "Civil Engineering" "Commercial Real Estate" "Computer & Network Security" "Computer Games" "Computer Hardware" "Computer Networking" "Computer Software" "Construction" "Consumer Electronics" "Consumer Goods" "Consumer Services" "Cosmetics" "Dairy" "Defense & Space" "Design" "E-Learning" "Education Management" "Electrical/Electronic Manufacturing" "Entertainment" "Environmental Services" "Events Services" "Executive Office" "Facilities Services" "Farming" "Financial Services" "Fine Art" "Fishery" "Food & Beverages" "Food Production" "Fund-Raising" "Furniture" "Gambling & Casinos" "Glass, Ceramics & Concrete" "Government Administration" "Government Relations" "Graphic Design" "Health, Wellness and Fitness" "Higher Education" "Hospital & Health Care" "Hospitality" "Human Resources" "Import and Export" "Individual & Family Services" "Industrial Automation" "Information Services" "Information Technology and Services" "Insurance" "International Affairs" "International Trade and Development" "Internet" "Investment Banking" "Investment Management" "Judiciary" "Law Enforcement" "Law Practice" "Legal Services" "Legislative Office" "Leisure, Travel & Tourism" "Libraries" "Logistics and Supply Chain" "Luxury Goods & Jewelry" "Machinery" "Management Consulting" "Maritime" "Market Research" "Marketing and Advertising" "Mechanical or Industrial Engineering" "Media Production" "Medical Devices" "Medical Practice" "Mental Health Care" "Military" "Mining & Metals" "Motion Pictures and Film" "Museums and Institutions" "Music" "Nanotechnology" "Newspapers" "Non-Profit Organization Management" "Oil & Energy" "Online Media" "Outsourcing/Offshoring" "Package/Freight Delivery" "Packaging and Containers" "Paper & Forest Products" "Performing Arts" "Pharmaceuticals" "Philanthropy" "Photography" "Plastics" "Political Organization" "Primary/Secondary Education" "Printing" "Professional Training & Coaching" "Program Development" "Public Policy" "Public Relations and Communications" "Public Safety" "Publishing" "Railroad Manufacture" "Ranching" "Real Estate" "Recreational Facilities and Services" "Religious Institutions" "Renewables & Environment" "Research" "Restaurants" "Retail" "Security and Investigations" "Semiconductors" "Shipbuilding" "Sporting Goods" "Sports" "Staffing and Recruiting" "Supermarkets" "Telecommunications" "Textiles" "Think Tanks" "Tobacco" "Translation and Localization" "Transportation/Trucking/Railroad" "Utilities" "Venture Capital & Private Equity" "Veterinary" "Warehousing" "Wholesale" "Wine and Spirits" "Wireless" "Writing and Editing"] }
def event-completer [] { ["conversation_message" "conversation_seen" "group_message" "group_seen" "group_update" "user_online" "user_update"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-apps: "record<data: table<about: record, id: float, legal: record>, pagination: record<limit: float, offset: float, total_records: float>>"
    get-apps-id: "record<data: table<about: record, id: float, legal: record>>"
    get-audiences: "record<data: table<about: record, id: float>, pagination: record<limit: float, offset: float, total_records: float>>"
    get-audiences-id: "record<data: table<about: record, id: float>>"
    post-audiences-id-memberships: "record<data: record<audience: record<id: float>, member: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>>, success: bool>"
    get-autocompletes: "record<data: record<conversations: list<string>, locations: list<string>, matches: list<string>, people: list<string>>>"
    post-conversations-schedules: "record<data: table<author_count: float, conversation_count: float, conversation_id: float, date: string, first_message: record, last_message: record, message_count: float, my_message_count: float, navigation: record>, pagination: record<limit: float, offset: float, total_records: float>>"
    post-conversations-searches: "record<data: table<message: record, relevance: record>, pagination: record<limit: float, offset: float, total_records: float>>"
    get-conversations-statuses: "record<data: table<archived_status: bool, bubbled: record, conversation: record, earliest_unseen_message: record, new_message_count: float>, pagination: record<limit: float, offset: float, total_records: float>>"
    get-conversations-id: "record<data: table<first_message: record, id: float, latest_message: record, user_a: record, user_b: record>>"
    get-conversations-id-messages: "record<data: table<author: record, conversation: record, id: float, last_seen: record, text: record, timestamp: string>, pagination: record<limit: float, offset: float, total_records: float>>"
    post-conversations-id-messages: "record<data: record<author: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>, conversation: record<first_message: record, id: float, latest_message: any, user_a: record, user_b: record>, id: float, last_seen: record<timestamp: string, user: record>, text: record<parsed: string>, timestamp: string>, success: bool>"
    post-conversations-id-schedules: "record<data: table<author_count: float, conversation_count: float, conversation_id: float, date: string, first_message: record, last_message: record, message_count: float, my_message_count: float, navigation: record>, pagination: record<limit: float, offset: float, total_records: float>>"
    post-conversations-id-searches: "record<data: table<message: record, relevance: record>, pagination: record<limit: float, offset: float, total_records: float>>"
    get-conversations-id-statuses: "record<data: table<archived_status: bool, bubbled: record, conversation: record, earliest_unseen_message: record, new_message_count: float>>"
    patch-conversations-id-statuses: "record<data: record<archived_status: bool, conversation: record<first_message: record, id: float, latest_message: record, user_a: record, user_b: record>>, success: bool>"
    get-groups: "record<data: table<first_message: record, id: float, latest_message: record, member_count: float, owner: record, properties: record>, pagination: record<limit: float, offset: float, total_records: float>>"
    post-groups: "record<data: record<first_message: record<timestamp: string>, id: float, latest_message: record<author: record, group: any, id: float, last_seen: record, moderated: record, text: record, timestamp: string>, member_count: float, owner: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>, properties: record<description: string, name: string, privacy: string, slug: string>>, success: bool>"
    post-groups-messages-metadata-filters: "record<data: table<matched_metadata: record, message: record>, pagination: record<limit: float, offset: float, total_records: float>>"
    delete-groups-messages-id: "record<data: table<author: record, group: record, id: float, last_seen: record, moderated: record, text: record, timestamp: string>, status: bool>"
    get-groups-messages-id: "record<data: table<author: record, group: record, id: float, last_seen: record, moderated: record, text: record, timestamp: string>>"
    get-groups-messages-id-metadata: "record<data: table<app: record, content: record, id: float, message: record, owner: record, settings: record, status: record>, pagination: record<limit: float, offset: float, total_records: float>>"
    post-groups-messages-id-metadata: "record<data: record, success: bool>"
    get-groups-messages-id-metadata-collections: "record<data: record>"
    post-groups-schedules: "record<data: table<author_count: float, date: string, first_message: record, group_count: float, group_id: float, last_message: record, message_count: float, my_message_count: float, navigation: record>, pagination: record<limit: float, offset: float, total_records: float>>"
    get-groups-statuses: "record<data: table<earliest_unseen_message: record, group: record, new_message_count: float>, pagination: record<limit: float, offset: float, total_records: float>>"
    get-groups-id: "record<data: table<first_message: record, id: float, latest_message: record, member_count: float, owner: record, properties: record>>"
    patch-groups-id: "record<data: record<first_message: record<timestamp: string>, id: float, latest_message: record<author: record, group: any, id: float, last_seen: record, moderated: record, text: record, timestamp: string>, member_count: float, owner: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>, properties: record<description: string, name: string, privacy: string, slug: string>>, success: bool>"
    delete-groups-id-memberships: "record<success: bool>"
    get-groups-id-memberships: "record<data: table<group: record, member: record, privileges: record>, pagination: record<limit: float, offset: float, total_records: float>>"
    patch-groups-id-memberships: "record<data: table<group: record, member: record, privileges: record>, pagination: record<limit: float, offset: float, total_records: float>, success: bool>"
    post-groups-id-memberships: "record<data: record<group: record<first_message: record, id: float, latest_message: record, member_count: float, owner: record, properties: record>, member: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>>, success: bool>"
    get-groups-id-messages: "record<data: table<author: record, group: record, id: float, last_seen: record, moderated: record, text: record, timestamp: string>, pagination: record<limit: float, offset: float, total_records: float>>"
    post-groups-id-messages: "record<data: table<author: record, group: record, id: float, last_seen: record, moderated: record, text: record, timestamp: string>, success: bool>"
    post-groups-id-schedules: "record<data: table<author_count: float, date: string, first_message: record, group_count: float, group_id: float, last_message: record, message_count: float, my_message_count: float, navigation: record>, pagination: record<limit: float, offset: float, total_records: float>>"
    get-groups-id-statuses: "record<data: table<earliest_unseen_message: record, group: record, membership_status: bool, new_message_count: float>>"
    get-industries: "record<data: list<string>>"
    post-markdown: "record<data: record<parsed: string, raw: string>>"
    get-markdown-emoticons: "record<data: table<alt: string, emoticon: string, image: string>>"
    post-messages-metadata-filters: "record<data: table<matched_metadata: record, message: record>, pagination: record<limit: float, offset: float, total_records: float>>"
    get-messages-id: "record<data: table<author: record, conversation: record, id: float, last_seen: record, text: record, timestamp: string>>"
    get-messages-id-metadata: "record<data: table<app: record, content: record, id: float, message: record, owner: record, settings: record, status: record>, pagination: record<limit: float, offset: float, total_records: float>>"
    post-messages-id-metadata: "record<data: record, success: bool>"
    get-messages-id-metadata-collections: "record<data: record>"
    post-positions: "record<data: record<app: record<about: record, id: float, legal: record>, category: string, id: float, organization: record<industry: string, name: string, size: string, ticker: string, type: string, url: string>, role: record<end_date: string, start_date: string, summary: string, title: string>, user: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>>, success: bool>"
    delete-positions-id: "record<success: bool>"
    patch-positions-id: "record<data: record<app: record<about: record, id: float, legal: record>, category: string, id: float, organization: record<industry: string, name: string, size: string, ticker: string, type: string, url: string>, role: record<end_date: string, start_date: string, summary: string, title: string>, user: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>>, success: bool>"
    get-users: "record<data: table<business_card: record, community_persona: record, id: float, profile: record, usage: record>, pagination: record<limit: float, offset: float, total_records: float>>"
    post-users-invites: "record<data: record<discovered: record<users: list>, emailed: record<emails: list>, existing: record<conversations: list>, invalid: record<emails: list>>, success: bool>"
    post-users-metadata-filters: "record<data: table<matched_metadata: record, user: record>, pagination: record<limit: float, offset: float, total_records: float>>"
    get-users-nearby: "record<data: table<distance_away: record, user: record>, pagination: record<limit: float, offset: float, total_records: float>>"
    post-users-searches: "record<data: table<relevance: record, user: record>, pagination: record<limit: float, offset: float, total_records: float>>"
    get-users-id: "record<data: table<business_card: record, community_persona: record, id: float, profile: record, usage: record>>"
    get-users-id-groups: "record<data: table<first_message: record, id: float, latest_message: record, member_count: float, owner: record, properties: record>>"
    get-users-id-groups-messages: "record<data: table<author: record, group: record, id: float, last_seen: record, moderated: record, text: record, timestamp: string>, pagination: record<limit: float, offset: float, total_records: float>>"
    post-users-id-messages: "record<data: record<author: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>, conversation: record<first_message: record, id: float, latest_message: any, user_a: record, user_b: record>, id: float, last_seen: record<timestamp: string, user: record>, text: record<parsed: string>, timestamp: string>, success: bool>"
    get-users-id-metadata: "record<data: table<app: record, content: record, id: float, owner: record, settings: record, status: record, user: record>, pagination: record<limit: float, offset: float, total_records: float>>"
    post-users-id-metadata: "record<data: record, success: bool>"
    get-users-id-metadata-collections: "record<data: record>"
    get-users-id-positions: "record<data: table<app: record, category: string, id: float, organization: record, role: record, user: record>>"
    get-users-id-synergies: "record<data: table<additional: record, conversation: record, match: record, meet: record, relationship: record>>"
    patch-users-id-synergies: "record<data: record<relationship: record<muted: bool, skipped: bool>>, success: bool>"
    get-users-1: "record<data: record<business_card: record<company_name: string, company_size: string, headline: string, industry: string, interest_tags: list, job_position: string, summary: string, website: record>, community_persona: record<id: float, identity: record, location: record, personal: record, signature: record, stats: record>, id: float, location: record<city: string, country: float, ip_address: string, latitude: string, longitude: string, region: string>, matching: record<goals: list, interest_tags: list, location_importance: string, targeted_industry: string>, profile: record<first_name: string, introduction: string, last_name: string>, settings: record<email: string, email_verified: bool, notifications: string, timezone: float>, usage: record<available_status: bool, joined_timestamp: string, last_activity_timestamp: string, online_status: bool>>>"
    patch-users: "record<data: record<business_card: record<company_name: string, company_size: string, headline: string, industry: string, interest_tags: list, job_position: string, summary: string, website: record>, community_persona: record<id: float, identity: record, location: record, personal: record, signature: record, stats: record>, id: float, location: record<city: string, country: float, ip_address: string, latitude: string, longitude: string, region: string>, matching: record<goals: list, interest_tags: list, location_importance: string, targeted_industry: string>, profile: record<first_name: string, introduction: string, last_name: string>, settings: record<email: string, email_verified: bool, notifications: string, timezone: float>, usage: record<available_status: bool, joined_timestamp: string, last_activity_timestamp: string, online_status: bool>>, success: bool>"
    get-webhooks: "record<data: table<app: record, event: record, id: float, name: string, object: record, uri: string, user: record>>"
    post-webhooks: "record<data: record<app: record<about: record, id: float, legal: record>, event: record<action: string>, id: float, name: string, object: record<id: float, type: string>, uri: string, user: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>>, success: bool>"
    delete-webhooks-id: "record<success: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-apps" "get-apps-id" "get-audiences" "get-audiences-id" "post-audiences-id-memberships" "get-autocompletes" "post-conversations-schedules" "post-conversations-searches" "get-conversations-statuses" "get-conversations-id" "get-conversations-id-messages" "post-conversations-id-messages" "post-conversations-id-schedules" "post-conversations-id-searches" "get-conversations-id-statuses" "patch-conversations-id-statuses" "get-groups" "post-groups" "post-groups-messages-metadata-filters" "delete-groups-messages-id" "get-groups-messages-id" "get-groups-messages-id-metadata" "post-groups-messages-id-metadata" "get-groups-messages-id-metadata-collections" "post-groups-schedules" "get-groups-statuses" "get-groups-id" "patch-groups-id" "delete-groups-id-memberships" "get-groups-id-memberships" "patch-groups-id-memberships" "post-groups-id-memberships" "get-groups-id-messages" "post-groups-id-messages" "post-groups-id-schedules" "get-groups-id-statuses" "get-industries" "post-markdown" "get-markdown-emoticons" "post-messages-metadata-filters" "get-messages-id" "get-messages-id-metadata" "post-messages-id-metadata" "get-messages-id-metadata-collections" "post-positions" "delete-positions-id" "patch-positions-id" "get-users" "post-users-invites" "post-users-metadata-filters" "get-users-nearby" "post-users-searches" "get-users-id" "get-users-id-groups" "get-users-id-groups-messages" "post-users-id-messages" "get-users-id-metadata" "post-users-id-metadata" "get-users-id-metadata-collections" "get-users-id-positions" "get-users-id-synergies" "patch-users-id-synergies" "get-users-1" "patch-users" "get-webhooks" "post-webhooks" "delete-webhooks-id" "commands"] | sort) } | get name | first)
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

# Fetch all Daniapps that are currently in production mode.
#
# GET /apps
# Returns: record<data: table<about: record, id: float, legal: record>, pagination: record<limit: float, offset: float, total_records: float>>
export def "get-apps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an array of Daniapps that are currently in production mode.
#
# GET /apps/{ID}
# Returns: record<data: table<about: record, id: float, legal: record>>
export def "get-apps-id" [
  id: list<int>
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
    path: "/apps/{ID}"
    path_params: [{name: ID, var: id, encode: array}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all Daniapp audience segments that comprise the current access token's bubble.
#
# GET /audiences
# Returns: record<data: table<about: record, id: float>, pagination: record<limit: float, offset: float, total_records: float>>
export def "get-audiences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/audiences"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an array of Daniapp audience segments that comprise the current access token's bubble.
#
# GET /audiences/{ID}
# Returns: record<data: table<about: record, id: float>>
export def "get-audiences-id" [
  id: list<int>
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
    path: "/audiences/{ID}"
    path_params: [{name: ID, var: id, encode: array}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a membership record for the OAuth'ed end-user based on the current audience segment/bubble combination.
#
# POST /audiences/{ID}/memberships
# Returns: record<data: record<audience: record<id: float>, member: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>>, success: bool>
export def "post-audiences-id-memberships" [
  id: int
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
    path: "/audiences/{ID}/memberships"
    path_params: [{name: ID, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an array of names and locations, filtered by category, that begin with the query string passed in. Ideally used for search autocomplete dropdowns, as the search functionality filters against name and location. The four potential categories are: `conversations` for names of users you are in existing conversations with; `matches` for names of users you have previously skipped over; `people` for names of all other users; `locations` for locations of users. Only users and their locations who exist with the current access token's bubble are considered.
#
# GET /autocompletes
# Returns: record<data: record<conversations: list<string>, locations: list<string>, matches: list<string>, people: list<string>>>
export def "get-autocompletes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # allows empty value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/autocompletes"
    query: [{name: query, var: query}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Paginated report of information about messages contributed by conversation and date. Only conversations that exist within the current access token's bubble are considered in the calculations. Optionally roll up all conversations to retrieve one record per date. Optionally specify a date formatted as YYYY-MM-DD to retrieve information just from the single date, along with additional navigational information, which is useful when generating a transcript for a single day and wanting to reference the previous and next days there were messages.
#
# POST /conversations/schedules
# Returns: record<data: table<author_count: float, conversation_count: float, conversation_id: float, date: string, first_message: record, last_message: record, message_count: float, my_message_count: float, navigation: record>, pagination: record<limit: float, offset: float, total_records: float>>
export def "post-conversations-schedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --roll-up: oneof<nothing, bool> # default: false
  --sort: string@sort-completer # default: desc
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations/schedules"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: date, var: date}, {name: limit, var: limit}, {name: offset, var: offset}, {name: roll_up, var: roll_up}, {name: sort, var: sort}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date: $date, limit: $limit, offset: $offset, roll_up: $roll_up, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch messages authored from within the current bubble that match a query string passed in as a search parameter along with their relevancy score.
#
# POST /conversations/searches
# Returns: record<data: table<message: record, relevance: record>, pagination: record<limit: float, offset: float, total_records: float>>
export def "post-conversations-searches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string
  --gt-message-id: int # format: int32
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  query: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations/searches"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: date, var: date}, {name: gt_message_id, var: gt_message_id}, {name: limit, var: limit}, {name: offset, var: offset}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date: $date, gt_message_id: $gt_message_id, limit: $limit, offset: $offset, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve conversations that you are participating in with users who exists within the same bubble, along with your current relationship with the conversations. The user_a / user_b properties of the conversation are populated with as much data as is available if the user is not you. If the user is you, only the id field is populated. There is a separate status endpoint to retrieve relationship information for individual conversations. Optionally filter: 'new' to only show conversations with messages you haven't yet seen; 'introductions' to only show conversations where users have introduced themselves to you but nothing more; 'unreplied' to only show conversations where you have introduced yourself to other users but nothing more; 'notifications' to show all conversations where the other user was the last person to message. Optionally only show conversations engaging within the existing access token's bubble. This report is limited to your ~500-1000 most recently active conversations you've engaged in within current the access token's bubble.
#
# GET /conversations/statuses
# Returns: record<data: table<archived_status: bool, bubbled: record, conversation: record, earliest_unseen_message: record, new_message_count: float>, pagination: record<limit: float, offset: float, total_records: float>>
export def "get-conversations-statuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer # allows empty value
  --include-archived: oneof<nothing, bool> # default: false, allows empty value
  --bubbled: oneof<nothing, bool> # default: false, allows empty value
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversations/statuses"
    query: [{name: filter, var: filter}, {name: include_archived, var: include_archived}, {name: bubbled, var: bubbled}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, include_archived: $include_archived, bubbled: $bubbled, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an array of conversations. You can only retrieve conversations with users who exist within the current access token's bubble.
#
# GET /conversations/{ID}
# Returns: record<data: table<first_message: record, id: float, latest_message: record, user_a: record, user_b: record>>
export def "get-conversations-id" [
  id: list<int>
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
    path: "/conversations/{ID}"
    path_params: [{name: ID, var: id, encode: array}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the last {limit} messages in the conversation, provided the conversations exist within the current access token's bubble. If a timeout is 0 or greater, the batch is sorted oldest first. Otherwise, if timeout is a negative number, the transcript is paginated and sorted newest first. Specify a timeout for long polling (which delays the server sending back results for up to n seconds or until results are available, whichever comes first), or default to 0 for immediate results. Optionally record your status as online along with sharing the latest message you've seen with the other conversation participant. Optionally specify a gt_message_id to retrieve only messages with an ID greater than that specified (such as greater than the latest message ID received in the last poll). Optionally only poll for messages authored by the other person in the conversation, and echo messages authored by you when sending, for a perceived increase in performance. Optionally only retrieve messages that were posted from within the current access token's bubble. Optionally specify a date formatted as YYYY-MM-DD to retrieve a transcript of messages from a single day. When record_seen is set to true, the new message count for the conversation is reset to zero.
#
# GET /conversations/{ID}/messages
# Returns: record<data: table<author: record, conversation: record, id: float, last_seen: record, text: record, timestamp: string>, pagination: record<limit: float, offset: float, total_records: float>>
export def "get-conversations-id-messages" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --gt-message-id: int # format: int32, allows empty value
  --exclude-self: oneof<nothing, bool> # default: false, allows empty value
  --date: string # allows empty value
  --bubbled: oneof<nothing, bool> # default: false, allows empty value
  --record-seen: oneof<nothing, bool> # default: false, allows empty value
  --timeout: int # format: int32, default: 0, allows empty value
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversations/{ID}/messages"
    path_params: [{name: ID, var: id}]
    query: [{name: gt_message_id, var: gt_message_id}, {name: exclude_self, var: exclude_self}, {name: date, var: date}, {name: bubbled, var: bubbled}, {name: record_seen, var: record_seen}, {name: timeout, var: timeout}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, gt_message_id: $gt_message_id, exclude_self: $exclude_self, date: $date, bubbled: $bubbled, record_seen: $record_seen, timeout: $timeout, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Post a message to a conversation that is with a user who exists within the current access token's bubble. Optionally specify whether emoticons should be parsed into smiley images. Optionally specify whether the message should be bubbled within the app. Additionally, optionally attach a single metadata key/value pair to the message upon submission.
#
# POST /conversations/{ID}/messages
# Returns: record<data: record<author: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>, conversation: record<first_message: record, id: float, latest_message: any, user_a: record, user_b: record>, id: float, last_seen: record<timestamp: string, user: record>, text: record<parsed: string>, timestamp: string>, success: bool>
export def "post-conversations-id-messages" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bubbled: oneof<nothing, bool> # default: false
  --metadata-0-key: string
  --metadata-0-privacy: string@metadata-0-privacy-completer
  --metadata-0-values: list<string>
  --metadata-1-key: string
  --metadata-1-privacy: string@metadata-1-privacy-completer
  --metadata-1-values: list<string>
  --metadata-2-key: string
  --metadata-2-privacy: string@metadata-2-privacy-completer
  --metadata-2-values: list<string>
  --text-emoticons: oneof<nothing, bool> # default: false
  text_raw: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations/{ID}/messages"
    path_params: [{name: ID, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: bubbled, var: bubbled}, {name: metadata_0_key, var: metadata_0_key}, {name: metadata_0_privacy, var: metadata_0_privacy}, {name: "metadata_0_values[]", var: metadata_0_values}, {name: metadata_1_key, var: metadata_1_key}, {name: metadata_1_privacy, var: metadata_1_privacy}, {name: "metadata_1_values[]", var: metadata_1_values}, {name: metadata_2_key, var: metadata_2_key}, {name: metadata_2_privacy, var: metadata_2_privacy}, {name: "metadata_2_values[]", var: metadata_2_values}, {name: text_emoticons, var: text_emoticons}, {name: text_raw, var: text_raw}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, bubbled: $bubbled, metadata_0_key: $metadata_0_key, metadata_0_privacy: $metadata_0_privacy, metadata_0_values: $metadata_0_values, metadata_1_key: $metadata_1_key, metadata_1_privacy: $metadata_1_privacy, metadata_1_values: $metadata_1_values, metadata_2_key: $metadata_2_key, metadata_2_privacy: $metadata_2_privacy, metadata_2_values: $metadata_2_values, text_emoticons: $text_emoticons, text_raw: $text_raw
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Paginated report of information about messages contributed by conversation and date. Only conversations that exist within the current access token's bubble are considered in the calculations. Optionally roll up all conversations to retrieve one record per date. Optionally specify a date formatted as YYYY-MM-DD to retrieve information just from the single date, along with additional navigational information, which is useful when generating a transcript for a single day and wanting to reference the previous and next days there were messages within the conversation(s).
#
# POST /conversations/{ID}/schedules
# Returns: record<data: table<author_count: float, conversation_count: float, conversation_id: float, date: string, first_message: record, last_message: record, message_count: float, my_message_count: float, navigation: record>, pagination: record<limit: float, offset: float, total_records: float>>
export def "post-conversations-id-schedules" [
  id: list<int>
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --roll-up: oneof<nothing, bool> # default: false
  --sort: string@sort-completer # default: desc
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations/{ID}/schedules"
    path_params: [{name: ID, var: id, encode: array}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: date, var: date}, {name: limit, var: limit}, {name: offset, var: offset}, {name: roll_up, var: roll_up}, {name: sort, var: sort}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, date: $date, limit: $limit, offset: $offset, roll_up: $roll_up, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch messages authored from within specified conversations that match a query string passed in as a search parameter along with their relevancy score.
#
# POST /conversations/{ID}/searches
# Returns: record<data: table<message: record, relevance: record>, pagination: record<limit: float, offset: float, total_records: float>>
export def "post-conversations-id-searches" [
  id: list<int>
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string
  --gt-message-id: int # format: int32
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  query: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations/{ID}/searches"
    path_params: [{name: ID, var: id, encode: array}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: date, var: date}, {name: gt_message_id, var: gt_message_id}, {name: limit, var: limit}, {name: offset, var: offset}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, date: $date, gt_message_id: $gt_message_id, limit: $limit, offset: $offset, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Status information about your current relationship with one or more conversations you participating in, provided the conversations exist within the current access token's bubble.
#
# GET /conversations/{ID}/statuses
# Returns: record<data: table<archived_status: bool, bubbled: record, conversation: record, earliest_unseen_message: record, new_message_count: float>>
export def "get-conversations-id-statuses" [
  id: list<int>
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
    path: "/conversations/{ID}/statuses"
    path_params: [{name: ID, var: id, encode: array}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archive or unarchive a conversation that is with a user who exists within the same bubble.
#
# PATCH /conversations/{ID}/statuses
# Returns: record<data: record<archived_status: bool, conversation: record<first_message: record, id: float, latest_message: record, user_a: record, user_b: record>>, success: bool>
export def "patch-conversations-id-statuses" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --archived-status: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/conversations/{ID}/statuses"
    path_params: [{name: ID, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: archived_status, var: archived_status, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, archived_status: $archived_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an array of all groups that were created by users existing within the current access token's bubble. The groups must be either Public or you must be a member of them. Unlisted and Private groups that you are not a member of are not listed.
#
# GET /groups
# Returns: record<data: table<first_message: record, id: float, latest_message: record, member_count: float, owner: record, properties: record>, pagination: record<limit: float, offset: float, total_records: float>>
export def "get-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new group for other members to join. Any user who is using an access token whose bubble you exist in can join your group provided it is not a private group. Private groups can only be joined by members who know its passphrase. Unlisted groups can be joined by anybody as long as they know the Group ID, but they are not referenced anywhere to non-members. Public groups can be joined by anybody, are discoverable, and anyone can see the public groups a user is a member of, provided the group owner exists in their access token's bubble. Groups each have their own discussions, transcripts, schedules, and ability to list and search their members.
#
# POST /groups
# Returns: record<data: record<first_message: record<timestamp: string>, id: float, latest_message: record<author: record, group: any, id: float, last_seen: record, moderated: record, text: record, timestamp: string>, member_count: float, owner: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>, properties: record<description: string, name: string, privacy: string, slug: string>>, success: bool>
export def "post-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string
  name: string
  --passphrase: string
  privacy: string@privacy-completer
  slug: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: description, var: description}, {name: name, var: name}, {name: passphrase, var: passphrase}, {name: privacy, var: privacy}, {name: slug, var: slug}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, name: $name, passphrase: $passphrase, privacy: $privacy, slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Paginated listing of messages filtered by arbitrary metadata criteria. Messages must match on all key/value pairs passed in. Messages may only match on one value of an array passed in. However, messages are sorted based on how many distinct values they match on (most matches first).
#
# POST /groups/messages/metadata/filters
# Returns: record<data: table<matched_metadata: record, message: record>, pagination: record<limit: float, offset: float, total_records: float>>
export def "post-groups-messages-metadata-filters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int32, default: 50
  --metadata-0-key: string
  --metadata-0-values: list<string>
  --metadata-1-key: string
  --metadata-1-values: list<string>
  --metadata-2-key: string
  --metadata-2-values: list<string>
  --offset: int # format: int32, default: 0
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/messages/metadata/filters"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: limit, var: limit}, {name: metadata_0_key, var: metadata_0_key}, {name: "metadata_0_values[]", var: metadata_0_values}, {name: metadata_1_key, var: metadata_1_key}, {name: "metadata_1_values[]", var: metadata_1_values}, {name: metadata_2_key, var: metadata_2_key}, {name: "metadata_2_values[]", var: metadata_2_values}, {name: offset, var: offset}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, metadata_0_key: $metadata_0_key, metadata_0_values: $metadata_0_values, metadata_1_key: $metadata_1_key, metadata_1_values: $metadata_1_values, metadata_2_key: $metadata_2_key, metadata_2_values: $metadata_2_values, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an array of group messages. You must be the owner or moderator of the group.
#
# DELETE /groups/messages/{ID}
# Returns: record<data: table<author: record, group: record, id: float, last_seen: record, moderated: record, text: record, timestamp: string>, status: bool>
export def "delete-groups-messages-id" [
  id: list<int>
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
    path: "/groups/messages/{ID}"
    path_params: [{name: ID, var: id, encode: array}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an array of group messages. You can only retrieve messages authored by you or by users existing within the current access token's bubble.
#
# GET /groups/messages/{ID}
# Returns: record<data: table<author: record, group: record, id: float, last_seen: record, moderated: record, text: record, timestamp: string>>
export def "get-groups-messages-id" [
  id: list<int>
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
    path: "/groups/messages/{ID}"
    path_params: [{name: ID, var: id, encode: array}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all key/value pairs attached to the current message that you have access to, so long as the user who created the group exists within the current access token's bubble. This includes all public metadata, bubbled metadata that was created by an access token existing within the current bubble, user metadata that was created by you, or private metadata created by you from an access token existing within the current bubble.
#
# GET /groups/messages/{ID}/metadata
# Returns: record<data: table<app: record, content: record, id: float, message: record, owner: record, settings: record, status: record>, pagination: record<limit: float, offset: float, total_records: float>>
export def "get-groups-messages-id-metadata" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/messages/{ID}/metadata"
    path_params: [{name: ID, var: id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attach one-to-many key/value pairs of metadata to a group message, so long as the user who authored the message exists within the current access token's bubble and you are a member of their group. A key is unique for each author/bubble combination. Attaching metadata with an existing key that was previously created by you, from within the same bubble, overwrites the key with the new value or set of values. The privacy setting allows you to specify who will have access to the metadata: Public metadata by anyone using an access token which grants them access to the user who authored the message and who is also a member of the group the message belongs to; Bubbled metadata by anyone using an access token existing within the current bubble who is also a member of the group the message belongs to; User metadata by you, so long as you are using an access token which grants you access to the user who authored the message and you remain a member of the group; Private metadata by you, so long as you are using an access token existing within the current bubble and you remain a member of the group.
#
# POST /groups/messages/{ID}/metadata
# Returns: record<data: record, success: bool>
export def "post-groups-messages-id-metadata" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata-0-key: string
  --metadata-0-privacy: string@metadata-0-privacy-completer
  --metadata-0-values: list<string>
  --metadata-1-key: string
  --metadata-1-privacy: string@metadata-1-privacy-completer
  --metadata-1-values: list<string>
  --metadata-2-key: string
  --metadata-2-privacy: string@metadata-2-privacy-completer
  --metadata-2-values: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/messages/{ID}/metadata"
    path_params: [{name: ID, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: metadata_0_key, var: metadata_0_key}, {name: metadata_0_privacy, var: metadata_0_privacy}, {name: "metadata_0_values[]", var: metadata_0_values}, {name: metadata_1_key, var: metadata_1_key}, {name: metadata_1_privacy, var: metadata_1_privacy}, {name: "metadata_1_values[]", var: metadata_1_values}, {name: metadata_2_key, var: metadata_2_key}, {name: metadata_2_privacy, var: metadata_2_privacy}, {name: "metadata_2_values[]", var: metadata_2_values}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, metadata_0_key: $metadata_0_key, metadata_0_privacy: $metadata_0_privacy, metadata_0_values: $metadata_0_values, metadata_1_key: $metadata_1_key, metadata_1_privacy: $metadata_1_privacy, metadata_1_values: $metadata_1_values, metadata_2_key: $metadata_2_key, metadata_2_privacy: $metadata_2_privacy, metadata_2_values: $metadata_2_values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all key/value pairs attached to the current message that you have access to, so long as the user who created the group exists within the current access token's bubble. This includes all public metadata, bubbled metadata that was created by an access token existing within the current bubble, user metadata that was created by you, or private metadata created by you from an access token existing within the current bubble. Metadata will be grouped by key.
#
# GET /groups/messages/{ID}/metadata/collections
# Returns: record<data: record>
export def "get-groups-messages-id-metadata-collections" [
  id: int
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
    path: "/groups/messages/{ID}/metadata/collections"
    path_params: [{name: ID, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Paginated report of information about messages contributed by group and date. Only groups you're a member of and group messages authored by users the current access token has access to are considered in the calculations. Optionally roll up all groups to retrieve one record per date. Optionally specify a date formatted as YYYY-MM-DD to retrieve information just from the single date, along with additional navigational information, which is useful when generating a transcript for a single day and wanting to reference the previous and next days there were messages.
#
# POST /groups/schedules
# Returns: record<data: table<author_count: float, date: string, first_message: record, group_count: float, group_id: float, last_message: record, message_count: float, my_message_count: float, navigation: record>, pagination: record<limit: float, offset: float, total_records: float>>
export def "post-groups-schedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --roll-up: oneof<nothing, bool> # default: false
  --sort: string@sort-completer # default: desc
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/schedules"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: date, var: date}, {name: limit, var: limit}, {name: offset, var: offset}, {name: roll_up, var: roll_up}, {name: sort, var: sort}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date: $date, limit: $limit, offset: $offset, roll_up: $roll_up, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve groups that were created by users within the current access token's bubble, along with your current relationship with the groups. The groups must be either Public or you must be a member of them. Unlisted and Private groups that you are not a member of are not listed. Optionally only retrieve groups that you are a member of.
#
# GET /groups/statuses
# Returns: record<data: table<earliest_unseen_message: record, group: record, new_message_count: float>, pagination: record<limit: float, offset: float, total_records: float>>
export def "get-groups-statuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --existing-membership: oneof<nothing, bool> # default: false, allows empty value
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/statuses"
    query: [{name: existing_membership, var: existing_membership}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    existing_membership: $existing_membership, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an array of groups. You can only retrieve groups created by users existing within the current access token's bubble.
#
# GET /groups/{ID}
# Returns: record<data: table<first_message: record, id: float, latest_message: record, member_count: float, owner: record, properties: record>>
export def "get-groups-id" [
  id: list<int>
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
    path: "/groups/{ID}"
    path_params: [{name: ID, var: id, encode: array}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a group you previously created.
#
# PATCH /groups/{ID}
# Returns: record<data: record<first_message: record<timestamp: string>, id: float, latest_message: record<author: record, group: any, id: float, last_seen: record, moderated: record, text: record, timestamp: string>, member_count: float, owner: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>, properties: record<description: string, name: string, privacy: string, slug: string>>, success: bool>
export def "patch-groups-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --name: string
  --passphrase: string
  --privacy: string@privacy-completer
  --slug: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/groups/{ID}"
    path_params: [{name: ID, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: description, var: description}, {name: name, var: name}, {name: passphrase, var: passphrase}, {name: privacy, var: privacy}, {name: slug, var: slug}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, description: $description, name: $name, passphrase: $passphrase, privacy: $privacy, slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Leave a group that you are a member of and that was created by a user who exists within the current access token's bubble.
#
# DELETE /groups/{ID}/memberships
# Returns: record<success: bool>
export def "delete-groups-id-memberships" [
  id: int
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
    path: "/groups/{ID}/memberships"
    path_params: [{name: ID, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an array of users who are members of specific groups that you are also a member of. You can only retrieve users existing within the current access token's bubble.
#
# GET /groups/{ID}/memberships
# Returns: record<data: table<group: record, member: record, privileges: record>, pagination: record<limit: float, offset: float, total_records: float>>
export def "get-groups-id-memberships" [
  id: list<int>
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --moderators-only: oneof<nothing, bool> # default: false, allows empty value
  --offset: int # format: int32, default: 0, allows empty value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{ID}/memberships"
    path_params: [{name: ID, var: id, encode: array}]
    query: [{name: moderators_only, var: moderators_only}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, moderators_only: $moderators_only, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Promote or demote a member's privileges within a group that you created. The user must exist within the current access token's bubble and be an existing member of the group.
#
# PATCH /groups/{ID}/memberships
# Returns: record<data: table<group: record, member: record, privileges: record>, pagination: record<limit: float, offset: float, total_records: float>, success: bool>
export def "patch-groups-id-memberships" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --moderator: oneof<nothing, bool> # default: false
  user_id: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/groups/{ID}/memberships"
    path_params: [{name: ID, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: moderator, var: moderator}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, moderator: $moderator, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Join a group that was created by a user who exists within the current access token's bubble, or join other users into a group that you created. If you are the group owner, you can pass in a user_id to create membership records for a user you are in a conversation with. The user must exist within the current access token's bubble. If the group is private, you must successfully pass in its passphrase in order to join. You can obtain the passphrase from the group's owner.
#
# POST /groups/{ID}/memberships
# Returns: record<data: record<group: record<first_message: record, id: float, latest_message: record, member_count: float, owner: record, properties: record>, member: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>>, success: bool>
export def "post-groups-id-memberships" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --passphrase: string
  --user-id: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/{ID}/memberships"
    path_params: [{name: ID, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: passphrase, var: passphrase}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, passphrase: $passphrase, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the last {limit} messages in the group, for messages authored by users within the current access token's bubble. If a timeout is 0 or greater, the batch is sorted oldest first. Otherwise, if timeout is a negative number, the transcript is paginated and sorted newest first. Specify a timeout for long polling (which delays the server sending back results for up to n seconds or until results are available, whichever comes first), or default to 0 for immediate results. Optionally record your status as online along with sharing the latest message you've seen with other group members. Optionally specify a gt_message_id to retrieve only messages with an ID greater than that specified (such as greater than the latest message ID received in the last poll). Optionally only poll for messages authored by other members of the group, and echo messages authored by you when sending, for a perceived increase in performance. Optionally only retrieve messages that were posted from within the current access token's bubble. Optionally specify a date formatted as YYYY-MM-DD to retrieve a transcript of messages from a single day. When record_seen is set to true, the new message count for the group is reset to zero.
#
# GET /groups/{ID}/messages
# Returns: record<data: table<author: record, group: record, id: float, last_seen: record, moderated: record, text: record, timestamp: string>, pagination: record<limit: float, offset: float, total_records: float>>
export def "get-groups-id-messages" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --gt-message-id: int # format: int32, allows empty value
  --exclude-self: oneof<nothing, bool> # default: false, allows empty value
  --include-deleted: oneof<nothing, bool> # default: false, allows empty value
  --date: string # allows empty value
  --bubbled: oneof<nothing, bool> # default: false, allows empty value
  --record-seen: oneof<nothing, bool> # default: false, allows empty value
  --timeout: int # format: int32, default: 0, allows empty value
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{ID}/messages"
    path_params: [{name: ID, var: id}]
    query: [{name: gt_message_id, var: gt_message_id}, {name: exclude_self, var: exclude_self}, {name: include_deleted, var: include_deleted}, {name: date, var: date}, {name: bubbled, var: bubbled}, {name: record_seen, var: record_seen}, {name: timeout, var: timeout}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, gt_message_id: $gt_message_id, exclude_self: $exclude_self, include_deleted: $include_deleted, date: $date, bubbled: $bubbled, record_seen: $record_seen, timeout: $timeout, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Post a message to a group that you are a member of and that was created by a user who exists within the current access token's bubble. Optionally specify whether emoticons should be parsed into smiley images. Additionally, optionally attach a single metadata key/value pair to the group message upon submission.
#
# POST /groups/{ID}/messages
# Returns: record<data: table<author: record, group: record, id: float, last_seen: record, moderated: record, text: record, timestamp: string>, success: bool>
export def "post-groups-id-messages" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata-0-key: string
  --metadata-0-privacy: string@metadata-0-privacy-completer
  --metadata-0-values: list<string>
  --metadata-1-key: string
  --metadata-1-privacy: string@metadata-1-privacy-completer
  --metadata-1-values: list<string>
  --metadata-2-key: string
  --metadata-2-privacy: string@metadata-2-privacy-completer
  --metadata-2-values: list<string>
  --text-emoticons: oneof<nothing, bool> # default: false
  text_raw: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/{ID}/messages"
    path_params: [{name: ID, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: metadata_0_key, var: metadata_0_key}, {name: metadata_0_privacy, var: metadata_0_privacy}, {name: "metadata_0_values[]", var: metadata_0_values}, {name: metadata_1_key, var: metadata_1_key}, {name: metadata_1_privacy, var: metadata_1_privacy}, {name: "metadata_1_values[]", var: metadata_1_values}, {name: metadata_2_key, var: metadata_2_key}, {name: metadata_2_privacy, var: metadata_2_privacy}, {name: "metadata_2_values[]", var: metadata_2_values}, {name: text_emoticons, var: text_emoticons}, {name: text_raw, var: text_raw}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, metadata_0_key: $metadata_0_key, metadata_0_privacy: $metadata_0_privacy, metadata_0_values: $metadata_0_values, metadata_1_key: $metadata_1_key, metadata_1_privacy: $metadata_1_privacy, metadata_1_values: $metadata_1_values, metadata_2_key: $metadata_2_key, metadata_2_privacy: $metadata_2_privacy, metadata_2_values: $metadata_2_values, text_emoticons: $text_emoticons, text_raw: $text_raw
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Paginated report of information about group messages contributed by conversation and date. Only groups you're a member of and group messages authored by users existing within the current access token's bubble are considered in the calculations. Optionally roll up all groups to retrieve one record per date. Optionally specify a date formatted as YYYY-MM-DD to retrieve information just from the single date, along with additional navigational information, which is useful when generating a transcript for a single day and wanting to reference the previous and next days there were messages within the group discussion(s).
#
# POST /groups/{ID}/schedules
# Returns: record<data: table<author_count: float, date: string, first_message: record, group_count: float, group_id: float, last_message: record, message_count: float, my_message_count: float, navigation: record>, pagination: record<limit: float, offset: float, total_records: float>>
export def "post-groups-id-schedules" [
  id: list<int>
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string
  --limit: int # format: int32, default: 50
  --offset: int # format: int32, default: 0
  --roll-up: oneof<nothing, bool> # default: false
  --sort: string@sort-completer # default: desc
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/{ID}/schedules"
    path_params: [{name: ID, var: id, encode: array}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: date, var: date}, {name: limit, var: limit}, {name: offset, var: offset}, {name: roll_up, var: roll_up}, {name: sort, var: sort}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, date: $date, limit: $limit, offset: $offset, roll_up: $roll_up, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Status information about your current relationship with one or more groups you are a member of, provided the users who created the groups exist within the current access token's bubble.
#
# GET /groups/{ID}/statuses
# Returns: record<data: table<earliest_unseen_message: record, group: record, membership_status: bool, new_message_count: float>>
export def "get-groups-id-statuses" [
  id: list<int>
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
    path: "/groups/{ID}/statuses"
    path_params: [{name: ID, var: id, encode: array}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /industries
#
# Returns: record<data: list<string>>
export def "get-industries" [
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
    path: "/industries"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /markdown
#
# Returns: record<data: record<parsed: string, raw: string>>
export def "post-markdown" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --text-emoticons: oneof<nothing, bool> # default: false
  text_raw: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/markdown"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: text_emoticons, var: text_emoticons}, {name: text_raw, var: text_raw}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    text_emoticons: $text_emoticons, text_raw: $text_raw
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /markdown/emoticons
#
# Returns: record<data: table<alt: string, emoticon: string, image: string>>
export def "get-markdown-emoticons" [
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
    path: "/markdown/emoticons"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Paginated listing of messages filtered by arbitrary metadata criteria. Messages must match on all key/value pairs passed in. Messages may only match on one value of an array passed in. However, messages are sorted based on how many distinct values they match on (most matches first).
#
# POST /messages/metadata/filters
# Returns: record<data: table<matched_metadata: record, message: record>, pagination: record<limit: float, offset: float, total_records: float>>
export def "post-messages-metadata-filters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int32, default: 50
  --metadata-0-key: string
  --metadata-0-values: list<string>
  --metadata-1-key: string
  --metadata-1-values: list<string>
  --metadata-2-key: string
  --metadata-2-values: list<string>
  --offset: int # format: int32, default: 0
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/metadata/filters"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: limit, var: limit}, {name: metadata_0_key, var: metadata_0_key}, {name: "metadata_0_values[]", var: metadata_0_values}, {name: metadata_1_key, var: metadata_1_key}, {name: "metadata_1_values[]", var: metadata_1_values}, {name: metadata_2_key, var: metadata_2_key}, {name: "metadata_2_values[]", var: metadata_2_values}, {name: offset, var: offset}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, metadata_0_key: $metadata_0_key, metadata_0_values: $metadata_0_values, metadata_1_key: $metadata_1_key, metadata_1_values: $metadata_1_values, metadata_2_key: $metadata_2_key, metadata_2_values: $metadata_2_values, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an array of messages. You can only retrieve messages authored by you or by users who exist within the current access token's bubble.
#
# GET /messages/{ID}
# Returns: record<data: table<author: record, conversation: record, id: float, last_seen: record, text: record, timestamp: string>>
export def "get-messages-id" [
  id: list<int>
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
    path: "/messages/{ID}"
    path_params: [{name: ID, var: id, encode: array}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all key/value pairs attached to the current message that you have access to, so long as the user who authored the message exists within the current access token's bubble. This includes all public metadata, bubbled metadata that was created by an access token existing within the current bubble, user metadata that was created by you, or private metadata created by you from an access token existing within the current bubble.
#
# GET /messages/{ID}/metadata
# Returns: record<data: table<app: record, content: record, id: float, message: record, owner: record, settings: record, status: record>, pagination: record<limit: float, offset: float, total_records: float>>
export def "get-messages-id-metadata" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messages/{ID}/metadata"
    path_params: [{name: ID, var: id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attach one-to-many key/value pairs of metadata to a message, so long as the user who authored the message exists within the current access token's bubble. A key is unique for each author/bubble combination. Attaching metadata with an existing key that was previously created by you, from within the same bubble, overwrites the key with the new value or set of values. The privacy setting allows you to specify who will have access to the metadata: Public metadata by you or the other user in the message's conversation, using an access token which grants you access to the user who authored the message, if it wasn't you; Bubbled metadata by you or the other user in the message's conversation, using an access token existing within the current bubble; User metadata by you, so long as you are using an access token which grants you access to the user who authored the message, if it wasn't you; Private metadata by you, so long as you are using an access token existing within the current bubble.
#
# POST /messages/{ID}/metadata
# Returns: record<data: record, success: bool>
export def "post-messages-id-metadata" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata-0-key: string
  --metadata-0-privacy: string@metadata-0-privacy-completer
  --metadata-0-values: list<string>
  --metadata-1-key: string
  --metadata-1-privacy: string@metadata-1-privacy-completer
  --metadata-1-values: list<string>
  --metadata-2-key: string
  --metadata-2-privacy: string@metadata-2-privacy-completer
  --metadata-2-values: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/messages/{ID}/metadata"
    path_params: [{name: ID, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: metadata_0_key, var: metadata_0_key}, {name: metadata_0_privacy, var: metadata_0_privacy}, {name: "metadata_0_values[]", var: metadata_0_values}, {name: metadata_1_key, var: metadata_1_key}, {name: metadata_1_privacy, var: metadata_1_privacy}, {name: "metadata_1_values[]", var: metadata_1_values}, {name: metadata_2_key, var: metadata_2_key}, {name: metadata_2_privacy, var: metadata_2_privacy}, {name: "metadata_2_values[]", var: metadata_2_values}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, metadata_0_key: $metadata_0_key, metadata_0_privacy: $metadata_0_privacy, metadata_0_values: $metadata_0_values, metadata_1_key: $metadata_1_key, metadata_1_privacy: $metadata_1_privacy, metadata_1_values: $metadata_1_values, metadata_2_key: $metadata_2_key, metadata_2_privacy: $metadata_2_privacy, metadata_2_values: $metadata_2_values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all key/value pairs attached to the current message that you have access to, so long as the user who authored the message exists within the current access token's bubble. This includes all public metadata, bubbled metadata that was created by an access token existing within the current bubble, user metadata that was created by you, or private metadata created by you from an access token existing within the current bubble. Metadata will be grouped by key.
#
# GET /messages/{ID}/metadata/collections
# Returns: record<data: record>
export def "get-messages-id-metadata-collections" [
  id: int
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
    path: "/messages/{ID}/metadata/collections"
    path_params: [{name: ID, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the OAuth'ed end user's Curriculum Vitae by adding a position.
#
# POST /positions
# Returns: record<data: record<app: record<about: record, id: float, legal: record>, category: string, id: float, organization: record<industry: string, name: string, size: string, ticker: string, type: string, url: string>, role: record<end_date: string, start_date: string, summary: string, title: string>, user: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>>, success: bool>
export def "post-positions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  category: string@category-completer
  --end-date: string
  organization: string
  --organization-size: string@organization-size-completer
  --position: string@position-completer
  role: string
  start_date: string
  --summary: string
  --url: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/positions"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: category, var: category}, {name: end_date, var: end_date}, {name: organization, var: organization}, {name: organization_size, var: organization_size}, {name: position, var: position}, {name: role, var: role}, {name: start_date, var: start_date}, {name: summary, var: summary}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    category: $category, end_date: $end_date, organization: $organization, organization_size: $organization_size, position: $position, role: $role, start_date: $start_date, summary: $summary, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an item from the OAuth'ed end user's Curriculum Vitae.
#
# DELETE /positions/{ID}
# Returns: record<success: bool>
export def "delete-positions-id" [
  id: int
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
    path: "/positions/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the OAuth'ed end user's Curriculum Vitae by modifying an existing position.
#
# PATCH /positions/{ID}
# Returns: record<data: record<app: record<about: record, id: float, legal: record>, category: string, id: float, organization: record<industry: string, name: string, size: string, ticker: string, type: string, url: string>, role: record<end_date: string, start_date: string, summary: string, title: string>, user: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>>, success: bool>
export def "patch-positions-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  category: string@category-completer
  --end-date: string
  organization: string
  --organization-size: string@organization-size-completer
  --position: string@position-completer
  role: string
  start_date: string
  --summary: string
  --url: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/positions/{ID}"
    path_params: [{name: ID, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: category, var: category}, {name: end_date, var: end_date}, {name: organization, var: organization}, {name: organization_size, var: organization_size}, {name: position, var: position}, {name: role, var: role}, {name: start_date, var: start_date}, {name: summary, var: summary}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, category: $category, end_date: $end_date, organization: $organization, organization_size: $organization_size, position: $position, role: $role, start_date: $start_date, summary: $summary, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an array of users that you've been matched with, connected with, skipped, or muted. You can only retrieve users existing within the current access token's bubble. This report may be limited to the last ~500-1000 users you've communicated with within the access token's bubble. Matches are always ordered by synergy, and the order_by parameter is ignored. You can only retrieve bubbled users when retrieving matches, and the bubbled parameter is ignored otherwise. Your 100 best algorithmic matches are based on: Complementary data submitted to Profiles, CVs, and Metadata; Complementary data acquired from third-parties; Location information; Many behavioral data points, such as how responsive users are to connections; Degrees of separation (mutual connections); etc. You may connect with 3 of these algorithmic matches per day for free. However, new members are allowed a grace period of additional daily matches. Each time you choose to meet or mute one of your algorithmic matches, a new match is introduced.
#
# GET /users
# Returns: record<data: table<business_card: record, community_persona: record, id: float, profile: record, usage: record>, pagination: record<limit: float, offset: float, total_records: float>>
export def "get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-1 # default: connections, allows empty value
  --order-by: string@order-by-completer # default: id, allows empty value
  --bubbled: oneof<nothing, bool> # default: false, allows empty value
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: filter, var: filter}, {name: order_by, var: order_by}, {name: bubbled, var: bubbled}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, order_by: $order_by, bubbled: $bubbled, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invite users to into your current access token's bubble by having Dazah send out email invitations on your behalf. The invitation sends users to begin the OAuth flow for the current application (based on the settings specified in the application's profile), and therefore they will be redirected to the application upon signing up / logging in. Upon doing so, if they aren't already, they will automatically be connected with you as well. If your current access token does not escape the bubble, the invitation will specify you wish to connect within the application's name. If your current access token escapes the bubble, the invitation will specify you wish to connect within Dazah. Submit either a list of emails, or a LinkedIn or Outlook CSV file. You can retrieve your LinkedIn CSV file by exporting your LinkedIn Connections at https://www.linkedin.com/people/export-settings. You can retrieve your Outlook CSV file by using the Outlook Import and Export Wizard. This endpoint buckets the invitations into four categories: Existing invites are existing users who are already connected with you within the current bubble, and are therefore not emailed; Discovered invites are existing Dazah users who are available to be connected with within the current bubble, and are therefore not emailed. Now that they have been discovered, the users/{:ID}/meet API endpoint may be used to connect with them; Invalid invites are existing Dazah users who are unavailable to be connected with, because they have deactivated accounts, are muting you, etc., and are therefore not emailed; Emailed invites are queued to receive an invitation within approximately 1 hour. Note that if you are attempting to invite an existing Dazah user who does not currently exist within your current access token's bubble, they will fall within the Discovered bucket if your current access token escapes the bubble, but will be emailed an invitation to join the application if your current access token does not escape the bubble.
#
# POST /users/invites
# Returns: record<data: record<discovered: record<users: list>, emailed: record<emails: list>, existing: record<conversations: list>, invalid: record<emails: list>>, success: bool>
export def "post-users-invites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --csv: string # format: binary
  --emails: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/invites"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: csv, var: csv}, {name: "emails[]", var: emails}], files: [csv]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    csv: $csv, emails: $emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Paginated listing of users filtered by arbitrary metadata criteria. Users must match on all key/value pairs passed in. Users may only match on one value of an array passed in. However, users are sorted based on how many distinct values they match on (most matches first).
#
# POST /users/metadata/filters
# Returns: record<data: table<matched_metadata: record, user: record>, pagination: record<limit: float, offset: float, total_records: float>>
export def "post-users-metadata-filters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int32, default: 50
  --metadata-0-key: string
  --metadata-0-values: list<string>
  --metadata-1-key: string
  --metadata-1-values: list<string>
  --metadata-2-key: string
  --metadata-2-values: list<string>
  --offset: int # format: int32, default: 0
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/metadata/filters"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: limit, var: limit}, {name: metadata_0_key, var: metadata_0_key}, {name: "metadata_0_values[]", var: metadata_0_values}, {name: metadata_1_key, var: metadata_1_key}, {name: "metadata_1_values[]", var: metadata_1_values}, {name: metadata_2_key, var: metadata_2_key}, {name: "metadata_2_values[]", var: metadata_2_values}, {name: offset, var: offset}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, metadata_0_key: $metadata_0_key, metadata_0_values: $metadata_0_values, metadata_1_key: $metadata_1_key, metadata_1_values: $metadata_1_values, metadata_2_key: $metadata_2_key, metadata_2_values: $metadata_2_values, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an array of users that are geographically close to a set of coordinates. You can only retrieve users existing within the current access token's bubble.
#
# GET /users/nearby
# Returns: record<data: table<distance_away: record, user: record>, pagination: record<limit: float, offset: float, total_records: float>>
export def "get-users-nearby" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --latitude: float # format: float, allows empty value
  --longitude: float # format: float, allows empty value
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/nearby"
    query: [{name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    latitude: $latitude, longitude: $longitude, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Filter and perform a weighted search against user profile fields, CV fields, and metadata by specifying a string to search on for each individual field. By default, results are filtered such that all words in the string must exist, unless you seprate the words with OR. To perform a weighted search (as opposed to filtering), specify the weight (from 0-100) the search algorithm should assign to the field. You can optionally exclude users who you are already in or not in conversations with, exclude users who you previously skipped, or exclude users who you are muting. By doing so, you can effectively customize your own matching algorithm. You can specify geo coordinates to only find users a certain distance away from a specific location, or only find users within a certain distance from the OAuth'ed end-user's last known location. If your app utilizes multiple audience segments, you can specify which audiences you would like to search. You can also limit users to just those who have been recently active. You can also choose to only receive users originating from the current access token's bubble. Only users existing within the current access token's bubble will be matched, and you can only search within a group created by a bubbled user.
#
# POST /users/searches
# Returns: record<data: table<relevance: record, user: record>, pagination: record<limit: float, offset: float, total_records: float>>
export def "post-users-searches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active-within-x-days: int # format: int32
  --audience-ids: list<int>
  --bubbled: oneof<nothing, bool> # default: false
  --exclude-connections: oneof<nothing, bool> # default: false
  --exclude-matches: oneof<nothing, bool> # default: false
  --exclude-muted: oneof<nothing, bool> # default: false
  --exclude-skipped: oneof<nothing, bool> # default: false
  --geo-latitude: float # format: float
  --geo-longitude: float # format: float
  --geo-miles-away: float # format: float
  --group-id: int # format: int32
  --limit: int # format: int32, default: 50
  --location-city-query: string
  --location-city-weight: int # format: int32
  --location-country-query: string
  --location-country-weight: int # format: int32
  --location-region-query: string
  --location-region-weight: int # format: int32
  --metadata-0-key: string
  --metadata-0-query: string
  --metadata-0-weight: int # format: int32
  --metadata-1-key: string
  --metadata-1-query: string
  --metadata-1-weight: int # format: int32
  --metadata-2-key: string
  --metadata-2-query: string
  --metadata-2-weight: int # format: int32
  --offset: int # format: int32, default: 0
  --position-organization-query: string
  --position-organization-weight: int # format: int32
  --position-role-query: string
  --position-role-weight: int # format: int32
  --position-summary-query: string
  --position-summary-weight: int # format: int32
  --profile-first-name-query: string
  --profile-first-name-weight: int # format: int32
  --profile-goals-query: string
  --profile-goals-weight: string
  --profile-headline-query: string
  --profile-headline-weight: int # format: int32
  --profile-industry-query: string
  --profile-industry-weight: int # format: int32
  --profile-last-name-query: string
  --profile-last-name-weight: int # format: int32
  --profile-pitch-query: string
  --profile-pitch-weight: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/searches"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: active_within_x_days, var: active_within_x_days}, {name: "audience_ids[]", var: audience_ids}, {name: bubbled, var: bubbled}, {name: exclude_connections, var: exclude_connections}, {name: exclude_matches, var: exclude_matches}, {name: exclude_muted, var: exclude_muted}, {name: exclude_skipped, var: exclude_skipped}, {name: geo_latitude, var: geo_latitude}, {name: geo_longitude, var: geo_longitude}, {name: geo_miles_away, var: geo_miles_away}, {name: group_id, var: group_id}, {name: limit, var: limit}, {name: location_city_query, var: location_city_query}, {name: location_city_weight, var: location_city_weight}, {name: location_country_query, var: location_country_query}, {name: location_country_weight, var: location_country_weight}, {name: location_region_query, var: location_region_query}, {name: location_region_weight, var: location_region_weight}, {name: metadata_0_key, var: metadata_0_key}, {name: metadata_0_query, var: metadata_0_query}, {name: metadata_0_weight, var: metadata_0_weight}, {name: metadata_1_key, var: metadata_1_key}, {name: metadata_1_query, var: metadata_1_query}, {name: metadata_1_weight, var: metadata_1_weight}, {name: metadata_2_key, var: metadata_2_key}, {name: metadata_2_query, var: metadata_2_query}, {name: metadata_2_weight, var: metadata_2_weight}, {name: offset, var: offset}, {name: position_organization_query, var: position_organization_query}, {name: position_organization_weight, var: position_organization_weight}, {name: position_role_query, var: position_role_query}, {name: position_role_weight, var: position_role_weight}, {name: position_summary_query, var: position_summary_query}, {name: position_summary_weight, var: position_summary_weight}, {name: profile_first_name_query, var: profile_first_name_query}, {name: profile_first_name_weight, var: profile_first_name_weight}, {name: profile_goals_query, var: profile_goals_query}, {name: profile_goals_weight, var: profile_goals_weight}, {name: profile_headline_query, var: profile_headline_query}, {name: profile_headline_weight, var: profile_headline_weight}, {name: profile_industry_query, var: profile_industry_query}, {name: profile_industry_weight, var: profile_industry_weight}, {name: profile_last_name_query, var: profile_last_name_query}, {name: profile_last_name_weight, var: profile_last_name_weight}, {name: profile_pitch_query, var: profile_pitch_query}, {name: profile_pitch_weight, var: profile_pitch_weight}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    active_within_x_days: $active_within_x_days, audience_ids: $audience_ids, bubbled: $bubbled, exclude_connections: $exclude_connections, exclude_matches: $exclude_matches, exclude_muted: $exclude_muted, exclude_skipped: $exclude_skipped, geo_latitude: $geo_latitude, geo_longitude: $geo_longitude, geo_miles_away: $geo_miles_away, group_id: $group_id, limit: $limit, location_city_query: $location_city_query, location_city_weight: $location_city_weight, location_country_query: $location_country_query, location_country_weight: $location_country_weight, location_region_query: $location_region_query, location_region_weight: $location_region_weight, metadata_0_key: $metadata_0_key, metadata_0_query: $metadata_0_query, metadata_0_weight: $metadata_0_weight, metadata_1_key: $metadata_1_key, metadata_1_query: $metadata_1_query, metadata_1_weight: $metadata_1_weight, metadata_2_key: $metadata_2_key, metadata_2_query: $metadata_2_query, metadata_2_weight: $metadata_2_weight, offset: $offset, position_organization_query: $position_organization_query, position_organization_weight: $position_organization_weight, position_role_query: $position_role_query, position_role_weight: $position_role_weight, position_summary_query: $position_summary_query, position_summary_weight: $position_summary_weight, profile_first_name_query: $profile_first_name_query, profile_first_name_weight: $profile_first_name_weight, profile_goals_query: $profile_goals_query, profile_goals_weight: $profile_goals_weight, profile_headline_query: $profile_headline_query, profile_headline_weight: $profile_headline_weight, profile_industry_query: $profile_industry_query, profile_industry_weight: $profile_industry_weight, profile_last_name_query: $profile_last_name_query, profile_last_name_weight: $profile_last_name_weight, profile_pitch_query: $profile_pitch_query, profile_pitch_weight: $profile_pitch_weight
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch an array of users. You can only retrieve users existing within the current access token's bubble.
#
# GET /users/{ID}
# Returns: record<data: table<business_card: record, community_persona: record, id: float, profile: record, usage: record>>
export def "get-users-id" [
  id: list<int>
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
    path: "/users/{ID}"
    path_params: [{name: ID, var: id, encode: array}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# You can only retrieve groups that were created by users existing within the current access token's bubble.
#
# GET /users/{ID}/groups
# Returns: record<data: table<first_message: record, id: float, latest_message: record, member_count: float, owner: record, properties: record>>
export def "get-users-id-groups" [
  id: int
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
    path: "/users/{ID}/groups"
    path_params: [{name: ID, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Paginated transcript of group messages authored by an individual user who exists within the current access token's bubble. Messages are sorted oldest to newest.
#
# GET /users/{ID}/groups/messages
# Returns: record<data: table<author: record, group: record, id: float, last_seen: record, moderated: record, text: record, timestamp: string>, pagination: record<limit: float, offset: float, total_records: float>>
export def "get-users-id-groups-messages" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{ID}/groups/messages"
    path_params: [{name: ID, var: id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiate a conversation with a user who exists within the current access token's bubble by sending them an introductory message. If you aren't already in a conversation with them, this endpoint meets them first, and then sends the message. Note that if you aren't in an existing conversation, you still must meet the criteria to meet them, meaning the user must currently be free for you to meet. You will receive an error message unless it is currently free for you to meet the user. You can use the users/{:IDS}/synergies endpoint to first determine if the user isn't already in a conversation with you and is free for you to meet and, if they aren't, how to pay to meet them. If you don't specify a message, it defaults to your custom introductory message defined in your settings.
#
# POST /users/{ID}/messages
# Returns: record<data: record<author: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>, conversation: record<first_message: record, id: float, latest_message: any, user_a: record, user_b: record>, id: float, last_seen: record<timestamp: string, user: record>, text: record<parsed: string>, timestamp: string>, success: bool>
export def "post-users-id-messages" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bubbled: oneof<nothing, bool> # default: false
  --metadata-0-key: string
  --metadata-0-privacy: string@metadata-0-privacy-completer
  --metadata-0-values: list<string>
  --metadata-1-key: string
  --metadata-1-privacy: string@metadata-1-privacy-completer
  --metadata-1-values: list<string>
  --metadata-2-key: string
  --metadata-2-privacy: string@metadata-2-privacy-completer
  --metadata-2-values: list<string>
  --text-emoticons: oneof<nothing, bool> # default: false
  --text-raw: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{ID}/messages"
    path_params: [{name: ID, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: bubbled, var: bubbled}, {name: metadata_0_key, var: metadata_0_key}, {name: metadata_0_privacy, var: metadata_0_privacy}, {name: "metadata_0_values[]", var: metadata_0_values}, {name: metadata_1_key, var: metadata_1_key}, {name: metadata_1_privacy, var: metadata_1_privacy}, {name: "metadata_1_values[]", var: metadata_1_values}, {name: metadata_2_key, var: metadata_2_key}, {name: metadata_2_privacy, var: metadata_2_privacy}, {name: "metadata_2_values[]", var: metadata_2_values}, {name: text_emoticons, var: text_emoticons}, {name: text_raw, var: text_raw}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, bubbled: $bubbled, metadata_0_key: $metadata_0_key, metadata_0_privacy: $metadata_0_privacy, metadata_0_values: $metadata_0_values, metadata_1_key: $metadata_1_key, metadata_1_privacy: $metadata_1_privacy, metadata_1_values: $metadata_1_values, metadata_2_key: $metadata_2_key, metadata_2_privacy: $metadata_2_privacy, metadata_2_values: $metadata_2_values, text_emoticons: $text_emoticons, text_raw: $text_raw
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all key/value pairs attached to the current user that you have access to, so long as the user exists within the current access token's bubble. This includes all public metadata, bubbled metadata that was created by an access token existing within the current bubble, user metadata that was created by you, or private metadata created by you from an access token existing within the current bubble. You will receive an error message unless either the current access token is bubbled, the user is an algorithmic match for you and you have not reached your quota of new introductions for the day, or you have paid to meet them. However, you can always use the /users/metadata/filters endpoint to filter across all users, including those that are unmatched, existing within the current access token's bubble based on preknown metadata key/value pairs.
#
# GET /users/{ID}/metadata
# Returns: record<data: table<app: record, content: record, id: float, owner: record, settings: record, status: record, user: record>, pagination: record<limit: float, offset: float, total_records: float>>
export def "get-users-id-metadata" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int32, default: 0, allows empty value
  --limit: int # format: int32, default: 50, allows empty value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{ID}/metadata"
    path_params: [{name: ID, var: id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attach one-to-many key/value pairs of metadata to a user, so long as the user exists within the current access token's bubble. You can set one key at a time, with one or many values. A key is unique for each author/bubble combination. Attaching metadata with an existing key that was previously created by you, from within the same bubble, overwrites the key with the new value or set of values. The privacy setting allows you to specify who will have access to the metadata: Public metadata by anyone using an access token which grants them access to the user; Bubbled metadata by anyone using an access token existing within the current bubble; User metadata by you, so long as you are using an access token which grants you access to the user; Private metadata by you, so long as you are using an access token existing within the current bubble.
#
# POST /users/{ID}/metadata
# Returns: record<data: record, success: bool>
export def "post-users-id-metadata" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata-0-key: string
  --metadata-0-privacy: string@metadata-0-privacy-completer
  --metadata-0-values: list<string>
  --metadata-1-key: string
  --metadata-1-privacy: string@metadata-1-privacy-completer
  --metadata-1-values: list<string>
  --metadata-2-key: string
  --metadata-2-privacy: string@metadata-2-privacy-completer
  --metadata-2-values: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{ID}/metadata"
    path_params: [{name: ID, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: metadata_0_key, var: metadata_0_key}, {name: metadata_0_privacy, var: metadata_0_privacy}, {name: "metadata_0_values[]", var: metadata_0_values}, {name: metadata_1_key, var: metadata_1_key}, {name: metadata_1_privacy, var: metadata_1_privacy}, {name: "metadata_1_values[]", var: metadata_1_values}, {name: metadata_2_key, var: metadata_2_key}, {name: metadata_2_privacy, var: metadata_2_privacy}, {name: "metadata_2_values[]", var: metadata_2_values}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, metadata_0_key: $metadata_0_key, metadata_0_privacy: $metadata_0_privacy, metadata_0_values: $metadata_0_values, metadata_1_key: $metadata_1_key, metadata_1_privacy: $metadata_1_privacy, metadata_1_values: $metadata_1_values, metadata_2_key: $metadata_2_key, metadata_2_privacy: $metadata_2_privacy, metadata_2_values: $metadata_2_values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all key/value pairs attached to the current user that you have access to, so long as the user exists within the current access token's bubble. This includes all public metadata, bubbled metadata that was created by an access token existing within the current bubble, user metadata that was created by you, or private metadata created by you from an access token existing within the current bubble. You will receive an error message unless either the current access token is bubbled, the user is an algorithmic match for you and you have not reached your quota of new introductions for the day, or you have paid to meet them. However, you can always use the /users/metadata/filters endpoint to filter across all users, including those that are unmatched, existing within the current access token's bubble based on preknown metadata key/value pairs. Metadata will be grouped by key.
#
# GET /users/{ID}/metadata/collections
# Returns: record<data: record>
export def "get-users-id-metadata-collections" [
  id: int
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
    path: "/users/{ID}/metadata/collections"
    path_params: [{name: ID, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the CV of a user who exists within the current access token's bubble. You will receive an error message unless either the current access token is bubbled, the user is an algorithmic match for you and you have not reached your quota of new introductions for the day, or you have paid to meet them. You can only record CV data to your own account. However, any app that you have OAuth'ed against can do so. By default, you will receive CV data that all apps have recorded for the user. Optionally, you can choose to only receive data that the current access token's bubble has recorded.
#
# GET /users/{ID}/positions
# Returns: record<data: table<app: record, category: string, id: float, organization: record, role: record, user: record>>
export def "get-users-id-positions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bubbled: oneof<nothing, bool> # default: false, allows empty value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{ID}/positions"
    path_params: [{name: ID, var: id}]
    query: [{name: bubbled, var: bubbled}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, bubbled: $bubbled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Determine your match relationship with one or more users who exist within the current access token's bubble. Under some conditions, the price to meet the user will be $0. However, if this is not the case, the PayPal URL payment method will be provided along with the price to meet the user. The PayPal API can be leveraged to send payments programatically, provided the parameters passed in remain the same to ensure that the payment is correctly recorded. Once the payment has been recorded via PayPal IPN, the price to meet the user changes to $0. You can then call the users/{:ID}/meet endpoint to meet the user.
#
# GET /users/{ID}/synergies
# Returns: record<data: table<additional: record, conversation: record, match: record, meet: record, relationship: record>>
export def "get-users-id-synergies" [
  id: list<int>
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
    path: "/users/{ID}/synergies"
    path_params: [{name: ID, var: id, encode: array}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Skip, mute or unmute a user you've been matched with. Skipped matches are only presented as algorithmic matches after all other candidates have been exhausted. You cannot be matched with or meet muted users. You can only skip, mute or unmute users existing within the same bubble.
#
# PATCH /users/{ID}/synergies
# Returns: record<data: record<relationship: record<muted: bool, skipped: bool>>, success: bool>
export def "patch-users-id-synergies" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --relationship-muted: oneof<nothing, bool>
  --relationship-skipped: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{ID}/synergies"
    path_params: [{name: ID, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: relationship_muted, var: relationship_muted}, {name: relationship_skipped, var: relationship_skipped}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, relationship_muted: $relationship_muted, relationship_skipped: $relationship_skipped
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the currently OAuth'ed end-user, based on the access token being used, including private information and settings such as their email address.
#
# GET /users/~
# Returns: record<data: record<business_card: record<company_name: string, company_size: string, headline: string, industry: string, interest_tags: list, job_position: string, summary: string, website: record>, community_persona: record<id: float, identity: record, location: record, personal: record, signature: record, stats: record>, id: float, location: record<city: string, country: float, ip_address: string, latitude: string, longitude: string, region: string>, matching: record<goals: list, interest_tags: list, location_importance: string, targeted_industry: string>, profile: record<first_name: string, introduction: string, last_name: string>, settings: record<email: string, email_verified: bool, notifications: string, timezone: float>, usage: record<available_status: bool, joined_timestamp: string, last_activity_timestamp: string, online_status: bool>>>
export def "get-users-1" [
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
    path: "/users/~"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the OAuth'ed end user's account profile. At this time, for anti-spam reasons, restrictions preclude the ability to update email address and some other settings via the API.
#
# PATCH /users/~
# Returns: record<data: record<business_card: record<company_name: string, company_size: string, headline: string, industry: string, interest_tags: list, job_position: string, summary: string, website: record>, community_persona: record<id: float, identity: record, location: record, personal: record, signature: record, stats: record>, id: float, location: record<city: string, country: float, ip_address: string, latitude: string, longitude: string, region: string>, matching: record<goals: list, interest_tags: list, location_importance: string, targeted_industry: string>, profile: record<first_name: string, introduction: string, last_name: string>, settings: record<email: string, email_verified: bool, notifications: string, timezone: float>, usage: record<available_status: bool, joined_timestamp: string, last_activity_timestamp: string, online_status: bool>>, success: bool>
export def "patch-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company: string
  --company-size: string@company-size-completer
  --first-name: string
  --goals: list<string>@goals-completer
  --headline: string
  --industry: string@industry-completer
  --introduction: string
  --job-position: string@job-position-completer
  --last-name: string
  --location-importance: string@location-importance-completer
  --match-tags: list<string>
  --pitch: string
  --tags: list<string>
  --targeted-industry: string@targeted-industry-completer
  --url: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/~"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: company, var: company}, {name: company_size, var: company_size}, {name: first_name, var: first_name}, {name: "goals[]", var: goals}, {name: headline, var: headline}, {name: industry, var: industry}, {name: introduction, var: introduction}, {name: job_position, var: job_position}, {name: last_name, var: last_name}, {name: location_importance, var: location_importance}, {name: "match_tags[]", var: match_tags}, {name: pitch, var: pitch}, {name: "tags[]", var: tags}, {name: targeted_industry, var: targeted_industry}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company: $company, company_size: $company_size, first_name: $first_name, goals: $goals, headline: $headline, industry: $industry, introduction: $introduction, job_position: $job_position, last_name: $last_name, location_importance: $location_importance, match_tags: $match_tags, pitch: $pitch, tags: $tags, targeted_industry: $targeted_industry, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a listing of all webhooks owned by the current user/bubble combination.
#
# GET /webhooks
# Returns: record<data: table<app: record, event: record, id: float, name: string, object: record, uri: string, user: record>>
export def "get-webhooks" [
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
    path: "/webhooks"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a new webhook for the current user/bubble combination. Specify an object_id to only be notified on an event related to that specific Conversation ID, Group ID, or User ID. Your access token must have access to the user being tracked, user you are in the conversation with, or user who created the group. You must be connected with a user in order to keep track of their online status. Alternatively, do not specify an object_id to be notified on all events that are related to conversations you're in, groups you're a member of, or users you are in conversations with. You may only have one webhook for each object_id/event. The webhook URI must reside on your own server. Webhooks do not expire when the access token used to create them expires. However, they will temporarily cease to function if the user who created them deauthorizes access to the application (effectively no longer existing within the bubble), unless/until the user reauthorizes the application using OAuth.
#
# POST /webhooks
# Returns: record<data: record<app: record<about: record, id: float, legal: record>, event: record<action: string>, id: float, name: string, object: record<id: float, type: string>, uri: string, user: record<business_card: record, community_persona: record, id: float, profile: record, usage: record>>, success: bool>
export def "post-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bubbled: oneof<nothing, bool> # default: false
  event: string@event-completer
  name: string
  --object-id: int # format: int32
  uri: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: bubbled, var: bubbled}, {name: event, var: event}, {name: name, var: name}, {name: object_id, var: object_id}, {name: uri, var: uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bubbled: $bubbled, event: $event, name: $name, object_id: $object_id, uri: $uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a webhook that was previously registered by the current user/bubble combination.
#
# DELETE /webhooks/{ID}
# Returns: record<success: bool>
export def "delete-webhooks-id" [
  id: int
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
    path: "/webhooks/{ID}"
    path_params: [{name: ID, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
