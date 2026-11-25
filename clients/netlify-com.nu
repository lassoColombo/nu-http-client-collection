# Auto-generated client for Netlify's API documentation v2.15.0
# Source: https://api.apis.guru/v2/specs/netlify.com/2.15.0/swagger.json
# Auth: --token flag or $env.NETLIFY_S_API_DOCUMENTATION_TOKEN

const CLIENT = {
  base_url: "https://api.netlify.com/api/v1"
  token_env_var: "NETLIFY_S_API_DOCUMENTATION_TOKEN"
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

def base-url-completer [] { ["https://api.netlify.com/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def period-completer [] { ["monthly" "yearly"] }
def context-name-completer [] { ["all" "branch-deploy" "deploy-preview" "dev" "production"] }
def scope-completer [] { ["builds" "functions" "post-processing" "runtime"] }
def context-completer [] { ["branch-deploy" "deploy-preview" "dev" "production"] }
def section-completer [] { ["building" "cleanup" "deploying" "initializing" "postprocessing"] }
def filter-completer [] { ["all" "guest" "owner"] }
def state-completer [] { ["accepted" "building" "enqueued" "error" "new" "pending_review" "prepared" "preparing" "processing" "ready" "rejected" "retrying" "uploaded" "uploading"] }
def role-completer [] { ["Collaborator" "Controller" "Owner"] }
def site-access-completer [] { ["all" "none" "selected"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-accounts-for-user: "table<billing_details: string, billing_email: string, billing_name: string, billing_period: string, capabilities: record<collaborators: record, sites: record>, created_at: string, id: string, name: string, owner_ids: list<string>, payment_method_id: string, roles_allowed: list<string>, slug: string, type: string, type_id: string, type_name: string, updated_at: string>"
    create-account: "record<billing_details: string, billing_email: string, billing_name: string, billing_period: string, capabilities: record<collaborators: record<included: int, used: int>, sites: record<included: int, used: int>>, created_at: string, id: string, name: string, owner_ids: list<string>, payment_method_id: string, roles_allowed: list<string>, slug: string, type: string, type_id: string, type_name: string, updated_at: string>"
    list-account-types-for-user: "table<capabilities: record, description: string, id: string, monthly_dollar_price: int, monthly_seats_addon_dollar_price: int, name: string, yearly_dollar_price: int, yearly_seats_addon_dollar_price: int>"
    get-account: "table<billing_details: string, billing_email: string, billing_name: string, billing_period: string, capabilities: record<collaborators: record, sites: record>, created_at: string, id: string, name: string, owner_ids: list<string>, payment_method_id: string, roles_allowed: list<string>, slug: string, type: string, type_id: string, type_name: string, updated_at: string>"
    update-account: "record<billing_details: string, billing_email: string, billing_name: string, billing_period: string, capabilities: record<collaborators: record<included: int, used: int>, sites: record<included: int, used: int>>, created_at: string, id: string, name: string, owner_ids: list<string>, payment_method_id: string, roles_allowed: list<string>, slug: string, type: string, type_id: string, type_name: string, updated_at: string>"
    list-account-audit-events: "table<account_id: string, id: string, payload: record<action: string, actor_email: string, actor_id: string, actor_name: string, log_type: string, timestamp: string>>"
    get-env-vars: "table<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: list<record>>"
    create-env-vars: "table<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: list<record>>"
    get-env-var: "record<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: table<context: string, id: string, value: string>>"
    set-env-var-value: "record<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: table<context: string, id: string, value: string>>"
    update-env-var: "record<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: table<context: string, id: string, value: string>>"
    list-payment-methods-for-user: "table<created_at: string, data: record<card_type: string, email: string, last4: string>, id: string, method_name: string, state: string, type: string, updated_at: string>"
    get-site-build: "record<created_at: string, deploy_id: string, done: bool, error: string, id: string, sha: string>"
    list-deploy-keys: "table<created_at: string, id: string, public_key: string>"
    create-deploy-key: "record<created_at: string, id: string, public_key: string>"
    get-deploy-key: "record<created_at: string, id: string, public_key: string>"
    get-deploy: "record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>"
    cancel-site-deploy: "record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>"
    upload-deploy-file: "record<id: string, mime_type: string, path: string, sha: string, size: int>"
    upload-deploy-function: "record<id: string, name: string, sha: string>"
    lock-deploy: "record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>"
    create-plugin-run: "record<package: string, reporting_event: string, state: string, summary: string, text: string, title: string, version: string, deploy_id: string>"
    unlock-deploy: "record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>"
    get-dns-zones: "table<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: list<record>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string>"
    create-dns-zone: "record<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string>"
    get-dns-zone: "record<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string>"
    get-dns-records: "table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>"
    create-dns-record: "record<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>"
    get-individual-dns-record: "record<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>"
    transfer-dns-zone: "record<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string>"
    list-form-submissions: "table<body: string, company: string, created_at: string, data: record, email: string, first_name: string, id: string, last_name: string, name: string, number: int, site_url: string, summary: string>"
    list-hooks-by-site-id: "table<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string>"
    create-hook-by-site-id: "record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string>"
    list-hook-types: "table<events: list<string>, fields: list<record>, name: string>"
    get-hook: "record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string>"
    update-hook: "record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string>"
    enable-hook: "record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string>"
    create-ticket: "record<authorized: bool, client_id: string, created_at: string, id: string>"
    show-ticket: "record<authorized: bool, client_id: string, created_at: string, id: string>"
    exchange-ticket: "record<access_token: string, created_at: string, id: string, user_email: string, user_id: string>"
    get-services: "table<created_at: string, description: string, environments: list<string>, events: list<record>, icon: string, id: string, long_description: string, manifest_url: string, name: string, service_path: string, slug: string, tags: list<string>, updated_at: string>"
    show-service: "record<created_at: string, description: string, environments: list<string>, events: list<record>, icon: string, id: string, long_description: string, manifest_url: string, name: string, service_path: string, slug: string, tags: list<string>, updated_at: string>"
    show-service-manifest: "record"
    list-sites: "table<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record, html: record, images: record, js: record, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list, id: string, locked: bool, name: string, published_at: string, required: list, required_functions: list, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>"
    create-site: "record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>"
    get-site: "record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>"
    update-site: "record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>"
    list-site-assets: "table<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string>"
    create-site-asset: "record<asset: record<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string>, form: record<fields: record, url: string>>"
    get-site-asset-info: "record<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string>"
    update-site-asset: "record<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string>"
    get-site-asset-public-signature: "record<url: string>"
    list-site-build-hooks: "table<branch: string, created_at: string, id: string, site_id: string, title: string, url: string>"
    create-site-build-hook: "record<branch: string, created_at: string, id: string, site_id: string, title: string, url: string>"
    get-site-build-hook: "record<branch: string, created_at: string, id: string, site_id: string, title: string, url: string>"
    list-site-builds: "table<created_at: string, deploy_id: string, done: bool, error: string, id: string, sha: string>"
    create-site-build: "record<created_at: string, deploy_id: string, done: bool, error: string, id: string, sha: string>"
    list-site-deployed-branches: "table<deploy_id: string, id: string, name: string, slug: string, ssl_url: string, url: string>"
    list-site-deploys: "table<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>"
    create-site-deploy: "record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>"
    get-site-deploy: "record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>"
    update-site-deploy: "record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>"
    restore-site-deploy: "record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>"
    get-dns-for-site: "table<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: list<record>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string>"
    configure-dns-for-site: "table<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: list<record>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string>"
    list-site-files: "table<id: string, mime_type: string, path: string, sha: string, size: int>"
    get-site-file-by-path-name: "record<id: string, mime_type: string, path: string, sha: string, size: int>"
    list-site-forms: "table<created_at: string, fields: list<record>, id: string, name: string, paths: list<string>, site_id: string, submission_count: int>"
    get-site-metadata: "record"
    get-latest-plugin-runs: "table<package: string, reporting_event: string, state: string, summary: string, text: string, title: string, version: string, deploy_id: string>"
    update-plugin: "record<package: string, pinned_version: string>"
    list-service-instances-for-site: "table<auth_url: string, config: record, created_at: string, env: record, external_attributes: record, id: string, service_name: string, service_path: string, service_slug: string, snippets: list<record>, updated_at: string, url: string>"
    create-service-instance: "record<auth_url: string, config: record, created_at: string, env: record, external_attributes: record, id: string, service_name: string, service_path: string, service_slug: string, snippets: list<record>, updated_at: string, url: string>"
    show-service-instance: "record<auth_url: string, config: record, created_at: string, env: record, external_attributes: record, id: string, service_name: string, service_path: string, service_slug: string, snippets: list<record>, updated_at: string, url: string>"
    list-site-snippets: "table<general: string, general_position: string, goal: string, goal_position: string, id: int, site_id: string, title: string>"
    create-site-snippet: "record<general: string, general_position: string, goal: string, goal_position: string, id: int, site_id: string, title: string>"
    get-site-snippet: "record<general: string, general_position: string, goal: string, goal_position: string, id: int, site_id: string, title: string>"
    show-site-tls-certificate: "record<created_at: string, domains: list<string>, expires_at: string, state: string, updated_at: string>"
    provision-site-tls-certificate: "record<created_at: string, domains: list<string>, expires_at: string, state: string, updated_at: string>"
    list-site-submissions: "table<body: string, company: string, created_at: string, data: record, email: string, first_name: string, id: string, last_name: string, name: string, number: int, site_url: string, summary: string>"
    get-split-tests: "table<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string>"
    create-split-test: "record<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string>"
    get-split-test: "record<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string>"
    update-split-test: "record<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string>"
    unlink-site-repo: "record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>"
    list-form-submission: "table<body: string, company: string, created_at: string, data: record, email: string, first_name: string, id: string, last_name: string, name: string, number: int, site_url: string, summary: string>"
    get-current-user: "table<affiliate_id: string, avatar_url: string, created_at: string, email: string, full_name: string, id: string, last_login: string, login_providers: list<string>, onboarding_progress: record<slides: string>, site_count: int, uid: string>"
    get-account-build-status: "table<active: int, build_count: int, enqueued: int, minutes: record<current: int, current_average_sec: int, included_minutes: string, included_minutes_with_packs: string, last_updated_at: string, period_end_date: string, period_start_date: string, previous: int>, pending_concurrency: int>"
    list-members-for-account: "table<avatar: string, email: string, full_name: string, id: string, role: string>"
    add-member-to-account: "table<avatar: string, email: string, full_name: string, id: string, role: string>"
    get-account-member: "record<avatar: string, email: string, full_name: string, id: string, role: string>"
    update-account-member: "record<avatar: string, email: string, full_name: string, id: string, role: string>"
    list-sites-for-account: "table<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record, html: record, images: record, js: record, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list, id: string, locked: bool, name: string, published_at: string, required: list, required_functions: list, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>"
    create-site-in-team: "record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-accounts-for-user" "create-account" "list-account-types-for-user" "cancel-account" "get-account" "update-account" "list-account-audit-events" "get-env-vars" "create-env-vars" "delete-env-var" "get-env-var" "set-env-var-value" "update-env-var" "delete-env-var-value" "list-payment-methods-for-user" "get-site-build" "update-site-build-log" "notify-build-start" "list-deploy-keys" "create-deploy-key" "delete-deploy-key" "get-deploy-key" "delete-deploy" "get-deploy" "cancel-site-deploy" "upload-deploy-file" "upload-deploy-function" "lock-deploy" "create-plugin-run" "unlock-deploy" "get-dns-zones" "create-dns-zone" "delete-dns-zone" "get-dns-zone" "get-dns-records" "create-dns-record" "delete-dns-record" "get-individual-dns-record" "transfer-dns-zone" "list-form-submissions" "list-hooks-by-site-id" "create-hook-by-site-id" "list-hook-types" "delete-hook" "get-hook" "update-hook" "enable-hook" "create-ticket" "show-ticket" "exchange-ticket" "get-services" "show-service" "show-service-manifest" "list-sites" "create-site" "delete-site" "get-site" "update-site" "list-site-assets" "create-site-asset" "delete-site-asset" "get-site-asset-info" "update-site-asset" "get-site-asset-public-signature" "list-site-build-hooks" "create-site-build-hook" "delete-site-build-hook" "get-site-build-hook" "update-site-build-hook" "list-site-builds" "create-site-build" "list-site-deployed-branches" "list-site-deploys" "create-site-deploy" "delete-site-deploy" "get-site-deploy" "update-site-deploy" "restore-site-deploy" "get-dns-for-site" "configure-dns-for-site" "list-site-files" "get-site-file-by-path-name" "list-site-forms" "delete-site-form" "get-site-metadata" "update-site-metadata" "get-latest-plugin-runs" "update-plugin" "rollback-site-deploy" "list-service-instances-for-site" "create-service-instance" "delete-service-instance" "show-service-instance" "update-service-instance" "list-site-snippets" "create-site-snippet" "delete-site-snippet" "get-site-snippet" "update-site-snippet" "show-site-tls-certificate" "provision-site-tls-certificate" "list-site-submissions" "get-split-tests" "create-split-test" "get-split-test" "update-split-test" "enable-split-test" "disable-split-test" "unlink-site-repo" "delete-submission" "list-form-submission" "get-current-user" "get-account-build-status" "list-members-for-account" "add-member-to-account" "remove-account-member" "get-account-member" "update-account-member" "list-sites-for-account" "create-site-in-team" "commands"] | sort) } | get name | first)
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

# GET /accounts
#
# Returns: table<billing_details: string, billing_email: string, billing_name: string, billing_period: string, capabilities: record<collaborators: record, sites: record>, created_at: string, id: string, name: string, owner_ids: list<string>, payment_method_id: string, roles_allowed: list<string>, slug: string, type: string, type_id: string, type_name: string, updated_at: string>
# operationId: listAccountsForUser
export def "list-accounts-for-user" [
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
    path: "/accounts"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /accounts
#
# Returns: record<billing_details: string, billing_email: string, billing_name: string, billing_period: string, capabilities: record<collaborators: record<included: int, used: int>, sites: record<included: int, used: int>>, created_at: string, id: string, name: string, owner_ids: list<string>, payment_method_id: string, roles_allowed: list<string>, slug: string, type: string, type_id: string, type_name: string, updated_at: string>
# operationId: createAccount
export def "create-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extra-seats-block: int
  name: string
  --payment-method-id: string
  --period: string@period-completer
  type_id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts"
    body: {content_type: "application/json", kind: json, fields: [{name: extra_seats_block, var: extra_seats_block}, {name: name, var: name}, {name: payment_method_id, var: payment_method_id}, {name: period, var: period}, {name: type_id, var: type_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    extra_seats_block: $extra_seats_block, name: $name, payment_method_id: $payment_method_id, period: $period, type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /accounts/types
#
# Returns: table<capabilities: record, description: string, id: string, monthly_dollar_price: int, monthly_seats_addon_dollar_price: int, name: string, yearly_dollar_price: int, yearly_seats_addon_dollar_price: int>
# operationId: listAccountTypesForUser
export def "list-account-types-for-user" [
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
    path: "/accounts/types"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /accounts/{account_id}
#
# operationId: cancelAccount
export def "cancel-account" [
  account_id: string
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
    method: delete
    path: "/accounts/{account_id}"
    path_params: [{name: account_id, var: account_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /accounts/{account_id}
#
# Returns: table<billing_details: string, billing_email: string, billing_name: string, billing_period: string, capabilities: record<collaborators: record, sites: record>, created_at: string, id: string, name: string, owner_ids: list<string>, payment_method_id: string, roles_allowed: list<string>, slug: string, type: string, type_id: string, type_name: string, updated_at: string>
# operationId: getAccount
export def "get-account" [
  account_id: string
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
    path: "/accounts/{account_id}"
    path_params: [{name: account_id, var: account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /accounts/{account_id}
#
# Returns: record<billing_details: string, billing_email: string, billing_name: string, billing_period: string, capabilities: record<collaborators: record<included: int, used: int>, sites: record<included: int, used: int>>, created_at: string, id: string, name: string, owner_ids: list<string>, payment_method_id: string, roles_allowed: list<string>, slug: string, type: string, type_id: string, type_name: string, updated_at: string>
# operationId: updateAccount
export def "update-account" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-details: string
  --billing-email: string
  --billing-name: string
  --extra-seats-block: int
  --name: string
  --slug: string
  --type-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{account_id}"
    path_params: [{name: account_id, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: billing_details, var: billing_details}, {name: billing_email, var: billing_email}, {name: billing_name, var: billing_name}, {name: extra_seats_block, var: extra_seats_block}, {name: name, var: name}, {name: slug, var: slug}, {name: type_id, var: type_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, billing_details: $billing_details, billing_email: $billing_email, billing_name: $billing_name, extra_seats_block: $extra_seats_block, name: $name, slug: $slug, type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /accounts/{account_id}/audit
#
# Returns: table<account_id: string, id: string, payload: record<action: string, actor_email: string, actor_id: string, actor_name: string, log_type: string, timestamp: string>>
# operationId: listAccountAuditEvents
export def "list-account-audit-events" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string
  --log-type: string
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{account_id}/audit"
    path_params: [{name: account_id, var: account_id}]
    query: [{name: query, var: query}, {name: log_type, var: log_type}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, query: $query, log_type: $log_type, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all environment variables for an account or site. An account corresponds to a team in the Netlify UI. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# GET /accounts/{account_id}/env
# Returns: table<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: list<record>>
# operationId: getEnvVars
export def "get-env-vars" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --context-name: string@context-name-completer # Filter by deploy context
  --scope: string@scope-completer # Filter by scope
  --site-id: string # If specified, only return environment variables set on this site
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{account_id}/env"
    path_params: [{name: account_id, var: account_id}]
    query: [{name: context_name, var: context_name}, {name: scope, var: scope}, {name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, context_name: $context_name, scope: $scope, site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates new environment variables. Granular scopes are available on Pro plans and above. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# POST /accounts/{account_id}/env
# Returns: table<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: list<record>>
# operationId: createEnvVars
export def "create-env-vars" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, create an environment variable on the site level, not the account level
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{account_id}/env"
    path_params: [{name: account_id, var: account_id}]
    query: [{name: site_id, var: site_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, site_id: $site_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an environment variable. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# DELETE /accounts/{account_id}/env/{key}
# operationId: deleteEnvVar
export def "delete-env-var" [
  account_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, delete the environment variable from this site
]: nothing -> any {
  http-request {
    method: delete
    path: "/accounts/{account_id}/env/{key}"
    path_params: [{name: account_id, var: account_id}, {name: key, var: key}]
    query: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, key: $key, site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an individual environment variable. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# GET /accounts/{account_id}/env/{key}
# Returns: record<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: table<context: string, id: string, value: string>>
# operationId: getEnvVar
export def "get-env-var" [
  account_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, return the environment variable for a specific site (no merging is performed)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{account_id}/env/{key}"
    path_params: [{name: account_id, var: account_id}, {name: key, var: key}]
    query: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, key: $key, site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates or creates a new value for an existing environment variable. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# PATCH /accounts/{account_id}/env/{key}
# Returns: record<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: table<context: string, id: string, value: string>>
# operationId: setEnvVarValue
export def "set-env-var-value" [
  account_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, update an environment variable set on this site
  --context: string@context-completer # The deploy context in which this value will be used. `dev` refers to local development when running `netlify dev`.
  --value: string # The environment variable's unencrypted value
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/accounts/{account_id}/env/{key}"
    path_params: [{name: account_id, var: account_id}, {name: key, var: key}]
    query: [{name: site_id, var: site_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: context, var: context}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, key: $key, site_id: $site_id, context: $context, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing environment variable and all of its values. Existing values will be replaced by values provided. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# PUT /accounts/{account_id}/env/{key}
# Returns: record<key: string, scopes: list<string>, updated_at: string, updated_by: record<avatar_url: string, email: string, full_name: string, id: string>, values: table<context: string, id: string, value: string>>
# operationId: updateEnvVar
export def "update-env-var" [
  account_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # If provided, update an environment variable set on this site
  --body-key: string # The existing or new name of the key, if you wish to rename it (case-sensitive) (spec name: key)
  --scopes: list<string> # The scopes that this environment variable is set to (Pro plans and above)
  --values: list # item shape: {context?: "all"|"dev"|"branch-deploy"|"deploy-preview"|"production", id?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{account_id}/env/{key}"
    path_params: [{name: account_id, var: account_id}, {name: key, var: key}]
    query: [{name: site_id, var: site_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: body_key}, {name: scopes, var: scopes}, {name: values, var: values}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, key: $key, site_id: $site_id, body_key: $body_key, scopes: $scopes, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specific environment variable value. To use this endpoint, your site must no longer be using the classic environment variables experience (https://docs.netlify.com/environment-variables/classic-experience/). Migrate now with the Netlify UI.
#
# DELETE /accounts/{account_id}/env/{key}/value/{id}
# operationId: deleteEnvVarValue
export def "delete-env-var-value" [
  account_id: string
  key: string
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
  --site-id: string # If provided, delete the value from an environment variable on this site
]: nothing -> any {
  http-request {
    method: delete
    path: "/accounts/{account_id}/env/{key}/value/{id}"
    path_params: [{name: account_id, var: account_id}, {name: key, var: key}, {name: id, var: id}]
    query: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, key: $key, id: $id, site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /billing/payment_methods
#
# Returns: table<created_at: string, data: record<card_type: string, email: string, last4: string>, id: string, method_name: string, state: string, type: string, updated_at: string>
# operationId: listPaymentMethodsForUser
export def "list-payment-methods-for-user" [
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
    path: "/billing/payment_methods"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /builds/{build_id}
#
# Returns: record<created_at: string, deploy_id: string, done: bool, error: string, id: string, sha: string>
# operationId: getSiteBuild
export def "get-site-build" [
  build_id: string
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
    path: "/builds/{build_id}"
    path_params: [{name: build_id, var: build_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    build_id: $build_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /builds/{build_id}/log
#
# operationId: updateSiteBuildLog
export def "update-site-build-log" [
  build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --error: oneof<nothing, bool>
  --message: string
  --section: string@section-completer
]: any -> any {
  $in | http-request {
    method: post
    path: "/builds/{build_id}/log"
    path_params: [{name: build_id, var: build_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: error, var: error}, {name: message, var: message}, {name: section, var: section}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    build_id: $build_id, error: $error, message: $message, section: $section
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /builds/{build_id}/start
#
# operationId: notifyBuildStart
export def "notify-build-start" [
  build_id: string
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
    method: post
    path: "/builds/{build_id}/start"
    path_params: [{name: build_id, var: build_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    build_id: $build_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /deploy_keys
#
# Returns: table<created_at: string, id: string, public_key: string>
# operationId: listDeployKeys
export def "list-deploy-keys" [
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
    path: "/deploy_keys"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /deploy_keys
#
# Returns: record<created_at: string, id: string, public_key: string>
# operationId: createDeployKey
export def "create-deploy-key" [
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
    path: "/deploy_keys"
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /deploy_keys/{key_id}
#
# operationId: deleteDeployKey
export def "delete-deploy-key" [
  key_id: string
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
    method: delete
    path: "/deploy_keys/{key_id}"
    path_params: [{name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /deploy_keys/{key_id}
#
# Returns: record<created_at: string, id: string, public_key: string>
# operationId: getDeployKey
export def "get-deploy-key" [
  key_id: string
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
    path: "/deploy_keys/{key_id}"
    path_params: [{name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /deploys/{deploy_id}
#
# operationId: deleteDeploy
export def "delete-deploy" [
  deploy_id: string
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
    method: delete
    path: "/deploys/{deploy_id}"
    path_params: [{name: deploy_id, var: deploy_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    deploy_id: $deploy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /deploys/{deploy_id}
#
# Returns: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>
# operationId: getDeploy
export def "get-deploy" [
  deploy_id: string
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
    path: "/deploys/{deploy_id}"
    path_params: [{name: deploy_id, var: deploy_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deploy_id: $deploy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /deploys/{deploy_id}/cancel
#
# Returns: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>
# operationId: cancelSiteDeploy
export def "cancel-site-deploy" [
  deploy_id: string
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
    path: "/deploys/{deploy_id}/cancel"
    path_params: [{name: deploy_id, var: deploy_id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    deploy_id: $deploy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /deploys/{deploy_id}/files/{path}
#
# Returns: record<id: string, mime_type: string, path: string, sha: string, size: int>
# operationId: uploadDeployFile
export def "upload-deploy-file" [
  deploy_id: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --size: int
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/deploys/{deploy_id}/files/{path}"
    path_params: [{name: deploy_id, var: deploy_id}, {name: path, var: path}]
    query: [{name: size, var: size}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deploy_id: $deploy_id, path: $path, size: $size, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /deploys/{deploy_id}/functions/{name}
#
# Returns: record<id: string, name: string, sha: string>
# operationId: uploadDeployFunction
export def "upload-deploy-function" [
  deploy_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --runtime: string
  --size: int
  --x-nf-retry-count: int
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/deploys/{deploy_id}/functions/{name}"
    path_params: [{name: deploy_id, var: deploy_id}, {name: name, var: name}]
    query: [{name: runtime, var: runtime}, {name: size, var: size}]
    header: [{name: X-Nf-Retry-Count, var: x_nf_retry_count}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deploy_id: $deploy_id, name: $name, runtime: $runtime, size: $size, x_nf_retry_count: $x_nf_retry_count, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /deploys/{deploy_id}/lock
#
# Returns: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>
# operationId: lockDeploy
export def "lock-deploy" [
  deploy_id: string
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
    path: "/deploys/{deploy_id}/lock"
    path_params: [{name: deploy_id, var: deploy_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deploy_id: $deploy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is an internal-only endpoint.
#
# POST /deploys/{deploy_id}/plugin_runs
# Returns: record<package: string, reporting_event: string, state: string, summary: string, text: string, title: string, version: string, deploy_id: string>
# operationId: createPluginRun
export def "create-plugin-run" [
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --package: string
  --reporting-event: string
  --state: string
  --summary: string
  --text: string
  --title: string
  --version: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deploys/{deploy_id}/plugin_runs"
    path_params: [{name: deploy_id, var: deploy_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: package, var: package}, {name: reporting_event, var: reporting_event}, {name: state, var: state}, {name: summary, var: summary}, {name: text, var: text}, {name: title, var: title}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    deploy_id: $deploy_id, package: $package, reporting_event: $reporting_event, state: $state, summary: $summary, text: $text, title: $title, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /deploys/{deploy_id}/unlock
#
# Returns: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>
# operationId: unlockDeploy
export def "unlock-deploy" [
  deploy_id: string
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
    path: "/deploys/{deploy_id}/unlock"
    path_params: [{name: deploy_id, var: deploy_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deploy_id: $deploy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /dns_zones
#
# Returns: table<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: list<record>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string>
# operationId: getDnsZones
export def "get-dns-zones" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-slug: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/dns_zones"
    query: [{name: account_slug, var: account_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_slug: $account_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /dns_zones
#
# Returns: record<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string>
# operationId: createDnsZone
export def "create-dns-zone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-slug: string
  --name: string
  --site-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dns_zones"
    body: {content_type: "application/json", kind: json, fields: [{name: account_slug, var: account_slug}, {name: name, var: name}, {name: site_id, var: site_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account_slug: $account_slug, name: $name, site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /dns_zones/{zone_id}
#
# operationId: deleteDnsZone
export def "delete-dns-zone" [
  zone_id: string
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
    method: delete
    path: "/dns_zones/{zone_id}"
    path_params: [{name: zone_id, var: zone_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    zone_id: $zone_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /dns_zones/{zone_id}
#
# Returns: record<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string>
# operationId: getDnsZone
export def "get-dns-zone" [
  zone_id: string
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
    path: "/dns_zones/{zone_id}"
    path_params: [{name: zone_id, var: zone_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    zone_id: $zone_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /dns_zones/{zone_id}/dns_records
#
# Returns: table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>
# operationId: getDnsRecords
export def "get-dns-records" [
  zone_id: string
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
    path: "/dns_zones/{zone_id}/dns_records"
    path_params: [{name: zone_id, var: zone_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    zone_id: $zone_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /dns_zones/{zone_id}/dns_records
#
# Returns: record<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>
# operationId: createDnsRecord
export def "create-dns-record" [
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --flag: int # format: int64
  --hostname: string
  --port: int # format: int64
  --priority: int # format: int64
  --tag: string
  --ttl: int # format: int64
  --type: string
  --value: string
  --weight: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dns_zones/{zone_id}/dns_records"
    path_params: [{name: zone_id, var: zone_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: flag, var: flag}, {name: hostname, var: hostname}, {name: port, var: port}, {name: priority, var: priority}, {name: tag, var: tag}, {name: ttl, var: ttl}, {name: type, var: type}, {name: value, var: value}, {name: weight, var: weight}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    zone_id: $zone_id, flag: $flag, hostname: $hostname, port: $port, priority: $priority, tag: $tag, ttl: $ttl, type: $type, value: $value, weight: $weight
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /dns_zones/{zone_id}/dns_records/{dns_record_id}
#
# operationId: deleteDnsRecord
export def "delete-dns-record" [
  zone_id: string
  dns_record_id: string
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
    method: delete
    path: "/dns_zones/{zone_id}/dns_records/{dns_record_id}"
    path_params: [{name: zone_id, var: zone_id}, {name: dns_record_id, var: dns_record_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    zone_id: $zone_id, dns_record_id: $dns_record_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /dns_zones/{zone_id}/dns_records/{dns_record_id}
#
# Returns: record<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>
# operationId: getIndividualDnsRecord
export def "get-individual-dns-record" [
  zone_id: string
  dns_record_id: string
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
    path: "/dns_zones/{zone_id}/dns_records/{dns_record_id}"
    path_params: [{name: zone_id, var: zone_id}, {name: dns_record_id, var: dns_record_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    zone_id: $zone_id, dns_record_id: $dns_record_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /dns_zones/{zone_id}/transfer
#
# Returns: record<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: table<dns_zone_id: string, flag: int, hostname: string, id: string, managed: bool, priority: int, site_id: string, tag: string, ttl: int, type: string, value: string>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string>
# operationId: transferDnsZone
export def "transfer-dns-zone" [
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # the account of the dns zone (required)
  --transfer-account-id: string # the account you want to transfer the dns zone to (required)
  --transfer-user-id: string # the user you want to transfer the dns zone to (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/dns_zones/{zone_id}/transfer"
    path_params: [{name: zone_id, var: zone_id}]
    query: [{name: account_id, var: account_id, required: true}, {name: transfer_account_id, var: transfer_account_id, required: true}, {name: transfer_user_id, var: transfer_user_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    zone_id: $zone_id, account_id: $account_id, transfer_account_id: $transfer_account_id, transfer_user_id: $transfer_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /forms/{form_id}/submissions
#
# Returns: table<body: string, company: string, created_at: string, data: record, email: string, first_name: string, id: string, last_name: string, name: string, number: int, site_url: string, summary: string>
# operationId: listFormSubmissions
export def "list-form-submissions" [
  form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/forms/{form_id}/submissions"
    path_params: [{name: form_id, var: form_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    form_id: $form_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /hooks
#
# Returns: table<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string>
# operationId: listHooksBySiteId
export def "list-hooks-by-site-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # required
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/hooks"
    query: [{name: site_id, var: site_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /hooks
#
# Returns: record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string>
# operationId: createHookBySiteId
export def "create-hook-by-site-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string # required
  --created-at: string # format: dateTime
  --data: record
  --disabled: oneof<nothing, bool>
  --event: string
  --id: string
  --body-site-id: string # (spec name: site_id)
  --type: string
  --updated-at: string # format: dateTime
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/hooks"
    query: [{name: site_id, var: site_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: created_at, var: created_at}, {name: data, var: data}, {name: disabled, var: disabled}, {name: event, var: event}, {name: id, var: id}, {name: site_id, var: body_site_id}, {name: type, var: type}, {name: updated_at, var: updated_at}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    site_id: $site_id, created_at: $created_at, data: $data, disabled: $disabled, event: $event, id: $id, body_site_id: $body_site_id, type: $type, updated_at: $updated_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /hooks/types
#
# Returns: table<events: list<string>, fields: list<record>, name: string>
# operationId: listHookTypes
export def "list-hook-types" [
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
    path: "/hooks/types"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /hooks/{hook_id}
#
# operationId: deleteHook
export def "delete-hook" [
  hook_id: string
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
    method: delete
    path: "/hooks/{hook_id}"
    path_params: [{name: hook_id, var: hook_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    hook_id: $hook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /hooks/{hook_id}
#
# Returns: record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string>
# operationId: getHook
export def "get-hook" [
  hook_id: string
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
    path: "/hooks/{hook_id}"
    path_params: [{name: hook_id, var: hook_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hook_id: $hook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /hooks/{hook_id}
#
# Returns: record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string>
# operationId: updateHook
export def "update-hook" [
  hook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: string # format: dateTime
  --data: record
  --disabled: oneof<nothing, bool>
  --event: string
  --id: string
  --site-id: string
  --type: string
  --updated-at: string # format: dateTime
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/hooks/{hook_id}"
    path_params: [{name: hook_id, var: hook_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: created_at, var: created_at}, {name: data, var: data}, {name: disabled, var: disabled}, {name: event, var: event}, {name: id, var: id}, {name: site_id, var: site_id}, {name: type, var: type}, {name: updated_at, var: updated_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hook_id: $hook_id, created_at: $created_at, data: $data, disabled: $disabled, event: $event, id: $id, site_id: $site_id, type: $type, updated_at: $updated_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /hooks/{hook_id}/enable
#
# Returns: record<created_at: string, data: record, disabled: bool, event: string, id: string, site_id: string, type: string, updated_at: string>
# operationId: enableHook
export def "enable-hook" [
  hook_id: string
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
    path: "/hooks/{hook_id}/enable"
    path_params: [{name: hook_id, var: hook_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hook_id: $hook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /oauth/tickets
#
# Returns: record<authorized: bool, client_id: string, created_at: string, id: string>
# operationId: createTicket
export def "create-ticket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/oauth/tickets"
    query: [{name: client_id, var: client_id, required: true}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /oauth/tickets/{ticket_id}
#
# Returns: record<authorized: bool, client_id: string, created_at: string, id: string>
# operationId: showTicket
export def "show-ticket" [
  ticket_id: string
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
    path: "/oauth/tickets/{ticket_id}"
    path_params: [{name: ticket_id, var: ticket_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ticket_id: $ticket_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /oauth/tickets/{ticket_id}/exchange
#
# Returns: record<access_token: string, created_at: string, id: string, user_email: string, user_id: string>
# operationId: exchangeTicket
export def "exchange-ticket" [
  ticket_id: string
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
    path: "/oauth/tickets/{ticket_id}/exchange"
    path_params: [{name: ticket_id, var: ticket_id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    ticket_id: $ticket_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /services/
#
# Returns: table<created_at: string, description: string, environments: list<string>, events: list<record>, icon: string, id: string, long_description: string, manifest_url: string, name: string, service_path: string, slug: string, tags: list<string>, updated_at: string>
# operationId: getServices
export def "get-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/services/"
    query: [{name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /services/{addonName}
#
# Returns: record<created_at: string, description: string, environments: list<string>, events: list<record>, icon: string, id: string, long_description: string, manifest_url: string, name: string, service_path: string, slug: string, tags: list<string>, updated_at: string>
# operationId: showService
export def "show-service" [
  addon_name: string
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
    path: "/services/{addonName}"
    path_params: [{name: addonName, var: addon_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    addon_name: $addon_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /services/{addonName}/manifest
#
# Returns: record
# operationId: showServiceManifest
export def "show-service-manifest" [
  addon_name: string
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
    path: "/services/{addonName}/manifest"
    path_params: [{name: addonName, var: addon_name}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    addon_name: $addon_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [getEnvVars](#tag/environmentVariables/operation/getEnvVars) to retrieve site environment variables.
#
# GET /sites
# Returns: table<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record, html: record, images: record, js: record, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list, id: string, locked: bool, name: string, published_at: string, required: list, required_functions: list, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>
# operationId: listSites
export def "list-sites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --filter: string@filter-completer
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/sites"
    query: [{name: name, var: name}, {name: filter, var: filter}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, filter: $filter, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [createEnvVars](#tag/environmentVariables/operation/createEnvVars) to create environment variables for a site.
#
# POST /sites
# Returns: record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>
# operationId: createSite
export def "create-site" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --configure-dns: oneof<nothing, bool>
  --account-name: string
  --account-slug: string
  --admin-url: string
  --build-image: string
  --build-settings: record # shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
  --capabilities: record
  --created-at: string # format: dateTime
  --custom-domain: string
  --default-hooks-data: record # shape: {access_token?: string}
  --deploy-hook: string
  --deploy-url: string
  --domain-aliases: list<string>
  --force-ssl: oneof<nothing, bool>
  --git-provider: string
  --id: string
  --id-domain: string
  --managed-dns: oneof<nothing, bool>
  --name: string
  --notification-email: string
  --password: string
  --plan: string
  --prerender: string
  --processing-settings: record # shape: {css?: record, html?: record, images?: record, js?: record, skip?: bool}
  --published-deploy: record # shape: {admin_url?: string, branch?: string, build_id?: string, commit_ref?: string, commit_url?: string, context?: string, created_at?: string, deploy_ssl_url?: string, deploy_url?: string, draft?: bool, error_message?: string, framework?: string, function_schedules?: list, id?: string, locked?: bool, name?: string, published_at?: string, required?: list<string>, required_functions?: list<string>, review_id?: float, review_url?: string, screenshot_url?: string, site_capabilities?: record, ... (8 more fields)}
  --screenshot-url: string
  --session-id: string
  --ssl: oneof<nothing, bool>
  --ssl-url: string
  --state: string
  --updated-at: string # format: dateTime
  --url: string
  --user-id: string
  --repo: record # shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sites"
    query: [{name: configure_dns, var: configure_dns}]
    body: {content_type: "application/json", kind: json, fields: [{name: account_name, var: account_name}, {name: account_slug, var: account_slug}, {name: admin_url, var: admin_url}, {name: build_image, var: build_image}, {name: build_settings, var: build_settings}, {name: capabilities, var: capabilities}, {name: created_at, var: created_at}, {name: custom_domain, var: custom_domain}, {name: default_hooks_data, var: default_hooks_data}, {name: deploy_hook, var: deploy_hook}, {name: deploy_url, var: deploy_url}, {name: domain_aliases, var: domain_aliases}, {name: force_ssl, var: force_ssl}, {name: git_provider, var: git_provider}, {name: id, var: id}, {name: id_domain, var: id_domain}, {name: managed_dns, var: managed_dns}, {name: name, var: name}, {name: notification_email, var: notification_email}, {name: password, var: password}, {name: plan, var: plan}, {name: prerender, var: prerender}, {name: processing_settings, var: processing_settings}, {name: published_deploy, var: published_deploy}, {name: screenshot_url, var: screenshot_url}, {name: session_id, var: session_id}, {name: ssl, var: ssl}, {name: ssl_url, var: ssl_url}, {name: state, var: state}, {name: updated_at, var: updated_at}, {name: url, var: url}, {name: user_id, var: user_id}, {name: repo, var: repo}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    configure_dns: $configure_dns, account_name: $account_name, account_slug: $account_slug, admin_url: $admin_url, build_image: $build_image, build_settings: $build_settings, capabilities: $capabilities, created_at: $created_at, custom_domain: $custom_domain, default_hooks_data: $default_hooks_data, deploy_hook: $deploy_hook, deploy_url: $deploy_url, domain_aliases: $domain_aliases, force_ssl: $force_ssl, git_provider: $git_provider, id: $id, id_domain: $id_domain, managed_dns: $managed_dns, name: $name, notification_email: $notification_email, password: $password, plan: $plan, prerender: $prerender, processing_settings: $processing_settings, published_deploy: $published_deploy, screenshot_url: $screenshot_url, session_id: $session_id, ssl: $ssl, ssl_url: $ssl_url, state: $state, updated_at: $updated_at, url: $url, user_id: $user_id, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /sites/{site_id}
#
# operationId: deleteSite
export def "delete-site" [
  site_id: string
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
    method: delete
    path: "/sites/{site_id}"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [getEnvVars](#tag/environmentVariables/operation/getEnvVars) to retrieve site environment variables.
#
# GET /sites/{site_id}
# Returns: record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>
# operationId: getSite
export def "get-site" [
  site_id: string
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
    path: "/sites/{site_id}"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [updateEnvVar](#tag/environmentVariables/operation/updateEnvVar) to update a site's environment variables.
#
# PATCH /sites/{site_id}
# Returns: record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>
# operationId: updateSite
export def "update-site" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string
  --account-slug: string
  --admin-url: string
  --build-image: string
  --build-settings: record # shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
  --capabilities: record
  --created-at: string # format: dateTime
  --custom-domain: string
  --default-hooks-data: record # shape: {access_token?: string}
  --deploy-hook: string
  --deploy-url: string
  --domain-aliases: list<string>
  --force-ssl: oneof<nothing, bool>
  --git-provider: string
  --id: string
  --id-domain: string
  --managed-dns: oneof<nothing, bool>
  --name: string
  --notification-email: string
  --password: string
  --plan: string
  --prerender: string
  --processing-settings: record # shape: {css?: record, html?: record, images?: record, js?: record, skip?: bool}
  --published-deploy: record # shape: {admin_url?: string, branch?: string, build_id?: string, commit_ref?: string, commit_url?: string, context?: string, created_at?: string, deploy_ssl_url?: string, deploy_url?: string, draft?: bool, error_message?: string, framework?: string, function_schedules?: list, id?: string, locked?: bool, name?: string, published_at?: string, required?: list<string>, required_functions?: list<string>, review_id?: float, review_url?: string, screenshot_url?: string, site_capabilities?: record, ... (8 more fields)}
  --screenshot-url: string
  --session-id: string
  --ssl: oneof<nothing, bool>
  --ssl-url: string
  --state: string
  --updated-at: string # format: dateTime
  --url: string
  --user-id: string
  --repo: record # shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/sites/{site_id}"
    path_params: [{name: site_id, var: site_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: account_name, var: account_name}, {name: account_slug, var: account_slug}, {name: admin_url, var: admin_url}, {name: build_image, var: build_image}, {name: build_settings, var: build_settings}, {name: capabilities, var: capabilities}, {name: created_at, var: created_at}, {name: custom_domain, var: custom_domain}, {name: default_hooks_data, var: default_hooks_data}, {name: deploy_hook, var: deploy_hook}, {name: deploy_url, var: deploy_url}, {name: domain_aliases, var: domain_aliases}, {name: force_ssl, var: force_ssl}, {name: git_provider, var: git_provider}, {name: id, var: id}, {name: id_domain, var: id_domain}, {name: managed_dns, var: managed_dns}, {name: name, var: name}, {name: notification_email, var: notification_email}, {name: password, var: password}, {name: plan, var: plan}, {name: prerender, var: prerender}, {name: processing_settings, var: processing_settings}, {name: published_deploy, var: published_deploy}, {name: screenshot_url, var: screenshot_url}, {name: session_id, var: session_id}, {name: ssl, var: ssl}, {name: ssl_url, var: ssl_url}, {name: state, var: state}, {name: updated_at, var: updated_at}, {name: url, var: url}, {name: user_id, var: user_id}, {name: repo, var: repo}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, account_name: $account_name, account_slug: $account_slug, admin_url: $admin_url, build_image: $build_image, build_settings: $build_settings, capabilities: $capabilities, created_at: $created_at, custom_domain: $custom_domain, default_hooks_data: $default_hooks_data, deploy_hook: $deploy_hook, deploy_url: $deploy_url, domain_aliases: $domain_aliases, force_ssl: $force_ssl, git_provider: $git_provider, id: $id, id_domain: $id_domain, managed_dns: $managed_dns, name: $name, notification_email: $notification_email, password: $password, plan: $plan, prerender: $prerender, processing_settings: $processing_settings, published_deploy: $published_deploy, screenshot_url: $screenshot_url, session_id: $session_id, ssl: $ssl, ssl_url: $ssl_url, state: $state, updated_at: $updated_at, url: $url, user_id: $user_id, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/assets
#
# Returns: table<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string>
# operationId: listSiteAssets
export def "list-site-assets" [
  site_id: string
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
    path: "/sites/{site_id}/assets"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /sites/{site_id}/assets
#
# Returns: record<asset: record<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string>, form: record<fields: record, url: string>>
# operationId: createSiteAsset
export def "create-site-asset" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # required
  --size: int # required, format: int64
  --content-type: string # required
  --visibility: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/sites/{site_id}/assets"
    path_params: [{name: site_id, var: site_id}]
    query: [{name: name, var: name, required: true}, {name: size, var: size, required: true}, {name: content_type, var: content_type, required: true}, {name: visibility, var: visibility}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    site_id: $site_id, name: $name, size: $size, content_type: $content_type, visibility: $visibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /sites/{site_id}/assets/{asset_id}
#
# operationId: deleteSiteAsset
export def "delete-site-asset" [
  site_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/sites/{site_id}/assets/{asset_id}"
    path_params: [{name: site_id, var: site_id}, {name: asset_id, var: asset_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    site_id: $site_id, asset_id: $asset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/assets/{asset_id}
#
# Returns: record<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string>
# operationId: getSiteAssetInfo
export def "get-site-asset-info" [
  site_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sites/{site_id}/assets/{asset_id}"
    path_params: [{name: site_id, var: site_id}, {name: asset_id, var: asset_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, asset_id: $asset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /sites/{site_id}/assets/{asset_id}
#
# Returns: record<content_type: string, created_at: string, creator_id: string, id: string, key: string, name: string, site_id: string, size: int, state: string, updated_at: string, url: string, visibility: string>
# operationId: updateSiteAsset
export def "update-site-asset" [
  site_id: string
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
  --state: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/sites/{site_id}/assets/{asset_id}"
    path_params: [{name: site_id, var: site_id}, {name: asset_id, var: asset_id}]
    query: [{name: state, var: state, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, asset_id: $asset_id, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/assets/{asset_id}/public_signature
#
# Returns: record<url: string>
# operationId: getSiteAssetPublicSignature
export def "get-site-asset-public-signature" [
  site_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sites/{site_id}/assets/{asset_id}/public_signature"
    path_params: [{name: site_id, var: site_id}, {name: asset_id, var: asset_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, asset_id: $asset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/build_hooks
#
# Returns: table<branch: string, created_at: string, id: string, site_id: string, title: string, url: string>
# operationId: listSiteBuildHooks
export def "list-site-build-hooks" [
  site_id: string
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
    path: "/sites/{site_id}/build_hooks"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /sites/{site_id}/build_hooks
#
# Returns: record<branch: string, created_at: string, id: string, site_id: string, title: string, url: string>
# operationId: createSiteBuildHook
export def "create-site-build-hook" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch: string
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sites/{site_id}/build_hooks"
    path_params: [{name: site_id, var: site_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: branch, var: branch}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    site_id: $site_id, branch: $branch, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /sites/{site_id}/build_hooks/{id}
#
# operationId: deleteSiteBuildHook
export def "delete-site-build-hook" [
  site_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/sites/{site_id}/build_hooks/{id}"
    path_params: [{name: site_id, var: site_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    site_id: $site_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/build_hooks/{id}
#
# Returns: record<branch: string, created_at: string, id: string, site_id: string, title: string, url: string>
# operationId: getSiteBuildHook
export def "get-site-build-hook" [
  site_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sites/{site_id}/build_hooks/{id}"
    path_params: [{name: site_id, var: site_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /sites/{site_id}/build_hooks/{id}
#
# operationId: updateSiteBuildHook
export def "update-site-build-hook" [
  site_id: string
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
  --branch: string
  --title: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/sites/{site_id}/build_hooks/{id}"
    path_params: [{name: site_id, var: site_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: branch, var: branch}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    site_id: $site_id, id: $id, branch: $branch, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/builds
#
# Returns: table<created_at: string, deploy_id: string, done: bool, error: string, id: string, sha: string>
# operationId: listSiteBuilds
export def "list-site-builds" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/sites/{site_id}/builds"
    path_params: [{name: site_id, var: site_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /sites/{site_id}/builds
#
# Returns: record<created_at: string, deploy_id: string, done: bool, error: string, id: string, sha: string>
# operationId: createSiteBuild
export def "create-site-build" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-cache: oneof<nothing, bool>
  --image: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sites/{site_id}/builds"
    path_params: [{name: site_id, var: site_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: clear_cache, var: clear_cache}, {name: image, var: image}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, clear_cache: $clear_cache, image: $image
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/deployed-branches
#
# Returns: table<deploy_id: string, id: string, name: string, slug: string, ssl_url: string, url: string>
# operationId: listSiteDeployedBranches
export def "list-site-deployed-branches" [
  site_id: string
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
    path: "/sites/{site_id}/deployed-branches"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/deploys
#
# Returns: table<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>
# operationId: listSiteDeploys
export def "list-site-deploys" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deploy-previews: oneof<nothing, bool>
  --production: oneof<nothing, bool>
  --state: string@state-completer
  --branch: string
  --latest-published: oneof<nothing, bool>
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/sites/{site_id}/deploys"
    path_params: [{name: site_id, var: site_id}]
    query: [{name: deploy-previews, var: deploy_previews}, {name: production, var: production}, {name: state, var: state}, {name: branch, var: branch}, {name: latest-published, var: latest_published}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, deploy_previews: $deploy_previews, production: $production, state: $state, branch: $branch, latest_published: $latest_published, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /sites/{site_id}/deploys
#
# Returns: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>
# operationId: createSiteDeploy
export def "create-site-deploy" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deploy-previews: oneof<nothing, bool>
  --production: oneof<nothing, bool>
  --state: string@state-completer
  --branch: string
  --latest-published: oneof<nothing, bool>
  --title: string
  --async: oneof<nothing, bool>
  --body-branch: string # (spec name: branch)
  --draft: oneof<nothing, bool>
  --files: record
  --framework: string
  --function-schedules: list # item shape: {cron?: string, name?: string}
  --functions: record
  --functions-config: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sites/{site_id}/deploys"
    path_params: [{name: site_id, var: site_id}]
    query: [{name: deploy-previews, var: deploy_previews}, {name: production, var: production}, {name: state, var: state}, {name: branch, var: branch}, {name: latest-published, var: latest_published}, {name: title, var: title}]
    body: {content_type: "application/json", kind: json, fields: [{name: async, var: async}, {name: branch, var: body_branch}, {name: draft, var: draft}, {name: files, var: files}, {name: framework, var: framework}, {name: function_schedules, var: function_schedules}, {name: functions, var: functions}, {name: functions_config, var: functions_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, deploy_previews: $deploy_previews, production: $production, state: $state, branch: $branch, latest_published: $latest_published, title: $title, async: $async, body_branch: $body_branch, draft: $draft, files: $files, framework: $framework, function_schedules: $function_schedules, functions: $functions, functions_config: $functions_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /sites/{site_id}/deploys/{deploy_id}
#
# operationId: deleteSiteDeploy
export def "delete-site-deploy" [
  site_id: string
  deploy_id: string
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
    method: delete
    path: "/sites/{site_id}/deploys/{deploy_id}"
    path_params: [{name: site_id, var: site_id}, {name: deploy_id, var: deploy_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    site_id: $site_id, deploy_id: $deploy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/deploys/{deploy_id}
#
# Returns: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>
# operationId: getSiteDeploy
export def "get-site-deploy" [
  site_id: string
  deploy_id: string
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
    path: "/sites/{site_id}/deploys/{deploy_id}"
    path_params: [{name: site_id, var: site_id}, {name: deploy_id, var: deploy_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, deploy_id: $deploy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /sites/{site_id}/deploys/{deploy_id}
#
# Returns: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>
# operationId: updateSiteDeploy
export def "update-site-deploy" [
  site_id: string
  deploy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async: oneof<nothing, bool>
  --branch: string
  --draft: oneof<nothing, bool>
  --files: record
  --framework: string
  --function-schedules: list # item shape: {cron?: string, name?: string}
  --functions: record
  --functions-config: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sites/{site_id}/deploys/{deploy_id}"
    path_params: [{name: site_id, var: site_id}, {name: deploy_id, var: deploy_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: async, var: async}, {name: branch, var: branch}, {name: draft, var: draft}, {name: files, var: files}, {name: framework, var: framework}, {name: function_schedules, var: function_schedules}, {name: functions, var: functions}, {name: functions_config, var: functions_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, deploy_id: $deploy_id, async: $async, branch: $branch, draft: $draft, files: $files, framework: $framework, function_schedules: $function_schedules, functions: $functions, functions_config: $functions_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /sites/{site_id}/deploys/{deploy_id}/restore
#
# Returns: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: table<cron: string, name: string>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>
# operationId: restoreSiteDeploy
export def "restore-site-deploy" [
  site_id: string
  deploy_id: string
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
    path: "/sites/{site_id}/deploys/{deploy_id}/restore"
    path_params: [{name: site_id, var: site_id}, {name: deploy_id, var: deploy_id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    site_id: $site_id, deploy_id: $deploy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/dns
#
# Returns: table<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: list<record>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string>
# operationId: getDNSForSite
export def "get-dns-for-site" [
  site_id: string
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
    path: "/sites/{site_id}/dns"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /sites/{site_id}/dns
#
# Returns: table<account_id: string, account_name: string, account_slug: string, created_at: string, dedicated: bool, dns_servers: list<string>, domain: string, errors: list<string>, id: string, ipv6_enabled: bool, name: string, records: list<record>, site_id: string, supported_record_types: list<string>, updated_at: string, user_id: string>
# operationId: configureDNSForSite
export def "configure-dns-for-site" [
  site_id: string
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
    method: put
    path: "/sites/{site_id}/dns"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/files
#
# Returns: table<id: string, mime_type: string, path: string, sha: string, size: int>
# operationId: listSiteFiles
export def "list-site-files" [
  site_id: string
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
    path: "/sites/{site_id}/files"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/files/{file_path}
#
# Returns: record<id: string, mime_type: string, path: string, sha: string, size: int>
# operationId: getSiteFileByPathName
export def "get-site-file-by-path-name" [
  site_id: string
  file_path: string
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
    path: "/sites/{site_id}/files/{file_path}"
    path_params: [{name: site_id, var: site_id}, {name: file_path, var: file_path}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, file_path: $file_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/forms
#
# Returns: table<created_at: string, fields: list<record>, id: string, name: string, paths: list<string>, site_id: string, submission_count: int>
# operationId: listSiteForms
export def "list-site-forms" [
  site_id: string
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
    path: "/sites/{site_id}/forms"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /sites/{site_id}/forms/{form_id}
#
# operationId: deleteSiteForm
export def "delete-site-form" [
  site_id: string
  form_id: string
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
    method: delete
    path: "/sites/{site_id}/forms/{form_id}"
    path_params: [{name: site_id, var: site_id}, {name: form_id, var: form_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    site_id: $site_id, form_id: $form_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/metadata
#
# Returns: record
# operationId: getSiteMetadata
export def "get-site-metadata" [
  site_id: string
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
    path: "/sites/{site_id}/metadata"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /sites/{site_id}/metadata
#
# operationId: updateSiteMetadata
export def "update-site-metadata" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: put
    path: "/sites/{site_id}/metadata"
    path_params: [{name: site_id, var: site_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    site_id: $site_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is an internal-only endpoint.
#
# GET /sites/{site_id}/plugin_runs/latest
# Returns: table<package: string, reporting_event: string, state: string, summary: string, text: string, title: string, version: string, deploy_id: string>
# operationId: getLatestPluginRuns
export def "get-latest-plugin-runs" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --packages: list<string> # required
  --state: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/sites/{site_id}/plugin_runs/latest"
    path_params: [{name: site_id, var: site_id}]
    query: [{name: packages, var: packages, style: csv, required: true}, {name: state, var: state}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, packages: $packages, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is an internal-only endpoint.
#
# PUT /sites/{site_id}/plugins/{package}
# Returns: record<package: string, pinned_version: string>
# operationId: updatePlugin
export def "update-plugin" [
  site_id: string
  package: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pinned-version: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sites/{site_id}/plugins/{package}"
    path_params: [{name: site_id, var: site_id}, {name: package, var: package}]
    body: {content_type: "application/json", kind: json, fields: [{name: pinned_version, var: pinned_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, package: $package, pinned_version: $pinned_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /sites/{site_id}/rollback
#
# operationId: rollbackSiteDeploy
export def "rollback-site-deploy" [
  site_id: string
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
    method: put
    path: "/sites/{site_id}/rollback"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/service-instances
#
# Returns: table<auth_url: string, config: record, created_at: string, env: record, external_attributes: record, id: string, service_name: string, service_path: string, service_slug: string, snippets: list<record>, updated_at: string, url: string>
# operationId: listServiceInstancesForSite
export def "list-service-instances-for-site" [
  site_id: string
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
    path: "/sites/{site_id}/service-instances"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /sites/{site_id}/services/{addon}/instances
#
# Returns: record<auth_url: string, config: record, created_at: string, env: record, external_attributes: record, id: string, service_name: string, service_path: string, service_slug: string, snippets: list<record>, updated_at: string, url: string>
# operationId: createServiceInstance
export def "create-service-instance" [
  site_id: string
  addon: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sites/{site_id}/services/{addon}/instances"
    path_params: [{name: site_id, var: site_id}, {name: addon, var: addon}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    site_id: $site_id, addon: $addon, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /sites/{site_id}/services/{addon}/instances/{instance_id}
#
# operationId: deleteServiceInstance
export def "delete-service-instance" [
  site_id: string
  addon: string
  instance_id: string
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
    method: delete
    path: "/sites/{site_id}/services/{addon}/instances/{instance_id}"
    path_params: [{name: site_id, var: site_id}, {name: addon, var: addon}, {name: instance_id, var: instance_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    site_id: $site_id, addon: $addon, instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/services/{addon}/instances/{instance_id}
#
# Returns: record<auth_url: string, config: record, created_at: string, env: record, external_attributes: record, id: string, service_name: string, service_path: string, service_slug: string, snippets: list<record>, updated_at: string, url: string>
# operationId: showServiceInstance
export def "show-service-instance" [
  site_id: string
  addon: string
  instance_id: string
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
    path: "/sites/{site_id}/services/{addon}/instances/{instance_id}"
    path_params: [{name: site_id, var: site_id}, {name: addon, var: addon}, {name: instance_id, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, addon: $addon, instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /sites/{site_id}/services/{addon}/instances/{instance_id}
#
# operationId: updateServiceInstance
export def "update-service-instance" [
  site_id: string
  addon: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: put
    path: "/sites/{site_id}/services/{addon}/instances/{instance_id}"
    path_params: [{name: site_id, var: site_id}, {name: addon, var: addon}, {name: instance_id, var: instance_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    site_id: $site_id, addon: $addon, instance_id: $instance_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/snippets
#
# Returns: table<general: string, general_position: string, goal: string, goal_position: string, id: int, site_id: string, title: string>
# operationId: listSiteSnippets
export def "list-site-snippets" [
  site_id: string
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
    path: "/sites/{site_id}/snippets"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /sites/{site_id}/snippets
#
# Returns: record<general: string, general_position: string, goal: string, goal_position: string, id: int, site_id: string, title: string>
# operationId: createSiteSnippet
export def "create-site-snippet" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --general: string
  --general-position: string
  --goal: string
  --goal-position: string
  --id: int # format: int32
  --body-site-id: string # (spec name: site_id)
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sites/{site_id}/snippets"
    path_params: [{name: site_id, var: site_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: general, var: general}, {name: general_position, var: general_position}, {name: goal, var: goal}, {name: goal_position, var: goal_position}, {name: id, var: id}, {name: site_id, var: body_site_id}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    site_id: $site_id, general: $general, general_position: $general_position, goal: $goal, goal_position: $goal_position, id: $id, body_site_id: $body_site_id, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /sites/{site_id}/snippets/{snippet_id}
#
# operationId: deleteSiteSnippet
export def "delete-site-snippet" [
  site_id: string
  snippet_id: string
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
    method: delete
    path: "/sites/{site_id}/snippets/{snippet_id}"
    path_params: [{name: site_id, var: site_id}, {name: snippet_id, var: snippet_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    site_id: $site_id, snippet_id: $snippet_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/snippets/{snippet_id}
#
# Returns: record<general: string, general_position: string, goal: string, goal_position: string, id: int, site_id: string, title: string>
# operationId: getSiteSnippet
export def "get-site-snippet" [
  site_id: string
  snippet_id: string
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
    path: "/sites/{site_id}/snippets/{snippet_id}"
    path_params: [{name: site_id, var: site_id}, {name: snippet_id, var: snippet_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, snippet_id: $snippet_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /sites/{site_id}/snippets/{snippet_id}
#
# operationId: updateSiteSnippet
export def "update-site-snippet" [
  site_id: string
  snippet_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --general: string
  --general-position: string
  --goal: string
  --goal-position: string
  --id: int # format: int32
  --body-site-id: string # (spec name: site_id)
  --title: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/sites/{site_id}/snippets/{snippet_id}"
    path_params: [{name: site_id, var: site_id}, {name: snippet_id, var: snippet_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: general, var: general}, {name: general_position, var: general_position}, {name: goal, var: goal}, {name: goal_position, var: goal_position}, {name: id, var: id}, {name: site_id, var: body_site_id}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    site_id: $site_id, snippet_id: $snippet_id, general: $general, general_position: $general_position, goal: $goal, goal_position: $goal_position, id: $id, body_site_id: $body_site_id, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/ssl
#
# Returns: record<created_at: string, domains: list<string>, expires_at: string, state: string, updated_at: string>
# operationId: showSiteTLSCertificate
export def "show-site-tls-certificate" [
  site_id: string
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
    path: "/sites/{site_id}/ssl"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /sites/{site_id}/ssl
#
# Returns: record<created_at: string, domains: list<string>, expires_at: string, state: string, updated_at: string>
# operationId: provisionSiteTLSCertificate
export def "provision-site-tls-certificate" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificate: string
  --key: string
  --ca-certificates: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/sites/{site_id}/ssl"
    path_params: [{name: site_id, var: site_id}]
    query: [{name: certificate, var: certificate}, {name: key, var: key}, {name: ca_certificates, var: ca_certificates}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, certificate: $certificate, key: $key, ca_certificates: $ca_certificates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/submissions
#
# Returns: table<body: string, company: string, created_at: string, data: record, email: string, first_name: string, id: string, last_name: string, name: string, number: int, site_url: string, summary: string>
# operationId: listSiteSubmissions
export def "list-site-submissions" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/sites/{site_id}/submissions"
    path_params: [{name: site_id, var: site_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/traffic_splits
#
# Returns: table<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string>
# operationId: getSplitTests
export def "get-split-tests" [
  site_id: string
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
    path: "/sites/{site_id}/traffic_splits"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /sites/{site_id}/traffic_splits
#
# Returns: record<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string>
# operationId: createSplitTest
export def "create-split-test" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch-tests: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sites/{site_id}/traffic_splits"
    path_params: [{name: site_id, var: site_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: branch_tests, var: branch_tests}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    site_id: $site_id, branch_tests: $branch_tests
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /sites/{site_id}/traffic_splits/{split_test_id}
#
# Returns: record<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string>
# operationId: getSplitTest
export def "get-split-test" [
  site_id: string
  split_test_id: string
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
    path: "/sites/{site_id}/traffic_splits/{split_test_id}"
    path_params: [{name: site_id, var: site_id}, {name: split_test_id, var: split_test_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, split_test_id: $split_test_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /sites/{site_id}/traffic_splits/{split_test_id}
#
# Returns: record<active: bool, branches: list<record>, created_at: string, id: string, name: string, path: string, site_id: string, unpublished_at: string, updated_at: string>
# operationId: updateSplitTest
export def "update-split-test" [
  site_id: string
  split_test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch-tests: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sites/{site_id}/traffic_splits/{split_test_id}"
    path_params: [{name: site_id, var: site_id}, {name: split_test_id, var: split_test_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: branch_tests, var: branch_tests}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    site_id: $site_id, split_test_id: $split_test_id, branch_tests: $branch_tests
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /sites/{site_id}/traffic_splits/{split_test_id}/publish
#
# operationId: enableSplitTest
export def "enable-split-test" [
  site_id: string
  split_test_id: string
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
    method: post
    path: "/sites/{site_id}/traffic_splits/{split_test_id}/publish"
    path_params: [{name: site_id, var: site_id}, {name: split_test_id, var: split_test_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    site_id: $site_id, split_test_id: $split_test_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /sites/{site_id}/traffic_splits/{split_test_id}/unpublish
#
# operationId: disableSplitTest
export def "disable-split-test" [
  site_id: string
  split_test_id: string
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
    method: post
    path: "/sites/{site_id}/traffic_splits/{split_test_id}/unpublish"
    path_params: [{name: site_id, var: site_id}, {name: split_test_id, var: split_test_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    site_id: $site_id, split_test_id: $split_test_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# [Beta] Unlinks the repo from the site. This action will also: - Delete associated deploy keys - Delete outgoing webhooks for the repo - Delete the site's build hooks
#
# PUT /sites/{site_id}/unlink_repo
# Returns: record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>
# operationId: unlinkSiteRepo
export def "unlink-site-repo" [
  site_id: string
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
    path: "/sites/{site_id}/unlink_repo"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /submissions/{submission_id}
#
# operationId: deleteSubmission
export def "delete-submission" [
  submission_id: string
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
    method: delete
    path: "/submissions/{submission_id}"
    path_params: [{name: submission_id, var: submission_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    submission_id: $submission_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /submissions/{submission_id}
#
# Returns: table<body: string, company: string, created_at: string, data: record, email: string, first_name: string, id: string, last_name: string, name: string, number: int, site_url: string, summary: string>
# operationId: listFormSubmission
export def "list-form-submission" [
  submission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/submissions/{submission_id}"
    path_params: [{name: submission_id, var: submission_id}]
    query: [{name: query, var: query}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    submission_id: $submission_id, query: $query, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /user
#
# Returns: table<affiliate_id: string, avatar_url: string, created_at: string, email: string, full_name: string, id: string, last_login: string, login_providers: list<string>, onboarding_progress: record<slides: string>, site_count: int, uid: string>
# operationId: getCurrentUser
export def "get-current-user" [
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
    path: "/user"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /{account_id}/builds/status
#
# Returns: table<active: int, build_count: int, enqueued: int, minutes: record<current: int, current_average_sec: int, included_minutes: string, included_minutes_with_packs: string, last_updated_at: string, period_end_date: string, period_start_date: string, previous: int>, pending_concurrency: int>
# operationId: getAccountBuildStatus
export def "get-account-build-status" [
  account_id: string
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
    path: "/{account_id}/builds/status"
    path_params: [{name: account_id, var: account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /{account_slug}/members
#
# Returns: table<avatar: string, email: string, full_name: string, id: string, role: string>
# operationId: listMembersForAccount
export def "list-members-for-account" [
  account_slug: string
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
    path: "/{account_slug}/members"
    path_params: [{name: account_slug, var: account_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_slug: $account_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /{account_slug}/members
#
# Returns: table<avatar: string, email: string, full_name: string, id: string, role: string>
# operationId: addMemberToAccount
export def "add-member-to-account" [
  account_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --role: string@role-completer
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{account_slug}/members"
    path_params: [{name: account_slug, var: account_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: role, var: role}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_slug: $account_slug, email: $email, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /{account_slug}/members/{member_id}
#
# operationId: removeAccountMember
export def "remove-account-member" [
  account_slug: string
  member_id: string
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
    method: delete
    path: "/{account_slug}/members/{member_id}"
    path_params: [{name: account_slug, var: account_slug}, {name: member_id, var: member_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account_slug: $account_slug, member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /{account_slug}/members/{member_id}
#
# Returns: record<avatar: string, email: string, full_name: string, id: string, role: string>
# operationId: getAccountMember
export def "get-account-member" [
  account_slug: string
  member_id: string
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
    path: "/{account_slug}/members/{member_id}"
    path_params: [{name: account_slug, var: account_slug}, {name: member_id, var: member_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_slug: $account_slug, member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /{account_slug}/members/{member_id}
#
# Returns: record<avatar: string, email: string, full_name: string, id: string, role: string>
# operationId: updateAccountMember
export def "update-account-member" [
  account_slug: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer
  --site-access: string@site-access-completer
  --site-ids: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{account_slug}/members/{member_id}"
    path_params: [{name: account_slug, var: account_slug}, {name: member_id, var: member_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: role, var: role}, {name: site_access, var: site_access}, {name: site_ids, var: site_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_slug: $account_slug, member_id: $member_id, role: $role, site_access: $site_access, site_ids: $site_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [getEnvVars](#tag/environmentVariables/operation/getEnvVars) to retrieve site environment variables.
#
# GET /{account_slug}/sites
# Returns: table<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record, html: record, images: record, js: record, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list, id: string, locked: bool, name: string, published_at: string, required: list, required_functions: list, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>
# operationId: listSitesForAccount
export def "list-sites-for-account" [
  account_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{account_slug}/sites"
    path_params: [{name: account_slug, var: account_slug}]
    query: [{name: name, var: name}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_slug: $account_slug, name: $name, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# **Note:** Environment variable keys and values will soon be moved from `build_settings.env` and `repo.env` to a new endpoint. Please use [createEnvVars](#tag/environmentVariables/operation/createEnvVars) to create environment variables for a site.
#
# POST /{account_slug}/sites
# Returns: record<account_name: string, account_slug: string, admin_url: string, build_image: string, build_settings: record<allowed_branches: list<string>, cmd: string, deploy_key_id: string, dir: string, env: record, functions_dir: string, id: int, installation_id: int, private_logs: bool, provider: string, public_repo: bool, repo_branch: string, repo_path: string, repo_url: string, stop_builds: bool>, capabilities: record, created_at: string, custom_domain: string, default_hooks_data: record<access_token: string>, deploy_hook: string, deploy_url: string, domain_aliases: list<string>, force_ssl: bool, git_provider: string, id: string, id_domain: string, managed_dns: bool, name: string, notification_email: string, password: string, plan: string, prerender: string, processing_settings: record<css: record<bundle: bool, minify: bool>, html: record<pretty_urls: bool>, images: record<optimize: bool>, js: record<bundle: bool, minify: bool>, skip: bool>, published_deploy: record<admin_url: string, branch: string, build_id: string, commit_ref: string, commit_url: string, context: string, created_at: string, deploy_ssl_url: string, deploy_url: string, draft: bool, error_message: string, framework: string, function_schedules: list<record>, id: string, locked: bool, name: string, published_at: string, required: list<string>, required_functions: list<string>, review_id: float, review_url: string, screenshot_url: string, site_capabilities: record<large_media_enabled: bool>, site_id: string, skipped: bool, ssl_url: string, state: string, title: string, updated_at: string, url: string, user_id: string>, screenshot_url: string, session_id: string, ssl: bool, ssl_url: string, state: string, updated_at: string, url: string, user_id: string>
# operationId: createSiteInTeam
export def "create-site-in-team" [
  account_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --configure-dns: oneof<nothing, bool>
  --account-name: string
  --body-account-slug: string # (spec name: account_slug)
  --admin-url: string
  --build-image: string
  --build-settings: record # shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
  --capabilities: record
  --created-at: string # format: dateTime
  --custom-domain: string
  --default-hooks-data: record # shape: {access_token?: string}
  --deploy-hook: string
  --deploy-url: string
  --domain-aliases: list<string>
  --force-ssl: oneof<nothing, bool>
  --git-provider: string
  --id: string
  --id-domain: string
  --managed-dns: oneof<nothing, bool>
  --name: string
  --notification-email: string
  --password: string
  --plan: string
  --prerender: string
  --processing-settings: record # shape: {css?: record, html?: record, images?: record, js?: record, skip?: bool}
  --published-deploy: record # shape: {admin_url?: string, branch?: string, build_id?: string, commit_ref?: string, commit_url?: string, context?: string, created_at?: string, deploy_ssl_url?: string, deploy_url?: string, draft?: bool, error_message?: string, framework?: string, function_schedules?: list, id?: string, locked?: bool, name?: string, published_at?: string, required?: list<string>, required_functions?: list<string>, review_id?: float, review_url?: string, screenshot_url?: string, site_capabilities?: record, ... (8 more fields)}
  --screenshot-url: string
  --session-id: string
  --ssl: oneof<nothing, bool>
  --ssl-url: string
  --state: string
  --updated-at: string # format: dateTime
  --url: string
  --user-id: string
  --repo: record # shape: {allowed_branches?: list<string>, cmd?: string, deploy_key_id?: string, dir?: string, env?: record, functions_dir?: string, id?: int, installation_id?: int, private_logs?: bool, provider?: string, public_repo?: bool, repo_branch?: string, repo_path?: string, repo_url?: string, stop_builds?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{account_slug}/sites"
    path_params: [{name: account_slug, var: account_slug}]
    query: [{name: configure_dns, var: configure_dns}]
    body: {content_type: "application/json", kind: json, fields: [{name: account_name, var: account_name}, {name: account_slug, var: body_account_slug}, {name: admin_url, var: admin_url}, {name: build_image, var: build_image}, {name: build_settings, var: build_settings}, {name: capabilities, var: capabilities}, {name: created_at, var: created_at}, {name: custom_domain, var: custom_domain}, {name: default_hooks_data, var: default_hooks_data}, {name: deploy_hook, var: deploy_hook}, {name: deploy_url, var: deploy_url}, {name: domain_aliases, var: domain_aliases}, {name: force_ssl, var: force_ssl}, {name: git_provider, var: git_provider}, {name: id, var: id}, {name: id_domain, var: id_domain}, {name: managed_dns, var: managed_dns}, {name: name, var: name}, {name: notification_email, var: notification_email}, {name: password, var: password}, {name: plan, var: plan}, {name: prerender, var: prerender}, {name: processing_settings, var: processing_settings}, {name: published_deploy, var: published_deploy}, {name: screenshot_url, var: screenshot_url}, {name: session_id, var: session_id}, {name: ssl, var: ssl}, {name: ssl_url, var: ssl_url}, {name: state, var: state}, {name: updated_at, var: updated_at}, {name: url, var: url}, {name: user_id, var: user_id}, {name: repo, var: repo}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account_slug: $account_slug, configure_dns: $configure_dns, account_name: $account_name, body_account_slug: $body_account_slug, admin_url: $admin_url, build_image: $build_image, build_settings: $build_settings, capabilities: $capabilities, created_at: $created_at, custom_domain: $custom_domain, default_hooks_data: $default_hooks_data, deploy_hook: $deploy_hook, deploy_url: $deploy_url, domain_aliases: $domain_aliases, force_ssl: $force_ssl, git_provider: $git_provider, id: $id, id_domain: $id_domain, managed_dns: $managed_dns, name: $name, notification_email: $notification_email, password: $password, plan: $plan, prerender: $prerender, processing_settings: $processing_settings, published_deploy: $published_deploy, screenshot_url: $screenshot_url, session_id: $session_id, ssl: $ssl, ssl_url: $ssl_url, state: $state, updated_at: $updated_at, url: $url, user_id: $user_id, repo: $repo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
