# Auto-generated client for Neutrino API v3.6.3
# Source: https://api.apis.guru/v2/specs/neutrinoapi.net/3.6.3/openapi.json
# Auth (api-key): --token-apikey flag or $env.NEUTRINO_API_APIKEY_TOKEN
# Auth (user-id): --token-userid flag or $env.NEUTRINO_API_USERID_TOKEN

const CLIENT = {
  base_url: "https://neutrinoapi.net"
  token_env_var: "NEUTRINO_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: api-key, in: header, header_name: api-key, prefix: ""}
    {name: user-id, in: header, header_name: user-id, prefix: ""}
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

def base-url-completer [] { ["https://neutrinoapi.net"] }
def auth-scheme-completer [] { ["api-key" "user-id"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help" "token-apikey" "token-userid"]
  let return_types = {
    bad-word-filter: "record<bad-words-list: list<string>, bad-words-total: int, censored-content: string, is-bad: bool>"
    bin-list-download: "binary"
    bin-lookup: "record<bin-number: string, card-brand: string, card-category: string, card-type: string, country: string, country-code: string, country-code3: string, currency-code: string, ip-blocklisted: bool, ip-blocklists: list<string>, ip-city: string, ip-country: string, ip-country-code: string, ip-country-code3: string, ip-matches-bin: bool, ip-region: string, is-commercial: bool, is-prepaid: bool, issuer: string, issuer-phone: string, issuer-website: string, valid: bool>"
    browser-bot: "record<content: string, elements: list<string>, error-message: string, exec-results: list<string>, http-redirect-url: string, http-status-code: int, http-status-message: string, is-error: bool, is-http-ok: bool, is-http-redirect: bool, is-secure: bool, is-timeout: bool, language-code: string, load-time: float, mime-type: string, response-headers: record, security-details: record, server-ip: string, title: string, url: string>"
    convert: "record<from-type: string, from-value: string, result: string, result-float: float, to-type: string, valid: bool>"
    email-validate: "record<domain: string, domain-error: bool, email: string, is-disposable: bool, is-freemail: bool, is-personal: bool, provider: string, syntax-error: bool, typos-fixed: bool, valid: bool>"
    email-verify: "record<domain: string, domain-error: bool, email: string, is-catch-all: bool, is-deferred: bool, is-disposable: bool, is-freemail: bool, is-personal: bool, provider: string, smtp-response: string, smtp-status: string, syntax-error: bool, typos-fixed: bool, valid: bool, verified: bool>"
    geocode-address: "record<found: int, locations: table<address: string, address-components: record, city: string, country: string, country-code: string, country-code3: string, currency-code: string, latitude: float, location-tags: list, location-type: string, longitude: float, postal-address: string, postal-code: string, region-code: string, state: string, timezone: record>>"
    geocode-reverse: "record<address: string, address-components: record, city: string, country: string, country-code: string, country-code3: string, currency-code: string, found: bool, latitude: float, location-tags: list<string>, location-type: string, longitude: float, postal-address: string, postal-code: string, region-code: string, state: string, timezone: record>"
    hlr-lookup: "record<country: string, country-code: string, country-code3: string, currency-code: string, current-network: string, hlr-status: string, hlr-valid: bool, imsi: string, international-calling-code: string, international-number: string, is-mobile: bool, is-ported: bool, is-roaming: bool, local-number: string, location: string, mcc: string, mnc: string, msc: string, msin: string, number-type: string, number-valid: bool, origin-network: string, ported-network: string, roaming-country-code: string>"
    host-reputation: "record<host: string, is-listed: bool, list-count: int, lists: table<is-listed: bool, list-host: string, list-name: string, list-rating: int, response-time: int, return-code: string, txt-record: string>>"
    html-clean: "binary"
    html-render: "binary"
    image-resize: "binary"
    image-watermark: "binary"
    ip-blocklist: "record<blocklists: list<string>, cidr: string, ip: string, is-bot: bool, is-dshield: bool, is-exploit-bot: bool, is-hijacked: bool, is-listed: bool, is-malware: bool, is-proxy: bool, is-spam-bot: bool, is-spider: bool, is-spyware: bool, is-tor: bool, is-vpn: bool, last-seen: int, list-count: int, sensors: table<blocklist: string, description: string, id: int>>"
    ip-blocklist-download: "binary"
    ip-info: "record<city: string, continent-code: string, country: string, country-code: string, country-code3: string, currency-code: string, host-domain: string, hostname: string, ip: string, is-bogon: bool, is-v4-mapped: bool, is-v6: bool, latitude: float, longitude: float, region: string, region-code: string, timezone: record, valid: bool>"
    ip-probe: "record<as-age: int, as-cidr: string, as-country-code: string, as-country-code3: string, as-description: string, as-domains: list<string>, asn: string, city: string, continent-code: string, country: string, country-code: string, country-code3: string, currency-code: string, host-domain: string, hostname: string, ip: string, is-bogon: bool, is-hosting: bool, is-isp: bool, is-proxy: bool, is-v4-mapped: bool, is-v6: bool, is-vpn: bool, provider-description: string, provider-domain: string, provider-type: string, provider-website: string, region: string, region-code: string, valid: bool, vpn-domain: string>"
    phone-playback: "record<calling: bool, number-valid: bool>"
    phone-validate: "record<country: string, country-code: string, country-code3: string, currency-code: string, international-calling-code: string, international-number: string, is-mobile: bool, local-number: string, location: string, prefix-network: string, type: string, valid: bool>"
    phone-verify: "record<calling: bool, number-valid: bool, security-code: string>"
    qr-code: "binary"
    sms-verify: "record<number-valid: bool, security-code: string, sent: bool>"
    ua-lookup: "record<browser-engine: string, browser-release: string, device-brand: string, device-height-px: float, device-model: string, device-model-code: string, device-pixel-ratio: float, device-ppi: float, device-price: float, device-release: string, device-resolution: string, device-width-px: float, is-mobile: bool, is-webview: bool, name: string, os: string, os-family: string, os-version: string, os-version-major: string, type: string, ua: string, version: string, version-major: string>"
    url-info: "record<content: string, content-encoding: string, content-size: int, content-type: string, http-ok: bool, http-redirect: bool, http-status: int, http-status-message: int, is-error: bool, is-timeout: bool, language-code: string, load-time: float, query: record, real: bool, server-city: string, server-country: string, server-country-code: string, server-hostname: string, server-ip: string, server-name: string, server-region: string, title: string, url: string, url-path: string, url-port: int, url-protocol: string, valid: bool>"
    verify-security-code: "record<verified: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["bad-word-filter" "bin-list-download" "bin-lookup" "browser-bot" "convert" "email-validate" "email-verify" "geocode-address" "geocode-reverse" "hlr-lookup" "host-reputation" "html-clean" "html-render" "image-resize" "image-watermark" "ip-blocklist" "ip-blocklist-download" "ip-info" "ip-probe" "phone-playback" "phone-validate" "phone-verify" "qr-code" "sms-verify" "ua-lookup" "url-info" "verify-security-code" "commands"] | sort) } | get name | first)
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

# Bad Word Filter
#
# POST /bad-word-filter
# Returns: record<bad-words-list: list<string>, bad-words-total: int, censored-content: string, is-bad: bool>
# operationId: BadWordFilter
export def "bad-word-filter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalog: string # Which catalog of bad words to use, we currently maintain two bad word catalogs: strict - the largest database of bad words which includes profanity, obscenity, sexual, rude, cuss, dirty, swear and objectionable words and phrases. This catalog is suitable for environments of all ages including educational or children's content obscene - like the strict catalog but does not include any mild profanities, idiomatic phrases or words which are considered formal terminology. This catalog is suitable for adult environments where certain types of bad words are considered OK (default: strict)
  --censor-character: string # The character to use to censor out the bad words found
  content: string # The content to scan. This can be either a URL to load from, a file upload (multipart/form-data) or an HTML content string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bad-word-filter"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: catalog, var: catalog}, {name: censor-character, var: censor_character}, {name: content, var: content}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    catalog: $catalog, censor_character: $censor_character, content: $content
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# BIN List Download
#
# GET /bin-list-download
# Returns: binary
# operationId: BINListDownload
export def "bin-list-download" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-iso3: oneof<nothing, bool> # Include ISO 3-letter country codes and ISO 3-letter currency codes in the data. These will be added to columns 10 and 11 respectively (default: false)
  --include-8digit: oneof<nothing, bool> # Include 8-digit and higher BIN codes. This option includes all 6-digit BINs and all 8-digit and higher BINs (including some 9, 10 and 11 digit BINs where available) (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/bin-list-download"
    query: [{name: include-iso3, var: include_iso3}, {name: include-8digit, var: include_8digit}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    include_iso3: $include_iso3, include_8digit: $include_8digit
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# BIN Lookup
#
# GET /bin-lookup
# Returns: record<bin-number: string, card-brand: string, card-category: string, card-type: string, country: string, country-code: string, country-code3: string, currency-code: string, ip-blocklisted: bool, ip-blocklists: list<string>, ip-city: string, ip-country: string, ip-country-code: string, ip-country-code3: string, ip-matches-bin: bool, ip-region: string, is-commercial: bool, is-prepaid: bool, issuer: string, issuer-phone: string, issuer-website: string, valid: bool>
# operationId: BINLookup
export def "bin-lookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bin-number: string # The BIN or IIN number. This is the first 6, 8 or 10 digits of a card number, use 8 (or more) digits for the highest level of accuracy (required)
  --customer-ip: string # Pass in the customers IP address and we will return some extra information about them
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bin-lookup"
    query: [{name: bin-number, var: bin_number, required: true}, {name: customer-ip, var: customer_ip}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    bin_number: $bin_number, customer_ip: $customer_ip
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Browser Bot
#
# POST /browser-bot
# Returns: record<content: string, elements: list<string>, error-message: string, exec-results: list<string>, http-redirect-url: string, http-status-code: int, http-status-message: string, is-error: bool, is-http-ok: bool, is-http-redirect: bool, is-secure: bool, is-timeout: bool, language-code: string, load-time: float, mime-type: string, response-headers: record, security-details: record, server-ip: string, title: string, url: string>
# operationId: BrowserBot
export def "browser-bot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delay: int # Delay in seconds to wait before capturing any page data, executing selectors or JavaScript (format: int32, default: 3)
  --exec: list<string> # Execute JavaScript on the website. This parameter accepts JavaScript as either a string containing JavaScript or for sending multiple separate statements a JSON array or POST array can also be used. If a statement returns any value it will be returned in the 'exec-results' response. You can also use the following specially defined user interaction functions: sleep(seconds); Just wait/sleep for the specified number of seconds. click('selector'); Click on the first element matching the given selector. focus('selector'); Focus on the first element matching the given selector. keys('characters'); Send the specified keyboard characters. Use click() or focus() first to send keys to a specific element. enter(); Send the Enter key. tab(); Send the Tab key. (default: [])
  --ignore-certificate-errors: oneof<nothing, bool> # Ignore any TLS/SSL certificate errors and load the page anyway (default: false)
  --selector: string # Extract content from the page DOM using this selector. Commonly known as a CSS selector, you can find a good reference here (https://www.w3schools.com/cssref/css_selectors.asp)
  --timeout: int # Timeout in seconds. Give up if still trying to load the page after this number of seconds (format: int32, default: 30)
  url: string # The URL to load
  --user-agent: string # Override the browsers default user-agent string with this one
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/browser-bot"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: delay, var: delay}, {name: exec, var: exec}, {name: ignore-certificate-errors, var: ignore_certificate_errors}, {name: selector, var: selector}, {name: timeout, var: timeout}, {name: url, var: url}, {name: user-agent, var: user_agent}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    delay: $delay, exec: $exec, ignore_certificate_errors: $ignore_certificate_errors, selector: $selector, timeout: $timeout, url: $url, user_agent: $user_agent
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Convert
#
# GET /convert
# Returns: record<from-type: string, from-value: string, result: string, result-float: float, to-type: string, valid: bool>
# operationId: Convert
export def "convert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-value: string # The value to convert from (e.g. 10.95) (required)
  --from-type: string # The type of the value to convert from (e.g. USD) (required)
  --to-type: string # The type to convert to (e.g. EUR) (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/convert"
    query: [{name: from-value, var: from_value, required: true}, {name: from-type, var: from_type, required: true}, {name: to-type, var: to_type, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    from_value: $from_value, from_type: $from_type, to_type: $to_type
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Email Validate
#
# GET /email-validate
# Returns: record<domain: string, domain-error: bool, email: string, is-disposable: bool, is-freemail: bool, is-personal: bool, provider: string, syntax-error: bool, typos-fixed: bool, valid: bool>
# operationId: EmailValidate
export def "email-validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # An email address (required)
  --fix-typos: oneof<nothing, bool> # Automatically attempt to fix typos in the address (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/email-validate"
    query: [{name: email, var: email, required: true}, {name: fix-typos, var: fix_typos}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    email: $email, fix_typos: $fix_typos
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Email Verify
#
# GET /email-verify
# Returns: record<domain: string, domain-error: bool, email: string, is-catch-all: bool, is-deferred: bool, is-disposable: bool, is-freemail: bool, is-personal: bool, provider: string, smtp-response: string, smtp-status: string, syntax-error: bool, typos-fixed: bool, valid: bool, verified: bool>
# operationId: EmailVerify
export def "email-verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # An email address (required)
  --fix-typos: oneof<nothing, bool> # Automatically attempt to fix typos in the address (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/email-verify"
    query: [{name: email, var: email, required: true}, {name: fix-typos, var: fix_typos}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    email: $email, fix_typos: $fix_typos
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Geocode Address
#
# GET /geocode-address
# Returns: record<found: int, locations: table<address: string, address-components: record, city: string, country: string, country-code: string, country-code3: string, currency-code: string, latitude: float, location-tags: list, location-type: string, longitude: float, postal-address: string, postal-code: string, region-code: string, state: string, timezone: record>>
# operationId: GeocodeAddress
export def "geocode-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # The full address, partial address or name of a place to try and locate. Comma separated address components are preferred.
  --house-number: string # The house/building number to locate
  --street: string # The street/road name to locate
  --city: string # The city/town name to locate
  --county: string # The county/region name to locate
  --state: string # The state name to locate
  --postal-code: string # The postal code to locate
  --country-code: string # Limit result to this country (the default is no country bias)
  --language-code: string # The language to display results in, available languages are: de, en, es, fr, it, pt, ru, zh (default: en)
  --fuzzy-search: oneof<nothing, bool> # If no matches are found for the given address, start performing a recursive fuzzy search until a geolocation is found. This option is recommended for processing user input or implementing auto-complete. We use a combination of approximate string matching and data cleansing to find possible location matches (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geocode-address"
    query: [{name: address, var: address}, {name: house-number, var: house_number}, {name: street, var: street}, {name: city, var: city}, {name: county, var: county}, {name: state, var: state}, {name: postal-code, var: postal_code}, {name: country-code, var: country_code}, {name: language-code, var: language_code}, {name: fuzzy-search, var: fuzzy_search}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    address: $address, house_number: $house_number, street: $street, city: $city, county: $county, state: $state, postal_code: $postal_code, country_code: $country_code, language_code: $language_code, fuzzy_search: $fuzzy_search
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Geocode Reverse
#
# GET /geocode-reverse
# Returns: record<address: string, address-components: record, city: string, country: string, country-code: string, country-code3: string, currency-code: string, found: bool, latitude: float, location-tags: list<string>, location-type: string, longitude: float, postal-address: string, postal-code: string, region-code: string, state: string, timezone: record>
# operationId: GeocodeReverse
export def "geocode-reverse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --latitude: string # The location latitude in decimal degrees format (required)
  --longitude: string # The location longitude in decimal degrees format (required)
  --language-code: string # The language to display results in, available languages are: de, en, es, fr, it, pt, ru (default: en)
  --zoom: string # The zoom level to respond with: address - the most precise address available street - the street level city - the city level state - the state level country - the country level (default: address)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geocode-reverse"
    query: [{name: latitude, var: latitude, required: true}, {name: longitude, var: longitude, required: true}, {name: language-code, var: language_code}, {name: zoom, var: zoom}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    latitude: $latitude, longitude: $longitude, language_code: $language_code, zoom: $zoom
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# HLR Lookup
#
# GET /hlr-lookup
# Returns: record<country: string, country-code: string, country-code3: string, currency-code: string, current-network: string, hlr-status: string, hlr-valid: bool, imsi: string, international-calling-code: string, international-number: string, is-mobile: bool, is-ported: bool, is-roaming: bool, local-number: string, location: string, mcc: string, mnc: string, msc: string, msin: string, number-type: string, number-valid: bool, origin-network: string, ported-network: string, roaming-country-code: string>
# operationId: HLRLookup
export def "hlr-lookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: string # A phone number (required)
  --country-code: string # ISO 2-letter country code, assume numbers are based in this country. If not set numbers are assumed to be in international format (with or without the leading + sign)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/hlr-lookup"
    query: [{name: number, var: number, required: true}, {name: country-code, var: country_code}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    number: $number, country_code: $country_code
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Host Reputation
#
# GET /host-reputation
# Returns: record<host: string, is-listed: bool, list-count: int, lists: table<is-listed: bool, list-host: string, list-name: string, list-rating: int, response-time: int, return-code: string, txt-record: string>>
# operationId: HostReputation
export def "host-reputation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --host: string # An IP address, domain name, FQDN or URL. If you supply a domain/URL it will be checked against the URI DNSBL lists (required)
  --list-rating: int # Only check lists with this rating or better (format: int32, default: 3)
  --zones: string # Only check these DNSBL zones/hosts. Multiple zones can be supplied as comma-separated values
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/host-reputation"
    query: [{name: host, var: host, required: true}, {name: list-rating, var: list_rating}, {name: zones, var: zones}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    host: $host, list_rating: $list_rating, zones: $zones
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# HTML Clean
#
# POST /html-clean
# Returns: binary
# operationId: HTMLClean
export def "html-clean" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string # The HTML content. This can be either a URL to load from, a file upload (multipart/form-data) or an HTML content string
  output_type: string # The level of sanitization, possible values are: plain-text: reduce the content to plain text only (no HTML tags at all) simple-text: allow only very basic text formatting tags like b, em, i, strong, u basic-html: allow advanced text formatting and hyper links basic-html-with-images: same as basic html but also allows image tags advanced-html: same as basic html with images but also allows many more common HTML tags like table, ul, dl, pre
]: any -> any {
  $in | http-request {
    method: post
    path: "/html-clean"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: content, var: content}, {name: output-type, var: output_type}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    content: $content, output_type: $output_type
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# HTML Render
#
# POST /html-render
# Returns: binary
# operationId: HTMLRender
export def "html-render" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string # The HTML content. This can be either a URL to load from, a file upload (multipart/form-data) or an HTML content string
  --css: string # Inject custom CSS into the HTML. e.g. 'body { background-color: red;}'
  --delay: int # Number of seconds to wait before rendering the page (can be useful for pages with animations etc) (format: int32, default: 0)
  --footer: string # The footer HTML to insert into each page. The following dynamic tags are supported: {date}, {title}, {url}, {pageNumber}, {totalPages}
  --format: string # Which format to output, available options are: PDF, PNG, JPG (default: PDF)
  --grayscale: oneof<nothing, bool> # Render the final document in grayscale (default: false)
  --header: string # The header HTML to insert into each page. The following dynamic tags are supported: {date}, {title}, {url}, {pageNumber}, {totalPages}
  --ignore-certificate-errors: oneof<nothing, bool> # Ignore any TLS/SSL certificate errors (default: false)
  --image-height: int # If rendering to an image format (PNG or JPG) use this image height (in pixels). The default is automatic which dynamically sets the image height based on the content (format: int32)
  --image-width: int # If rendering to an image format (PNG or JPG) use this image width (in pixels) (format: int32, default: 1024)
  --landscape: oneof<nothing, bool> # Set the document to landscape orientation (default: false)
  --margin: float # The document margin (in mm) (format: double, default: 0)
  --margin-bottom: float # The document bottom margin (in mm) (format: double, default: 0)
  --margin-left: float # The document left margin (in mm) (format: double, default: 0)
  --margin-right: float # The document right margin (in mm) (format: double, default: 0)
  --margin-top: float # The document top margin (in mm) (format: double, default: 0)
  --page-height: float # Set the PDF page height explicitly (in mm) (format: double)
  --page-size: string # Set the document page size, can be one of: A0 - A9, B0 - B10, Comm10E, DLE or Letter (default: A4)
  --page-width: float # Set the PDF page width explicitly (in mm) (format: double)
  --timeout: int # Timeout in seconds. Give up if still trying to load the HTML content after this number of seconds (format: int32, default: 300)
  --title: string # The document title
  --zoom: float # Set the zoom factor when rendering the page (2.0 for double size, 0.5 for half size) (format: double, default: 1)
]: any -> any {
  $in | http-request {
    method: post
    path: "/html-render"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: content, var: content}, {name: css, var: css}, {name: delay, var: delay}, {name: footer, var: footer}, {name: format, var: format}, {name: grayscale, var: grayscale}, {name: header, var: header}, {name: ignore-certificate-errors, var: ignore_certificate_errors}, {name: image-height, var: image_height}, {name: image-width, var: image_width}, {name: landscape, var: landscape}, {name: margin, var: margin}, {name: margin-bottom, var: margin_bottom}, {name: margin-left, var: margin_left}, {name: margin-right, var: margin_right}, {name: margin-top, var: margin_top}, {name: page-height, var: page_height}, {name: page-size, var: page_size}, {name: page-width, var: page_width}, {name: timeout, var: timeout}, {name: title, var: title}, {name: zoom, var: zoom}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    content: $content, css: $css, delay: $delay, footer: $footer, format: $format, grayscale: $grayscale, header: $header, ignore_certificate_errors: $ignore_certificate_errors, image_height: $image_height, image_width: $image_width, landscape: $landscape, margin: $margin, margin_bottom: $margin_bottom, margin_left: $margin_left, margin_right: $margin_right, margin_top: $margin_top, page_height: $page_height, page_size: $page_size, page_width: $page_width, timeout: $timeout, title: $title, zoom: $zoom
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Image Resize
#
# POST /image-resize
# Returns: binary
# operationId: ImageResize
export def "image-resize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bg-color: string # The image background color in hexadecimal notation (e.g. #0000ff). For PNG output the special value of 'transparent' can also be used. For JPG output the default is black (#000000) (default: transparent)
  --format: string # The output image format, can be either png or jpg (default: png)
  --height: int # The height to resize to (in px). If you don't set this field then the height will be automatic based on the requested width and image aspect ratio (format: int32)
  image_url: string # The URL or Base64 encoded Data URL for the source image. You can also upload an image file directly using multipart/form-data
  --resize-mode: string # The resize mode to use, we support 3 main resizing modes: scaleResize to within the width and height specified while preserving aspect ratio. In this mode the width or height will be automatically adjusted to fit the aspect ratio padResize to exactly the width and height specified while preserving aspect ratio and pad any space left over. Any padded space will be filled in with the 'bg-color' value cropResize to exactly the width and height specified while preserving aspect ratio and crop any space which fall outside the area. The cropping window is centered on the original image (default: scale)
  width: int # The width to resize to (in px) (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/image-resize"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: bg-color, var: bg_color}, {name: format, var: format}, {name: height, var: height}, {name: image-url, var: image_url}, {name: resize-mode, var: resize_mode}, {name: width, var: width}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    bg_color: $bg_color, format: $format, height: $height, image_url: $image_url, resize_mode: $resize_mode, width: $width
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Image Watermark
#
# POST /image-watermark
# Returns: binary
# operationId: ImageWatermark
export def "image-watermark" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bg-color: string # The image background color in hexadecimal notation (e.g. #0000ff). For PNG output the special value of 'transparent' can also be used. For JPG output the default is black (#000000) (default: transparent)
  --format: string # The output image format, can be either png or jpg (default: png)
  --height: int # If set resize the resulting image to this height (in px) (format: int32)
  image_url: string # The URL or Base64 encoded Data URL for the source image. You can also upload an image file directly using multipart/form-data
  --opacity: int # The opacity of the watermark (0 to 100) (format: int32, default: 50)
  --position: string # The position of the watermark image, possible values are: center, top-left, top-center, top-right, bottom-left, bottom-center, bottom-right (default: center)
  --resize-mode: string # The resize mode to use, we support 3 main resizing modes: scaleResize to within the width and height specified while preserving aspect ratio. In this mode the width or height will be automatically adjusted to fit the aspect ratio padResize to exactly the width and height specified while preserving aspect ratio and pad any space left over. Any padded space will be filled in with the 'bg-color' value cropResize to exactly the width and height specified while preserving aspect ratio and crop any space which fall outside the area. The cropping window is centered on the original image (default: scale)
  watermark_url: string # The URL or Base64 encoded Data URL for the watermark image. You can also upload an image file directly using multipart/form-data
  --width: int # If set resize the resulting image to this width (in px) (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/image-watermark"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: bg-color, var: bg_color}, {name: format, var: format}, {name: height, var: height}, {name: image-url, var: image_url}, {name: opacity, var: opacity}, {name: position, var: position}, {name: resize-mode, var: resize_mode}, {name: watermark-url, var: watermark_url}, {name: width, var: width}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    bg_color: $bg_color, format: $format, height: $height, image_url: $image_url, opacity: $opacity, position: $position, resize_mode: $resize_mode, watermark_url: $watermark_url, width: $width
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IP Blocklist
#
# GET /ip-blocklist
# Returns: record<blocklists: list<string>, cidr: string, ip: string, is-bot: bool, is-dshield: bool, is-exploit-bot: bool, is-hijacked: bool, is-listed: bool, is-malware: bool, is-proxy: bool, is-spam-bot: bool, is-spider: bool, is-spyware: bool, is-tor: bool, is-vpn: bool, last-seen: int, list-count: int, sensors: table<blocklist: string, description: string, id: int>>
# operationId: IPBlocklist
export def "ip-blocklist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip: string # An IPv4 or IPv6 address. Accepts standard IP notation (with or without port number), CIDR notation and IPv6 compressed notation. If multiple IPs are passed using comma-separated values the first non-bogon address on the list will be checked (required)
  --vpn-lookup: oneof<nothing, bool> # Include public VPN provider IP addresses. NOTE: For more advanced VPN detection including the ability to identify private and stealth VPNs use the IP Probe API (https://www.neutrinoapi.com/api/ip-probe/) (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ip-blocklist"
    query: [{name: ip, var: ip, required: true}, {name: vpn-lookup, var: vpn_lookup}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    ip: $ip, vpn_lookup: $vpn_lookup
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IP Blocklist Download
#
# GET /ip-blocklist-download
# Returns: binary
# operationId: IPBlocklistDownload
export def "ip-blocklist-download" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # The data format. Can be either CSV or TXT (default: csv)
  --include-vpn: oneof<nothing, bool> # Include public VPN provider addresses, this option is only available for Tier 3 or higher accounts. Adds any IPs which are solely listed as VPN providers, IPs that are listed on multiple sensors will still be included without enabling this option. WARNING: This adds at least an additional 8 million IP addresses to the download if not using CIDR notation (default: false)
  --cidr: oneof<nothing, bool> # Output IPs using CIDR notation. This option should be preferred but is off by default for backwards compatibility (default: false)
  --ip6: oneof<nothing, bool> # Output the IPv6 version of the blocklist, the default is to output IPv4 only. Note that this option enables CIDR notation too as this is the only notation currently supported for IPv6 (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/ip-blocklist-download"
    query: [{name: format, var: format}, {name: include-vpn, var: include_vpn}, {name: cidr, var: cidr}, {name: ip6, var: ip6}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    format: $format, include_vpn: $include_vpn, cidr: $cidr, ip6: $ip6
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IP Info
#
# GET /ip-info
# Returns: record<city: string, continent-code: string, country: string, country-code: string, country-code3: string, currency-code: string, host-domain: string, hostname: string, ip: string, is-bogon: bool, is-v4-mapped: bool, is-v6: bool, latitude: float, longitude: float, region: string, region-code: string, timezone: record, valid: bool>
# operationId: IPInfo
export def "ip-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip: string # IPv4 or IPv6 address (required)
  --reverse-lookup: oneof<nothing, bool> # Do a reverse DNS (PTR) lookup. This option can add extra delay to the request so only use it if you need it (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ip-info"
    query: [{name: ip, var: ip, required: true}, {name: reverse-lookup, var: reverse_lookup}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    ip: $ip, reverse_lookup: $reverse_lookup
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# IP Probe
#
# GET /ip-probe
# Returns: record<as-age: int, as-cidr: string, as-country-code: string, as-country-code3: string, as-description: string, as-domains: list<string>, asn: string, city: string, continent-code: string, country: string, country-code: string, country-code3: string, currency-code: string, host-domain: string, hostname: string, ip: string, is-bogon: bool, is-hosting: bool, is-isp: bool, is-proxy: bool, is-v4-mapped: bool, is-v6: bool, is-vpn: bool, provider-description: string, provider-domain: string, provider-type: string, provider-website: string, region: string, region-code: string, valid: bool, vpn-domain: string>
# operationId: IPProbe
export def "ip-probe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip: string # IPv4 or IPv6 address (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ip-probe"
    query: [{name: ip, var: ip, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    ip: $ip
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Phone Playback
#
# POST /phone-playback
# Returns: record<calling: bool, number-valid: bool>
# operationId: PhonePlayback
export def "phone-playback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  audio_url: string # A URL to a valid audio file. Accepted audio formats are: MP3 WAV OGG You can use the following MP3 URL for testing: https://www.neutrinoapi.com/test-files/test1.mp3
  --limit: int # Limit the total number of calls allowed to the supplied phone number, if the limit is reached within the TTL then error code 14 will be returned (format: int32, default: 3)
  --limit-ttl: int # Set the TTL in number of days that the 'limit' option will remember a phone number (the default is 1 day and the maximum is 365 days) (format: int32, default: 1)
  number: string # The phone number to call. Must be in valid international format
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone-playback"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: audio-url, var: audio_url}, {name: limit, var: limit}, {name: limit-ttl, var: limit_ttl}, {name: number, var: number}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    audio_url: $audio_url, limit: $limit, limit_ttl: $limit_ttl, number: $number
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Phone Validate
#
# GET /phone-validate
# Returns: record<country: string, country-code: string, country-code3: string, currency-code: string, international-calling-code: string, international-number: string, is-mobile: bool, local-number: string, location: string, prefix-network: string, type: string, valid: bool>
# operationId: PhoneValidate
export def "phone-validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: string # A phone number. This can be in international format (E.164) or local format. If passing local format you must also set either the 'country-code' OR 'ip' options as well (required)
  --country-code: string # ISO 2-letter country code, assume numbers are based in this country. If not set numbers are assumed to be in international format (with or without the leading + sign)
  --ip: string # Pass in a users IP address and we will assume numbers are based in the country of the IP address
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone-validate"
    query: [{name: number, var: number, required: true}, {name: country-code, var: country_code}, {name: ip, var: ip}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    number: $number, country_code: $country_code, ip: $ip
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Phone Verify
#
# POST /phone-verify
# Returns: record<calling: bool, number-valid: bool, security-code: string>
# operationId: PhoneVerify
export def "phone-verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code-length: int # The number of digits to use in the security code (between 4 and 12) (format: int32, default: 6)
  --country-code: string # ISO 2-letter country code, assume numbers are based in this country. If not set numbers are assumed to be in international format (with or without the leading + sign)
  --language-code: string # The language to playback the verification code in, available languages are: de - German en - English es - Spanish fr - French it - Italian pt - Portuguese ru - Russian (default: en)
  --limit: int # Limit the total number of calls allowed to the supplied phone number, if the limit is reached within the TTL then error code 14 will be returned (format: int32, default: 3)
  --limit-ttl: int # Set the TTL in number of days that the 'limit' option will remember a phone number (the default is 1 day and the maximum is 365 days) (format: int32, default: 1)
  number: string # The phone number to send the verification code to
  --playback-delay: int # The delay in milliseconds between the playback of each security code (format: int32, default: 800)
  --security-code: int # Pass in your own security code. This is useful if you have implemented TOTP or similar 2FA methods. If not set then we will generate a secure random code (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone-verify"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: code-length, var: code_length}, {name: country-code, var: country_code}, {name: language-code, var: language_code}, {name: limit, var: limit}, {name: limit-ttl, var: limit_ttl}, {name: number, var: number}, {name: playback-delay, var: playback_delay}, {name: security-code, var: security_code}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    code_length: $code_length, country_code: $country_code, language_code: $language_code, limit: $limit, limit_ttl: $limit_ttl, number: $number, playback_delay: $playback_delay, security_code: $security_code
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# QR Code
#
# POST /qr-code
# Returns: binary
# operationId: QRCode
export def "qr-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bg-color: string # The QR code background color (default: #ffffff)
  content: string # The content to encode into the QR code (e.g. a URL or a phone number)
  --fg-color: string # The QR code foreground color (default: #000000)
  --height: int # The height of the QR code (in px) (format: int32, default: 256)
  --width: int # The width of the QR code (in px) (format: int32, default: 256)
]: any -> any {
  $in | http-request {
    method: post
    path: "/qr-code"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: bg-color, var: bg_color}, {name: content, var: content}, {name: fg-color, var: fg_color}, {name: height, var: height}, {name: width, var: width}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    bg_color: $bg_color, content: $content, fg_color: $fg_color, height: $height, width: $width
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SMS Verify
#
# POST /sms-verify
# Returns: record<number-valid: bool, security-code: string, sent: bool>
# operationId: SMSVerify
export def "sms-verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code-length: int # The number of digits to use in the security code (must be between 4 and 12) (format: int32, default: 5)
  --country-code: string # ISO 2-letter country code, assume numbers are based in this country. If not set numbers are assumed to be in international format (with or without the leading + sign)
  --language-code: string # The language to send the verification code in, available languages are: de - German en - English es - Spanish fr - French it - Italian pt - Portuguese ru - Russian (default: en)
  --limit: int # Limit the total number of SMS allowed to the supplied phone number, if the limit is reached within the TTL then error code 14 will be returned (format: int32, default: 10)
  --limit-ttl: int # Set the TTL in number of days that the 'limit' option will remember a phone number (the default is 1 day and the maximum is 365 days) (format: int32, default: 1)
  number: string # The phone number to send a verification code to
  --security-code: int # Pass in your own security code. This is useful if you have implemented TOTP or similar 2FA methods. If not set then we will generate a secure random code (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sms-verify"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: code-length, var: code_length}, {name: country-code, var: country_code}, {name: language-code, var: language_code}, {name: limit, var: limit}, {name: limit-ttl, var: limit_ttl}, {name: number, var: number}, {name: security-code, var: security_code}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    code_length: $code_length, country_code: $country_code, language_code: $language_code, limit: $limit, limit_ttl: $limit_ttl, number: $number, security_code: $security_code
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UA Lookup
#
# GET /ua-lookup
# Returns: record<browser-engine: string, browser-release: string, device-brand: string, device-height-px: float, device-model: string, device-model-code: string, device-pixel-ratio: float, device-ppi: float, device-price: float, device-release: string, device-resolution: string, device-width-px: float, is-mobile: bool, is-webview: bool, name: string, os: string, os-family: string, os-version: string, os-version-major: string, type: string, ua: string, version: string, version-major: string>
# operationId: UALookup
export def "ua-lookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ua: string # The user-agent string to lookup. For client hints use the 'UA' header or the JSON data directly from 'navigator.userAgentData.brands' or 'navigator.userAgentData.getHighEntropyValues()' (required)
  --ua-version: string # For client hints this corresponds to the 'UA-Full-Version' header or 'uaFullVersion' from NavigatorUAData
  --ua-platform: string # For client hints this corresponds to the 'UA-Platform' header or 'platform' from NavigatorUAData
  --ua-platform-version: string # For client hints this corresponds to the 'UA-Platform-Version' header or 'platformVersion' from NavigatorUAData
  --ua-mobile: string # For client hints this corresponds to the 'UA-Mobile' header or 'mobile' from NavigatorUAData
  --device-model: string # For client hints this corresponds to the 'UA-Model' header or 'model' from NavigatorUAData. You can also use this parameter to lookup a device directly by its model name, model code or hardware code, on android you can get the model name from: https://developer.android.com/reference/android/os/Build.html#MODEL
  --device-brand: string # This parameter is only used in combination with 'device-model' when doing direct device lookups without any user-agent data. Set this to the brand or manufacturer name, this is required for accurate device detection with ambiguous model names. On android you can get the device brand from: https://developer.android.com/reference/android/os/Build#MANUFACTURER
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ua-lookup"
    query: [{name: ua, var: ua, required: true}, {name: ua-version, var: ua_version}, {name: ua-platform, var: ua_platform}, {name: ua-platform-version, var: ua_platform_version}, {name: ua-mobile, var: ua_mobile}, {name: device-model, var: device_model}, {name: device-brand, var: device_brand}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    ua: $ua, ua_version: $ua_version, ua_platform: $ua_platform, ua_platform_version: $ua_platform_version, ua_mobile: $ua_mobile, device_model: $device_model, device_brand: $device_brand
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# URL Info
#
# GET /url-info
# Returns: record<content: string, content-encoding: string, content-size: int, content-type: string, http-ok: bool, http-redirect: bool, http-status: int, http-status-message: int, is-error: bool, is-timeout: bool, language-code: string, load-time: float, query: record, real: bool, server-city: string, server-country: string, server-country-code: string, server-hostname: string, server-ip: string, server-name: string, server-region: string, title: string, url: string, url-path: string, url-port: int, url-protocol: string, valid: bool>
# operationId: URLInfo
export def "url-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # The URL to probe (required)
  --fetch-content: oneof<nothing, bool> # If this URL responds with html, text, json or xml then return the response. This option is useful if you want to perform further processing on the URL content (e.g. with the HTML Extract or HTML Clean APIs) (default: false)
  --ignore-certificate-errors: oneof<nothing, bool> # Ignore any TLS/SSL certificate errors and load the URL anyway (default: false)
  --timeout: int # Timeout in seconds. Give up if still trying to load the URL after this number of seconds (format: int32, default: 60)
  --retry: int # If the request fails for any reason try again this many times (format: int32, default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/url-info"
    query: [{name: url, var: url, required: true}, {name: fetch-content, var: fetch_content}, {name: ignore-certificate-errors, var: ignore_certificate_errors}, {name: timeout, var: timeout}, {name: retry, var: retry}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    url: $url, fetch_content: $fetch_content, ignore_certificate_errors: $ignore_certificate_errors, timeout: $timeout, retry: $retry
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify Security Code
#
# GET /verify-security-code
# Returns: record<verified: bool>
# operationId: VerifySecurityCode
export def "verify-security-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikey: string # Auth token for api-key (api-key)
  --token-userid: string # Auth token for user-id (user-id)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --security-code: string # The security code to verify (required)
  --limit-by: string # If set then enable additional brute-force protection by limiting the number of attempts by the supplied value. This can be set to any unique identifier you would like to limit by, for example a hash of the users email, phone number or IP address. Requests to this API will be ignored after approximately 10 failed verification attempts
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/verify-security-code"
    query: [{name: security-code, var: security_code, required: true}, {name: limit-by, var: limit_by}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: api-key, var: token_apikey, env: NEUTRINO_API_APIKEY_TOKEN}, {scheme: user-id, var: token_userid, env: NEUTRINO_API_USERID_TOKEN}]
  } {
    security_code: $security_code, limit_by: $limit_by
    base_url: $base_url, token_apikey: $token_apikey, token_userid: $token_userid, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
