# Auto-generated client for Conjur v5.3.0
# Source: https://api.apis.guru/v2/specs/conjur.local/5.3.0/openapi.json
# Auth: --token flag or $env.CONJUR_TOKEN
# Auth (basicAuth): --token-basicauth flag or $env.CONJUR_BASICAUTH_TOKEN
# Auth (conjurAuth): --token-conjurauth flag or $env.CONJUR_CONJURAUTH_TOKEN

const CLIENT = {
  base_url: "http://conjur.local"
  token_env_var: "CONJUR_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: basic, in: header, header_name: Authorization, prefix: Basic}
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
    {name: mutual, in: header, header_name: Authorization, prefix: Mutual}
    {name: basic-credentials, in: header, header_name: Authorization, prefix: Basic, base64: true}
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

def base-url-completer [] { ["http://conjur.local" "https://api.apis.guru"] }
def auth-scheme-completer [] { ["basic" "bearer" "mutual" "none" "basic-credentials"] }

# Completers for enum parameters
def accept-encoding-completer [] { ["application/json" "base64"] }
def accept-encoding-completer-1 [] { ["base64"] }
def accept-completer [] { ["application/json" "application/x-pem-file"] }
def authenticator-completer [] { ["authn-azure" "authn-gcp" "authn-iam" "authn-jwt" "authn-k8s" "authn-ldap" "authn-oidc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help" "token-basicauth" "token-conjurauth"]
  let return_types = {
    get-authenticators: "record<configured: list<string>, enabled: list<string>, installed: list<string>>"
    get-access-token-via-azure: "string"
    get-access-token-via-gcp: "string"
    get-gcp-authenticator-status: "record<error: string, status: string>"
    get-access-token-via-aws: "string"
    get-access-token-via-jwt: "string"
    get-access-token-via-jwt-with-id: "string"
    get-access-token-via-kubernetes: "string"
    get-api-key-via-ldap: "string"
    get-access-token-via-ldap: "string"
    get-access-token-via-oidc: "string"
    rotate-api-key: "string"
    get-api-key: "string"
    get-access-token: "string"
    sign: "record<certificate: string>"
    health: "record"
    create-host: "record<annotations: list<string>, api_key: string, created_at: string, id: string, owner: string, permissions: list<string>>"
    create-token: "table<cidr: list<string>, expiration: string, token: string>"
    info: "record<authenticators: record<configured: list<string>, enabled: list<string>, installed: list<string>>, configuration: record, container: string, release: string, role: string, services: record, version: string>"
    update-policy: "record<created_roles: record, version: float>"
    load-policy: "record<created_roles: record, version: float>"
    replace-policy: "record<created_roles: record, version: float>"
    show-public-keys: "string"
    remote-health: "record"
    show-resources-for-all-accounts: "table<annotations: list<string>, created_at: string, id: string, owner: string, permissions: list<record>, policy: string, policy_versions: list<record>, restricted_to: list<string>, secrets: list<record>>"
    show-resources-for-account: "table<annotations: list<string>, created_at: string, id: string, owner: string, permissions: list<record>, policy: string, policy_versions: list<record>, restricted_to: list<string>, secrets: list<record>>"
    show-resources-for-kind: "table<annotations: list<string>, created_at: string, id: string, owner: string, permissions: list<record>, policy: string, policy_versions: list<record>, restricted_to: list<string>, secrets: list<record>>"
    show-resource: "record<annotations: list<string>, created_at: string, id: string, owner: string, permissions: table<policy: string, privilege: string, role: string>, policy: string, policy_versions: table<client_ip: string, created_at: string, finished_at: string, id: string, policy_sha256: string, policy_text: string, role: string, version: float>, restricted_to: list<string>, secrets: table<expires_at: string, version: float>>"
    show-role: "record"
    get-secrets: "record"
    get-secret: "string"
    who-am-i: "record<account: string, client_ip: string, token_issued_at: string, user_agent: string, username: string>"
    get-service-authenticator-status: "record<error: string, status: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-authenticators" "get-access-token-via-azure" "get-access-token-via-gcp" "get-gcp-authenticator-status" "get-access-token-via-aws" "get-access-token-via-jwt" "get-access-token-via-jwt-with-id" "k8s-inject-client-cert" "get-access-token-via-kubernetes" "get-api-key-via-ldap" "get-access-token-via-ldap" "get-access-token-via-oidc" "rotate-api-key" "get-api-key" "change-password" "get-access-token" "sign" "health" "create-host" "create-token" "revoke-token" "info" "update-policy" "load-policy" "replace-policy" "show-public-keys" "remote-health" "show-resources-for-all-accounts" "show-resources-for-account" "show-resources-for-kind" "show-resource" "remove-member-from-role" "show-role" "add-member-to-role" "get-secrets" "get-secret" "create-secret" "who-am-i" "enable-authenticator" "enable-authenticator-instance" "get-service-authenticator-status" "commands"] | sort) } | get name | first)
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

# Details about which authenticators are on the Conjur Server
#
# GET /authenticators
# Returns: record<configured: list<string>, enabled: list<string>, installed: list<string>>
# operationId: getAuthenticators
export def "get-authenticators" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/authenticators"
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-lived access token for applications running in Azure.
#
# POST /authn-azure/{service_id}/{account}/{login}/authenticate
# Returns: string
# operationId: getAccessTokenViaAzure
export def "get-access-token-via-azure" [
  service_id: string
  account: string
  login: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --accept-encoding: string@accept-encoding-completer # Setting the Accept-Encoding header to base64 will return a pre-encoded access token (default: application/json)
  --jwt: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/authn-azure/{service_id}/{account}/{login}/authenticate"
    path_params: [{name: service_id, var: service_id}, {name: account, var: account}, {name: login, var: login}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: Accept-Encoding, var: accept_encoding}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: jwt, var: jwt}]}
    accept: ["text/plain"]
    ok: [200]
    auth: none
  } {
    service_id: $service_id, account: $account, login: $login, x_request_id: $x_request_id, accept_encoding: $accept_encoding, jwt: $jwt
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-lived access token for applications running in Google Cloud Platform.
#
# POST /authn-gcp/{account}/authenticate
# Returns: string
# operationId: getAccessTokenViaGCP
export def "get-access-token-via-gcp" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --accept-encoding: string@accept-encoding-completer-1 # Setting the Accept-Encoding header to base64 will return a pre-encoded access token
  --jwt: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/authn-gcp/{account}/authenticate"
    path_params: [{name: account, var: account}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: Accept-Encoding, var: accept_encoding}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: jwt, var: jwt}]}
    accept: ["text/plain"]
    ok: [200]
    auth: none
  } {
    account: $account, x_request_id: $x_request_id, accept_encoding: $accept_encoding, jwt: $jwt
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Details whether an authentication service has been configured properly
#
# GET /authn-gcp/{account}/status
# Returns: record<error: string, status: string>
# operationId: getGCPAuthenticatorStatus
export def "get-gcp-authenticator-status" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/authn-gcp/{account}/status"
    path_params: [{name: account, var: account}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account: $account, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a short-lived access token for applications running in AWS.
#
# POST /authn-iam/{service_id}/{account}/{login}/authenticate
# Returns: string
# operationId: getAccessTokenViaAWS
export def "get-access-token-via-aws" [
  service_id: string
  account: string
  login: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --accept-encoding: string@accept-encoding-completer # Setting the Accept-Encoding header to base64 will return a pre-encoded access token (default: application/json)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/authn-iam/{service_id}/{account}/{login}/authenticate"
    path_params: [{name: service_id, var: service_id}, {name: account, var: account}, {name: login, var: login}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: Accept-Encoding, var: accept_encoding}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["text/plain"]
    ok: [200]
    auth: none
  } {
    service_id: $service_id, account: $account, login: $login, x_request_id: $x_request_id, accept_encoding: $accept_encoding, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-lived access token for applications using JSON Web Token (JWT) to access the Conjur API.
#
# POST /authn-jwt/{service_id}/{account}/authenticate
# Returns: string
# operationId: getAccessTokenViaJWT
export def "get-access-token-via-jwt" [
  service_id: string
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --jwt: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/authn-jwt/{service_id}/{account}/authenticate"
    path_params: [{name: service_id, var: service_id}, {name: account, var: account}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: jwt, var: jwt}]}
    accept: ["text/plain"]
    ok: [200]
    auth: none
  } {
    service_id: $service_id, account: $account, x_request_id: $x_request_id, jwt: $jwt
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-lived access token for applications using JSON Web Token (JWT) to access the Conjur API. Covers the case of use of optional URL parameter "ID"
#
# POST /authn-jwt/{service_id}/{account}/{id}/authenticate
# Returns: string
# operationId: getAccessTokenViaJWTWithId
export def "get-access-token-via-jwt-with-id" [
  service_id: string
  account: string
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
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --jwt: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/authn-jwt/{service_id}/{account}/{id}/authenticate"
    path_params: [{name: service_id, var: service_id}, {name: account, var: account}, {name: id, var: id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: jwt, var: jwt}]}
    accept: ["text/plain"]
    ok: [200]
    auth: none
  } {
    service_id: $service_id, account: $account, id: $id, x_request_id: $x_request_id, jwt: $jwt
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For applications running in Kubernetes; sends Conjur a certificate signing request (CSR) and requests a client certificate injected into the application's Kubernetes pod.
#
# POST /authn-k8s/{service_id}/inject_client_cert
# operationId: k8sInjectClientCert
export def "k8s-inject-client-cert" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --host-id-prefix: string # Dot-separated policy tree, prefixed by `host.`, where the application identity is defined (e.g. host/conjur/authn-k8s/my-authenticator-id/apps)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/authn-k8s/{service_id}/inject_client_cert"
    path_params: [{name: service_id, var: service_id}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: Host-Id-Prefix, var: host_id_prefix}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [202]
    auth: basic
  } {
    service_id: $service_id, x_request_id: $x_request_id, host_id_prefix: $host_id_prefix, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-lived access token for applications running in Kubernetes.
#
# POST /authn-k8s/{service_id}/{account}/{login}/authenticate
# Returns: string
# operationId: getAccessTokenViaKubernetes
export def "get-access-token-via-kubernetes" [
  service_id: string
  account: string
  login: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --accept-encoding: string@accept-encoding-completer # Setting the Accept-Encoding header to base64 will return a pre-encoded access token (default: application/json)
]: nothing -> any {
  http-request {
    method: post
    path: "/authn-k8s/{service_id}/{account}/{login}/authenticate"
    path_params: [{name: service_id, var: service_id}, {name: account, var: account}, {name: login, var: login}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: Accept-Encoding, var: accept_encoding}]
    accept: ["text/plain"]
    ok: [200]
    auth: mutual
  } {
    service_id: $service_id, account: $account, login: $login, x_request_id: $x_request_id, accept_encoding: $accept_encoding
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Conjur API key of a user given the LDAP username and password via HTTP Basic Authentication.
#
# GET /authn-ldap/{service_id}/{account}/login
# Returns: string
# operationId: getAPIKeyViaLDAP
export def "get-api-key-via-ldap" [
  service_id: string
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> any {
  http-request {
    method: get
    path: "/authn-ldap/{service_id}/{account}/login"
    path_params: [{name: service_id, var: service_id}, {name: account, var: account}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["text/plain"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id, account: $account, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-lived access token for users and hosts using their LDAP identity to access the Conjur API.
#
# POST /authn-ldap/{service_id}/{account}/{login}/authenticate
# Returns: string
# operationId: getAccessTokenViaLDAP
export def "get-access-token-via-ldap" [
  service_id: string
  account: string
  login: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --accept-encoding: string@accept-encoding-completer # Setting the Accept-Encoding header to base64 will return a pre-encoded access token (default: application/json)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/authn-ldap/{service_id}/{account}/{login}/authenticate"
    path_params: [{name: service_id, var: service_id}, {name: account, var: account}, {name: login, var: login}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: Accept-Encoding, var: accept_encoding}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["text/plain"]
    ok: [200]
    auth: none
  } {
    service_id: $service_id, account: $account, login: $login, x_request_id: $x_request_id, accept_encoding: $accept_encoding, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-lived access token for applications using OpenID Connect (OIDC) to access the Conjur API.
#
# POST /authn-oidc/{service_id}/{account}/authenticate
# Returns: string
# operationId: getAccessTokenViaOIDC
export def "get-access-token-via-oidc" [
  service_id: string
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --id-token: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/authn-oidc/{service_id}/{account}/authenticate"
    path_params: [{name: service_id, var: service_id}, {name: account, var: account}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: id_token, var: id_token}]}
    accept: ["text/plain"]
    ok: [200]
    auth: none
  } {
    service_id: $service_id, account: $account, x_request_id: $x_request_id, id_token: $id_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rotates a role's API key.
#
# PUT /authn/{account}/api_key
# Returns: string
# operationId: rotateApiKey
export def "rotate-api-key" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-basicauth: string # Auth token for basicAuth (Authorization)
  --token-conjurauth: string # Auth token for conjurAuth (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string # (**Optional**) role specifier in `{kind}:{identifier}` format ##### Permissions required `update` privilege on the role whose API key is being rotated.
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> any {
  http-request {
    method: put
    path: "/authn/{account}/api_key"
    path_params: [{name: account, var: account}]
    query: [{name: role, var: role}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["text/plain"]
    ok: [200]
    auth_all: [{scheme: basic, var: token_basicauth, env: CONJUR_BASICAUTH_TOKEN}, {scheme: bearer, var: token_conjurauth, env: CONJUR_CONJURAUTH_TOKEN}]
  } {
    account: $account, role: $role, x_request_id: $x_request_id
    base_url: $base_url, token_basicauth: $token_basicauth, token_conjurauth: $token_conjurauth, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the API key of a user given the username and password via HTTP Basic Authentication.
#
# GET /authn/{account}/login
# Returns: string
# operationId: getAPIKey
export def "get-api-key" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> any {
  http-request {
    method: get
    path: "/authn/{account}/login"
    path_params: [{name: account, var: account}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["text/plain"]
    ok: [200]
    auth: basic
  } {
    account: $account, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes a user’s password.
#
# PUT /authn/{account}/password
# operationId: changePassword
export def "change-password" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/authn/{account}/password"
    path_params: [{name: account, var: account}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    account: $account, x_request_id: $x_request_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-lived access token, which is required in the header of most subsequent API requests.
#
# POST /authn/{account}/{login}/authenticate
# Returns: string
# operationId: getAccessToken
export def "get-access-token" [
  account: string
  login: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --accept-encoding: string@accept-encoding-completer # Setting the Accept-Encoding header to base64 will return a pre-encoded access token (default: application/json)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/authn/{account}/{login}/authenticate"
    path_params: [{name: account, var: account}, {name: login, var: login}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: Accept-Encoding, var: accept_encoding}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["text/plain"]
    ok: [200]
    auth: none
  } {
    account: $account, login: $login, x_request_id: $x_request_id, accept_encoding: $accept_encoding, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a signed certificate from the configured Certificate Authority service.
#
# POST /ca/{account}/{service_id}/sign
# Returns: record<certificate: string>
# operationId: sign
export def "sign" [
  account: string
  service_id: string
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
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --hdr-accept: string # Setting the Accept header to `application/x-pem-file` allows Conjur to respond with a formatted certificate (e.g. application/x-pem-file) (spec name: Accept)
  csr: string
  ttl: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ca/{account}/{service_id}/sign"
    path_params: [{name: account, var: account}, {name: service_id, var: service_id}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: Accept, var: hdr_accept}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: csr, var: csr}, {name: ttl, var: ttl}]}
    accept: ["application/json", "application/x-pem-file"]
    ok: [201]
    auth: bearer
  } {
    account: $account, service_id: $service_id, x_request_id: $x_request_id, hdr_accept: $hdr_accept, csr: $csr, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Health info about conjur
#
# GET /health
# Returns: record
# operationId: health
export def "health" [
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
    path: "/health"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Host using the Host Factory.
#
# POST /host_factories/hosts
# Returns: record<annotations: list<string>, api_key: string, created_at: string, id: string, owner: string, permissions: list<string>>
# operationId: createHost
export def "create-host" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --annotations: record # Annotations to apply to the new host (e.g. {description: new db host, puppet: true})
  id: string # Identifier of the host to be created. It will be created within the account of the host factory. (e.g. my-new-host)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/host_factories/hosts"
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: annotations, var: annotations}, {name: id, var: id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_request_id: $x_request_id, annotations: $annotations, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates one or more host identity tokens.
#
# POST /host_factory_tokens
# Returns: table<cidr: list<string>, expiration: string, token: string>
# operationId: createToken
export def "create-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --cidr: list<string> # Number of host tokens to create (e.g. [127.0.0.1/32])
  --count: int # Number of host tokens to create (e.g. 2)
  expiration: string # `ISO 8601 datetime` denoting a requested expiration time. (e.g. 2017-08-04T22:27:20+00:00)
  host_factory: string # Fully qualified host factory ID (e.g. myorg:host_factory:hf-db)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/host_factory_tokens"
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: cidr, var: cidr}, {name: count, var: count}, {name: expiration, var: expiration}, {name: host_factory, var: host_factory}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_request_id: $x_request_id, cidr: $cidr, count: $count, expiration: $expiration, host_factory: $host_factory
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revokes a token, immediately disabling it.
#
# DELETE /host_factory_tokens/{token}
# operationId: revokeToken
export def "revoke-token" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> any {
  http-request {
    method: delete
    path: "/host_factory_tokens/{token}"
    path_params: [{name: token, var: token_arg}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    token_arg: $token_arg, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Basic information about the Conjur Enterprise server
#
# GET /info
# Returns: record<authenticators: record<configured: list<string>, enabled: list<string>, installed: list<string>>, configuration: record, container: string, release: string, role: string, services: record, version: string>
# operationId: info
export def "info" [
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
    path: "/info"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies an existing Conjur policy.
#
# PATCH /policies/{account}/policy/{identifier}
# Returns: record<created_roles: record, version: float>
# operationId: updatePolicy
export def "update-policy" [
  account: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/policies/{account}/policy/{identifier}"
    path_params: [{name: account, var: account}, {name: identifier, var: identifier}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/x-yaml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account: $account, identifier: $identifier, x_request_id: $x_request_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds data to the existing Conjur policy.
#
# POST /policies/{account}/policy/{identifier}
# Returns: record<created_roles: record, version: float>
# operationId: loadPolicy
export def "load-policy" [
  account: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/policies/{account}/policy/{identifier}"
    path_params: [{name: account, var: account}, {name: identifier, var: identifier}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/x-yaml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account: $account, identifier: $identifier, x_request_id: $x_request_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Loads or replaces a Conjur policy document.
#
# PUT /policies/{account}/policy/{identifier}
# Returns: record<created_roles: record, version: float>
# operationId: replacePolicy
export def "replace-policy" [
  account: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/policies/{account}/policy/{identifier}"
    path_params: [{name: account, var: account}, {name: identifier, var: identifier}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/x-yaml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account: $account, identifier: $identifier, x_request_id: $x_request_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shows all public keys for a resource.
#
# GET /public_keys/{account}/{kind}/{identifier}
# Returns: string
# operationId: showPublicKeys
export def "show-public-keys" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> any {
  http-request {
    method: get
    path: "/public_keys/{account}/{kind}/{identifier}"
    path_params: [{name: account, var: account}, {name: kind, var: kind}, {name: identifier, var: identifier}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["text/plain"]
    ok: [200]
    auth: basic
  } {
    account: $account, kind: $kind, identifier: $identifier, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Health info about a given Conjur Enterprise server
#
# GET /remote_health/{remote}
# Returns: record
# operationId: remoteHealth
export def "remote-health" [
  remote: string
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
    path: "/remote_health/{remote}"
    path_params: [{name: remote, var: remote}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    remote: $remote
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists resources within an organization account.
#
# GET /resources
# Returns: table<annotations: list<string>, created_at: string, id: string, owner: string, permissions: list<record>, policy: string, policy_versions: list<record>, restricted_to: list<string>, secrets: list<record>>
# operationId: showResourcesForAllAccounts
export def "show-resources-for-all-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account: string # Organization account name (e.g. default)
  --kind: string # Type of resource (e.g. variable)
  --search: string # Filter resources based on this value by name (e.g. password)
  --offset: int # When listing resources, start at this item number. (e.g. 20)
  --limit: int # When listing resources, return up to this many results. (e.g. 10)
  --count: oneof<nothing, bool> # When listing resources, if `true`, return only the count of the results. (e.g. true)
  --role: string # Retrieves the resources list for a different role if the authenticated role has access (e.g. myorg:host:host1)
  --acting-as: string # Retrieves the resources list for a different role if the authenticated role has access (e.g. myorg:host:host1)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/resources"
    query: [{name: account, var: account}, {name: kind, var: kind}, {name: search, var: search}, {name: offset, var: offset}, {name: limit, var: limit}, {name: count, var: count}, {name: role, var: role}, {name: acting_as, var: acting_as}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account: $account, kind: $kind, search: $search, offset: $offset, limit: $limit, count: $count, role: $role, acting_as: $acting_as, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists resources within an organization account.
#
# GET /resources/{account}
# Returns: table<annotations: list<string>, created_at: string, id: string, owner: string, permissions: list<record>, policy: string, policy_versions: list<record>, restricted_to: list<string>, secrets: list<record>>
# operationId: showResourcesForAccount
export def "show-resources-for-account" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kind: string # Type of resource (e.g. variable)
  --search: string # Filter resources based on this value by name (e.g. password)
  --offset: int # When listing resources, start at this item number. (e.g. 20)
  --limit: int # When listing resources, return up to this many results. (e.g. 10)
  --count: oneof<nothing, bool> # When listing resources, if `true`, return only the count of the results. (e.g. true)
  --role: string # Retrieves the resources list for a different role if the authenticated role has access (e.g. myorg:host:host1)
  --acting-as: string # Retrieves the resources list for a different role if the authenticated role has access (e.g. myorg:host:host1)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/resources/{account}"
    path_params: [{name: account, var: account}]
    query: [{name: kind, var: kind}, {name: search, var: search}, {name: offset, var: offset}, {name: limit, var: limit}, {name: count, var: count}, {name: role, var: role}, {name: acting_as, var: acting_as}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account: $account, kind: $kind, search: $search, offset: $offset, limit: $limit, count: $count, role: $role, acting_as: $acting_as, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists resources of the same kind within an organization account.
#
# GET /resources/{account}/{kind}
# Returns: table<annotations: list<string>, created_at: string, id: string, owner: string, permissions: list<record>, policy: string, policy_versions: list<record>, restricted_to: list<string>, secrets: list<record>>
# operationId: showResourcesForKind
export def "show-resources-for-kind" [
  account: string
  kind: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter resources based on this value by name (e.g. password)
  --offset: int # When listing resources, start at this item number. (e.g. 20)
  --limit: int # When listing resources, return up to this many results. (e.g. 10)
  --count: oneof<nothing, bool> # When listing resources, if `true`, return only the count of the results. (e.g. true)
  --role: string # Retrieves the resources list for a different role if the authenticated role has access (e.g. myorg:host:host1)
  --acting-as: string # Retrieves the resources list for a different role if the authenticated role has access (e.g. myorg:host:host1)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/resources/{account}/{kind}"
    path_params: [{name: account, var: account}, {name: kind, var: kind}]
    query: [{name: search, var: search}, {name: offset, var: offset}, {name: limit, var: limit}, {name: count, var: count}, {name: role, var: role}, {name: acting_as, var: acting_as}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account: $account, kind: $kind, search: $search, offset: $offset, limit: $limit, count: $count, role: $role, acting_as: $acting_as, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shows a description of a single resource.
#
# GET /resources/{account}/{kind}/{identifier}
# Returns: record<annotations: list<string>, created_at: string, id: string, owner: string, permissions: table<policy: string, privilege: string, role: string>, policy: string, policy_versions: table<client_ip: string, created_at: string, finished_at: string, id: string, policy_sha256: string, policy_text: string, role: string, version: float>, restricted_to: list<string>, secrets: table<expires_at: string, version: float>>
# operationId: showResource
export def "show-resource" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --permitted-roles: oneof<nothing, bool> # Lists the roles which have the named privilege on a resource. (e.g. true)
  --privilege: string # Level of privilege to filter on. Can only be used in combination with `permitted_roles` or `check` parameter. (e.g. execute)
  --check: oneof<nothing, bool> # Check whether a role has a privilege on a resource. (e.g. true)
  --role: string # Role to check privilege on. Can only be used in combination with `check` parameter. (e.g. myorg:host:host1)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/resources/{account}/{kind}/{identifier}"
    path_params: [{name: account, var: account}, {name: kind, var: kind}, {name: identifier, var: identifier}]
    query: [{name: permitted_roles, var: permitted_roles}, {name: privilege, var: privilege}, {name: check, var: check}, {name: role, var: role}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    account: $account, kind: $kind, identifier: $identifier, permitted_roles: $permitted_roles, privilege: $privilege, check: $check, role: $role, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing role membership
#
# DELETE /roles/{account}/{kind}/{identifier}
# operationId: removeMemberFromRole
export def "remove-member-from-role" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --members: string # Returns a list of the Role's members. (required)
  --member: string # The identifier of the Role to be added as a member. (required)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> any {
  http-request {
    method: delete
    path: "/roles/{account}/{kind}/{identifier}"
    path_params: [{name: account, var: account}, {name: kind, var: kind}, {name: identifier, var: identifier}]
    query: [{name: members, var: members, required: true}, {name: member, var: member, required: true}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account: $account, kind: $kind, identifier: $identifier, members: $members, member: $member, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get role information
#
# GET /roles/{account}/{kind}/{identifier}
# Returns: record
# operationId: showRole
export def "show-role" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: string # Returns an array of Role IDs representing all role memberships, expanded recursively.
  --memberships: string # Returns all direct role memberships (members not expanded recursively).
  --members: string # Returns a list of the Role's members.
  --offset: int # When listing members, start at this item number. (e.g. 20)
  --limit: int # When listing members, return up to this many results. (e.g. 10)
  --count: oneof<nothing, bool> # When listing members, if `true`, return only the count of members. (e.g. true)
  --search: string # When listing members, the results will be narrowed to only those matching the provided string (e.g. user)
  --graph: string # If included in the query returns a graph view of the role (e.g. )
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/roles/{account}/{kind}/{identifier}"
    path_params: [{name: account, var: account}, {name: kind, var: kind}, {name: identifier, var: identifier}]
    query: [{name: all, var: all}, {name: memberships, var: memberships}, {name: members, var: members}, {name: offset, var: offset}, {name: limit, var: limit}, {name: count, var: count}, {name: search, var: search}, {name: graph, var: graph}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account: $account, kind: $kind, identifier: $identifier, all: $all, memberships: $memberships, members: $members, offset: $offset, limit: $limit, count: $count, search: $search, graph: $graph, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update or modify an existing role membership
#
# POST /roles/{account}/{kind}/{identifier}
# operationId: addMemberToRole
export def "add-member-to-role" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --members: string # Returns a list of the Role's members. (required)
  --member: string # The identifier of the Role to be added as a member. (required)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> any {
  http-request {
    method: post
    path: "/roles/{account}/{kind}/{identifier}"
    path_params: [{name: account, var: account}, {name: kind, var: kind}, {name: identifier, var: identifier}]
    query: [{name: members, var: members, required: true}, {name: member, var: member, required: true}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account: $account, kind: $kind, identifier: $identifier, members: $members, member: $member, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch multiple secrets
#
# GET /secrets
# Returns: record
# operationId: getSecrets
export def "get-secrets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --variable-ids: string # Comma-delimited, URL-encoded resource IDs of the variables. (required, e.g. myorg:variable:secret1,myorg:variable:secret1)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --accept-encoding: string@accept-encoding-completer-1 # Set the encoding of the response object
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/secrets"
    query: [{name: variable_ids, var: variable_ids, required: true}]
    header: [{name: X-Request-Id, var: x_request_id}, {name: Accept-Encoding, var: accept_encoding}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    variable_ids: $variable_ids, x_request_id: $x_request_id, accept_encoding: $accept_encoding
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the value of a secret from the specified Secret.
#
# GET /secrets/{account}/{kind}/{identifier}
# Returns: string
# operationId: getSecret
export def "get-secret" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int # (**Optional**) Version you want to retrieve (Conjur keeps the last 20 versions of a secret) (e.g. 1)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> any {
  http-request {
    method: get
    path: "/secrets/{account}/{kind}/{identifier}"
    path_params: [{name: account, var: account}, {name: kind, var: kind}, {name: identifier, var: identifier}]
    query: [{name: version, var: version}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    account: $account, kind: $kind, identifier: $identifier, version: $version, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a secret value within the specified variable.
#
# POST /secrets/{account}/{kind}/{identifier}
# operationId: createSecret
export def "create-secret" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expirations: string # Tells the server to reset the variables expiration date
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/secrets/{account}/{kind}/{identifier}"
    path_params: [{name: account, var: account}, {name: kind, var: kind}, {name: identifier, var: identifier}]
    query: [{name: expirations, var: expirations}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account: $account, kind: $kind, identifier: $identifier, expirations: $expirations, x_request_id: $x_request_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides information about the client making an API request.
#
# GET /whoami
# Returns: record<account: string, client_ip: string, token_issued_at: string, user_agent: string, username: string>
# operationId: whoAmI
export def "who-am-i" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/whoami"
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables or disables authenticator defined without service_id.
#
# PATCH /{authenticator}/{account}
# operationId: enableAuthenticator
export def "enable-authenticator" [
  authenticator: string@authenticator-completer
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --enabled: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: patch
    path: "/{authenticator}/{account}"
    path_params: [{name: authenticator, var: authenticator}, {name: account, var: account}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    authenticator: $authenticator, account: $account, x_request_id: $x_request_id, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables or disables authenticator service instances.
#
# PATCH /{authenticator}/{service_id}/{account}
# operationId: enableAuthenticatorInstance
export def "enable-authenticator-instance" [
  authenticator: string@authenticator-completer
  service_id: string
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --enabled: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: patch
    path: "/{authenticator}/{service_id}/{account}"
    path_params: [{name: authenticator, var: authenticator}, {name: service_id, var: service_id}, {name: account, var: account}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    authenticator: $authenticator, service_id: $service_id, account: $account, x_request_id: $x_request_id, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Details whether an authentication service has been configured properly
#
# GET /{authenticator}/{service_id}/{account}/status
# Returns: record<error: string, status: string>
# operationId: getServiceAuthenticatorStatus
export def "get-service-authenticator-status" [
  authenticator: string
  service_id: string
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{authenticator}/{service_id}/{account}/status"
    path_params: [{name: authenticator, var: authenticator}, {name: service_id, var: service_id}, {name: account, var: account}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authenticator: $authenticator, service_id: $service_id, account: $account, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
