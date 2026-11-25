# Auto-generated client for Open States API v3 v2021.11.12
# Source: https://api.apis.guru/v2/specs/openstates.org/2021.11.12/openapi.json
# Auth: --token flag or $env.OPEN_STATES_API_V3_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru"
  token_env_var: "OPEN_STATES_API_V3_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: []
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

def base-url-completer [] { ["https://api.apis.guru"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["first_action_asc" "first_action_desc" "latest_action_asc" "latest_action_desc" "updated_asc" "updated_desc"] }
def classification-completer [] { ["committee" "subcommittee"] }
def chamber-completer [] { ["executive" "government" "legislature" "lower" "upper"] }
def classification-completer-1 [] { ["country" "municipality" "state"] }
def org-classification-completer [] { ["executive" "government" "legislature" "lower" "upper"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    bills-search-bills-get: "record<pagination: record<max_page: int, page: int, per_page: int, total_items: int>, results: table<abstracts: list, actions: list, classification: list, created_at: string, documents: list, extras: record, first_action_date: string, from_organization: record, id: string, identifier: string, jurisdiction: record, latest_action_date: string, latest_action_description: string, latest_passage_date: string, openstates_url: string, other_identifiers: list, other_titles: list, related_bills: list, session: string, sources: list, sponsorships: list, subject: list, title: string, updated_at: string, versions: list, votes: list>>"
    bill-detail-by-id-bills-ocd-bill-openstates-bill-id-get: "record<abstracts: table<abstract: string, note: string>, actions: table<classification: list, date: string, description: string, order: int, organization: record>, classification: list<string>, created_at: string, documents: table<date: string, links: list, note: string>, extras: record, first_action_date: string, from_organization: record<classification: string, id: string, name: string>, id: string, identifier: string, jurisdiction: record<classification: string, id: string, name: string>, latest_action_date: string, latest_action_description: string, latest_passage_date: string, openstates_url: string, other_identifiers: table<identifier: string>, other_titles: table<note: string, title: string>, related_bills: table<identifier: string, legislative_session: string, relation_type: string>, session: string, sources: table<note: string, url: string>, sponsorships: table<classification: string, entity_type: string, name: string, organization: record, person: record, primary: bool>, subject: list<string>, title: string, updated_at: string, versions: table<date: string, links: list, note: string>, votes: table<counts: list, extras: record, id: string, identifier: string, motion_classification: list, motion_text: string, organization: record, result: string, sources: list, start_date: string, votes: list>>"
    bill-detail-bills-jurisdiction-session-bill-id-get: "record<abstracts: table<abstract: string, note: string>, actions: table<classification: list, date: string, description: string, order: int, organization: record>, classification: list<string>, created_at: string, documents: table<date: string, links: list, note: string>, extras: record, first_action_date: string, from_organization: record<classification: string, id: string, name: string>, id: string, identifier: string, jurisdiction: record<classification: string, id: string, name: string>, latest_action_date: string, latest_action_description: string, latest_passage_date: string, openstates_url: string, other_identifiers: table<identifier: string>, other_titles: table<note: string, title: string>, related_bills: table<identifier: string, legislative_session: string, relation_type: string>, session: string, sources: table<note: string, url: string>, sponsorships: table<classification: string, entity_type: string, name: string, organization: record, person: record, primary: bool>, subject: list<string>, title: string, updated_at: string, versions: table<date: string, links: list, note: string>, votes: table<counts: list, extras: record, id: string, identifier: string, motion_classification: list, motion_text: string, organization: record, result: string, sources: list, start_date: string, votes: list>>"
    committee-list-committees-get: "record<pagination: record<max_page: int, page: int, per_page: int, total_items: int>, results: table<classification: string, extras: record, id: string, links: list, memberships: list, name: string, other_names: list, parent_id: string, sources: list>>"
    committee-detail-committees-committee-id-get: "record<classification: string, extras: record, id: string, links: table<note: string, url: string>, memberships: table<person: record, person_name: string, role: string>, name: string, other_names: table<name: string, note: string>, parent_id: string, sources: table<note: string, url: string>>"
    event-list-events-get: "record<pagination: record<max_page: int, page: int, per_page: int, total_items: int>, results: table<agenda: list, all_day: bool, classification: string, deleted: bool, description: string, documents: list, end_date: string, id: string, jurisdiction: record, links: list, location: record, media: list, name: string, participants: list, sources: list, start_date: string, status: string, upstream_id: string>>"
    event-detail-events-event-id-get: "record<agenda: table<classification: list, description: string, extras: record, media: list, notes: list, order: int, related_entities: list, subjects: list>, all_day: bool, classification: string, deleted: bool, description: string, documents: table<classification: string, date: string, links: list, note: string>, end_date: string, id: string, jurisdiction: record<classification: string, id: string, name: string>, links: table<note: string, url: string>, location: record<name: string, url: string>, media: table<classification: string, date: string, links: list, note: string, offset: int>, name: string, participants: table<entity_type: string, name: string, note: string, organization: record, person: record>, sources: table<note: string, url: string>, start_date: string, status: string, upstream_id: string>"
    jurisdiction-list-jurisdictions-get: "record<pagination: record<max_page: int, page: int, per_page: int, total_items: int>, results: table<classification: string, division_id: string, id: string, latest_bill_update: string, latest_people_update: string, latest_runs: list, legislative_sessions: list, name: string, organizations: list, url: string>>"
    jurisdiction-detail-jurisdictions-jurisdiction-id-get: "record<classification: string, division_id: string, id: string, latest_bill_update: string, latest_people_update: string, latest_runs: table<end_time: string, start_time: string, success: bool>, legislative_sessions: table<classification: string, downloads: list, end_date: string, identifier: string, name: string, start_date: string>, name: string, organizations: table<classification: string, districts: list, id: string, name: string>, url: string>"
    people-search-people-get: "record<pagination: record<max_page: int, page: int, per_page: int, total_items: int>, results: table<birth_date: string, created_at: string, current_role: record, death_date: string, email: string, extras: record, family_name: string, gender: string, given_name: string, id: string, image: string, jurisdiction: record, links: list, name: string, offices: list, openstates_url: string, other_identifiers: list, other_names: list, party: string, sources: list, updated_at: string>>"
    people-geo-people-geo-get: "record<pagination: record<max_page: int, page: int, per_page: int, total_items: int>, results: table<birth_date: string, created_at: string, current_role: record, death_date: string, email: string, extras: record, family_name: string, gender: string, given_name: string, id: string, image: string, jurisdiction: record, links: list, name: string, offices: list, openstates_url: string, other_identifiers: list, other_names: list, party: string, sources: list, updated_at: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["bills-search-bills-get" "bill-detail-by-id-bills-ocd-bill-openstates-bill-id-get" "bill-detail-bills-jurisdiction-session-bill-id-get" "committee-list-committees-get" "committee-detail-committees-committee-id-get" "event-list-events-get" "event-detail-events-event-id-get" "jurisdiction-list-jurisdictions-get" "jurisdiction-detail-jurisdictions-jurisdiction-id-get" "metrics-metrics-get" "people-search-people-get" "people-geo-people-geo-get" "commands"] | sort) } | get name | first)
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

# Bills Search
#
# GET /bills
# Returns: record<pagination: record<max_page: int, page: int, per_page: int, total_items: int>, results: table<abstracts: list, actions: list, classification: list, created_at: string, documents: list, extras: record, first_action_date: string, from_organization: record, id: string, identifier: string, jurisdiction: record, latest_action_date: string, latest_action_description: string, latest_passage_date: string, openstates_url: string, other_identifiers: list, other_titles: list, related_bills: list, session: string, sources: list, sponsorships: list, subject: list, title: string, updated_at: string, versions: list, votes: list>>
# operationId: bills_search_bills_get
export def "bills-search-bills-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jurisdiction: string # Filter by jurisdiction name or ID.
  --session: string # Filter by session identifier.
  --chamber: string # Filter by chamber of origination.
  --identifier: list<string> # Filter to only include bills with this identifier. (default: [])
  --classification: string # Filter by classification, e.g. bill or resolution
  --subject: list<string> # Filter by one or more subjects. (default: [])
  --updated-since: string # Filter to only include bills with updates since a given date.
  --created-since: string # Filter to only include bills created since a given date.
  --action-since: string # Filter to only include bills with an action since a given date.
  --sort: string@sort-completer # Desired sort order for bill results. (default: updated_desc)
  --sponsor: string # Filter to only include bills sponsored by a given name or person ID.
  --sponsor-classification: string # Filter matched sponsors to only include particular types of sponsorships.
  --q: string # Filter by full text search term.
  --include: list<string> # Additional information to include in response. (default: [])
  --page: int # default: 1
  --per-page: int # default: 10
  --apikey: string
  --x-api-key: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bills"
    query: [{name: jurisdiction, var: jurisdiction}, {name: session, var: session}, {name: chamber, var: chamber}, {name: identifier, var: identifier, style: multi}, {name: classification, var: classification}, {name: subject, var: subject, style: multi}, {name: updated_since, var: updated_since}, {name: created_since, var: created_since}, {name: action_since, var: action_since}, {name: sort, var: sort}, {name: sponsor, var: sponsor}, {name: sponsor_classification, var: sponsor_classification}, {name: q, var: q}, {name: include, var: include, style: multi}, {name: page, var: page}, {name: per_page, var: per_page}, {name: apikey, var: apikey}]
    header: [{name: x-api-key, var: x_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    jurisdiction: $jurisdiction, session: $session, chamber: $chamber, identifier: $identifier, classification: $classification, subject: $subject, updated_since: $updated_since, created_since: $created_since, action_since: $action_since, sort: $sort, sponsor: $sponsor, sponsor_classification: $sponsor_classification, q: $q, include: $include, page: $page, per_page: $per_page, apikey: $apikey, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bill Detail By Id
#
# GET /bills/ocd-bill/{openstates_bill_id}
# Returns: record<abstracts: table<abstract: string, note: string>, actions: table<classification: list, date: string, description: string, order: int, organization: record>, classification: list<string>, created_at: string, documents: table<date: string, links: list, note: string>, extras: record, first_action_date: string, from_organization: record<classification: string, id: string, name: string>, id: string, identifier: string, jurisdiction: record<classification: string, id: string, name: string>, latest_action_date: string, latest_action_description: string, latest_passage_date: string, openstates_url: string, other_identifiers: table<identifier: string>, other_titles: table<note: string, title: string>, related_bills: table<identifier: string, legislative_session: string, relation_type: string>, session: string, sources: table<note: string, url: string>, sponsorships: table<classification: string, entity_type: string, name: string, organization: record, person: record, primary: bool>, subject: list<string>, title: string, updated_at: string, versions: table<date: string, links: list, note: string>, votes: table<counts: list, extras: record, id: string, identifier: string, motion_classification: list, motion_text: string, organization: record, result: string, sources: list, start_date: string, votes: list>>
# operationId: bill_detail_by_id_bills_ocd_bill__openstates_bill_id__get
export def "bill-detail-by-id-bills-ocd-bill-openstates-bill-id-get" [
  openstates_bill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list<string> # default: []
  --apikey: string
  --x-api-key: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bills/ocd-bill/{openstates_bill_id}"
    path_params: [{name: openstates_bill_id, var: openstates_bill_id}]
    query: [{name: include, var: include, style: multi}, {name: apikey, var: apikey}]
    header: [{name: x-api-key, var: x_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    openstates_bill_id: $openstates_bill_id, include: $include, apikey: $apikey, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bill Detail
#
# GET /bills/{jurisdiction}/{session}/{bill_id}
# Returns: record<abstracts: table<abstract: string, note: string>, actions: table<classification: list, date: string, description: string, order: int, organization: record>, classification: list<string>, created_at: string, documents: table<date: string, links: list, note: string>, extras: record, first_action_date: string, from_organization: record<classification: string, id: string, name: string>, id: string, identifier: string, jurisdiction: record<classification: string, id: string, name: string>, latest_action_date: string, latest_action_description: string, latest_passage_date: string, openstates_url: string, other_identifiers: table<identifier: string>, other_titles: table<note: string, title: string>, related_bills: table<identifier: string, legislative_session: string, relation_type: string>, session: string, sources: table<note: string, url: string>, sponsorships: table<classification: string, entity_type: string, name: string, organization: record, person: record, primary: bool>, subject: list<string>, title: string, updated_at: string, versions: table<date: string, links: list, note: string>, votes: table<counts: list, extras: record, id: string, identifier: string, motion_classification: list, motion_text: string, organization: record, result: string, sources: list, start_date: string, votes: list>>
# operationId: bill_detail_bills__jurisdiction___session___bill_id__get
export def "bill-detail-bills-jurisdiction-session-bill-id-get" [
  jurisdiction: string
  session: string
  bill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list<string> # default: []
  --apikey: string
  --x-api-key: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bills/{jurisdiction}/{session}/{bill_id}"
    path_params: [{name: jurisdiction, var: jurisdiction}, {name: session, var: session}, {name: bill_id, var: bill_id}]
    query: [{name: include, var: include, style: multi}, {name: apikey, var: apikey}]
    header: [{name: x-api-key, var: x_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    jurisdiction: $jurisdiction, session: $session, bill_id: $bill_id, include: $include, apikey: $apikey, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Committee List
#
# GET /committees
# Returns: record<pagination: record<max_page: int, page: int, per_page: int, total_items: int>, results: table<classification: string, extras: record, id: string, links: list, memberships: list, name: string, other_names: list, parent_id: string, sources: list>>
# operationId: committee_list_committees_get
export def "committee-list-committees-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jurisdiction: string # Filter by jurisdiction name or ID.
  --classification: string@classification-completer
  --parent: string # ocd-organization ID of parent committee.
  --chamber: string@chamber-completer # Chamber of committee, generally upper or lower.
  --include: list<string> # Additional includes for the Committee response. (default: [])
  --apikey: string
  --page: int # default: 1
  --per-page: int # default: 20
  --x-api-key: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/committees"
    query: [{name: jurisdiction, var: jurisdiction}, {name: classification, var: classification}, {name: parent, var: parent}, {name: chamber, var: chamber}, {name: include, var: include, style: multi}, {name: apikey, var: apikey}, {name: page, var: page}, {name: per_page, var: per_page}]
    header: [{name: x-api-key, var: x_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    jurisdiction: $jurisdiction, classification: $classification, parent: $parent, chamber: $chamber, include: $include, apikey: $apikey, page: $page, per_page: $per_page, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Committee Detail
#
# GET /committees/{committee_id}
# Returns: record<classification: string, extras: record, id: string, links: table<note: string, url: string>, memberships: table<person: record, person_name: string, role: string>, name: string, other_names: table<name: string, note: string>, parent_id: string, sources: table<note: string, url: string>>
# operationId: committee_detail_committees__committee_id__get
export def "committee-detail-committees-committee-id-get" [
  committee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list<string> # Additional includes for the Committee response. (default: [])
  --apikey: string
  --x-api-key: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/committees/{committee_id}"
    path_params: [{name: committee_id, var: committee_id}]
    query: [{name: include, var: include, style: multi}, {name: apikey, var: apikey}]
    header: [{name: x-api-key, var: x_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    committee_id: $committee_id, include: $include, apikey: $apikey, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Event List
#
# GET /events
# Returns: record<pagination: record<max_page: int, page: int, per_page: int, total_items: int>, results: table<agenda: list, all_day: bool, classification: string, deleted: bool, description: string, documents: list, end_date: string, id: string, jurisdiction: record, links: list, location: record, media: list, name: string, participants: list, sources: list, start_date: string, status: string, upstream_id: string>>
# operationId: event_list_events_get
export def "event-list-events-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jurisdiction: string # Filter by jurisdiction name or ID.
  --deleted: oneof<nothing, bool> # Return events marked as deleted? (default: false)
  --before: string # Limit results to those starting before a given datetime.
  --after: string # Limit results to those starting before a given datetime.
  --require-bills: oneof<nothing, bool> # Limit results to events with associated bills. (default: false)
  --include: list<string> # Additional includes for the Event response. (default: [])
  --apikey: string
  --page: int # default: 1
  --per-page: int # default: 20
  --x-api-key: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events"
    query: [{name: jurisdiction, var: jurisdiction}, {name: deleted, var: deleted}, {name: before, var: before}, {name: after, var: after}, {name: require_bills, var: require_bills}, {name: include, var: include, style: multi}, {name: apikey, var: apikey}, {name: page, var: page}, {name: per_page, var: per_page}]
    header: [{name: x-api-key, var: x_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    jurisdiction: $jurisdiction, deleted: $deleted, before: $before, after: $after, require_bills: $require_bills, include: $include, apikey: $apikey, page: $page, per_page: $per_page, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Event Detail
#
# GET /events/{event_id}
# Returns: record<agenda: table<classification: list, description: string, extras: record, media: list, notes: list, order: int, related_entities: list, subjects: list>, all_day: bool, classification: string, deleted: bool, description: string, documents: table<classification: string, date: string, links: list, note: string>, end_date: string, id: string, jurisdiction: record<classification: string, id: string, name: string>, links: table<note: string, url: string>, location: record<name: string, url: string>, media: table<classification: string, date: string, links: list, note: string, offset: int>, name: string, participants: table<entity_type: string, name: string, note: string, organization: record, person: record>, sources: table<note: string, url: string>, start_date: string, status: string, upstream_id: string>
# operationId: event_detail_events__event_id__get
export def "event-detail-events-event-id-get" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list<string> # Additional includes for the Event response. (default: [])
  --apikey: string
  --x-api-key: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events/{event_id}"
    path_params: [{name: event_id, var: event_id}]
    query: [{name: include, var: include, style: multi}, {name: apikey, var: apikey}]
    header: [{name: x-api-key, var: x_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    event_id: $event_id, include: $include, apikey: $apikey, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Jurisdiction List
#
# GET /jurisdictions
# Returns: record<pagination: record<max_page: int, page: int, per_page: int, total_items: int>, results: table<classification: string, division_id: string, id: string, latest_bill_update: string, latest_people_update: string, latest_runs: list, legislative_sessions: list, name: string, organizations: list, url: string>>
# operationId: jurisdiction_list_jurisdictions_get
export def "jurisdiction-list-jurisdictions-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --classification: string@classification-completer-1 # Filter returned jurisdictions by type.
  --include: list<string> # Additional information to include in response. (default: [])
  --page: int # default: 1
  --per-page: int # default: 52
  --apikey: string
  --x-api-key: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jurisdictions"
    query: [{name: classification, var: classification}, {name: include, var: include, style: multi}, {name: page, var: page}, {name: per_page, var: per_page}, {name: apikey, var: apikey}]
    header: [{name: x-api-key, var: x_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    classification: $classification, include: $include, page: $page, per_page: $per_page, apikey: $apikey, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Jurisdiction Detail
#
# GET /jurisdictions/{jurisdiction_id}
# Returns: record<classification: string, division_id: string, id: string, latest_bill_update: string, latest_people_update: string, latest_runs: table<end_time: string, start_time: string, success: bool>, legislative_sessions: table<classification: string, downloads: list, end_date: string, identifier: string, name: string, start_date: string>, name: string, organizations: table<classification: string, districts: list, id: string, name: string>, url: string>
# operationId: jurisdiction_detail_jurisdictions__jurisdiction_id__get
export def "jurisdiction-detail-jurisdictions-jurisdiction-id-get" [
  jurisdiction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list<string> # Additional includes for the Jurisdiction response. (default: [])
  --apikey: string
  --x-api-key: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jurisdictions/{jurisdiction_id}"
    path_params: [{name: jurisdiction_id, var: jurisdiction_id}]
    query: [{name: include, var: include, style: multi}, {name: apikey, var: apikey}]
    header: [{name: x-api-key, var: x_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    jurisdiction_id: $jurisdiction_id, include: $include, apikey: $apikey, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Metrics
#
# GET /metrics
# operationId: metrics_metrics_get
export def "metrics-metrics-get" [
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
    path: "/metrics"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# People Search
#
# GET /people
# Returns: record<pagination: record<max_page: int, page: int, per_page: int, total_items: int>, results: table<birth_date: string, created_at: string, current_role: record, death_date: string, email: string, extras: record, family_name: string, gender: string, given_name: string, id: string, image: string, jurisdiction: record, links: list, name: string, offices: list, openstates_url: string, other_identifiers: list, other_names: list, party: string, sources: list, updated_at: string>>
# operationId: people_search_people_get
export def "people-search-people-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jurisdiction: string # Filter by jurisdiction name or id.
  --name: string # Filter by name, case-insensitive match.
  --id: list<string> # Filter by id, can be specified multiple times for multiple people. (default: [])
  --org-classification: string@org-classification-completer # Filter by current role.
  --district: string # Filter by district name.
  --include: list<string> # Additional information to include in response. (default: [])
  --page: int # default: 1
  --per-page: int # default: 10
  --apikey: string
  --x-api-key: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/people"
    query: [{name: jurisdiction, var: jurisdiction}, {name: name, var: name}, {name: id, var: id, style: multi}, {name: org_classification, var: org_classification}, {name: district, var: district}, {name: include, var: include, style: multi}, {name: page, var: page}, {name: per_page, var: per_page}, {name: apikey, var: apikey}]
    header: [{name: x-api-key, var: x_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    jurisdiction: $jurisdiction, name: $name, id: $id, org_classification: $org_classification, district: $district, include: $include, page: $page, per_page: $per_page, apikey: $apikey, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# People Geo
#
# GET /people.geo
# Returns: record<pagination: record<max_page: int, page: int, per_page: int, total_items: int>, results: table<birth_date: string, created_at: string, current_role: record, death_date: string, email: string, extras: record, family_name: string, gender: string, given_name: string, id: string, image: string, jurisdiction: record, links: list, name: string, offices: list, openstates_url: string, other_identifiers: list, other_names: list, party: string, sources: list, updated_at: string>>
# operationId: people_geo_people_geo_get
export def "people-geo-people-geo-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: float # Latitude of point. (required)
  --lng: float # Longitude of point. (required)
  --include: list<string> # Additional information to include in the response. (default: [])
  --apikey: string
  --x-api-key: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/people.geo"
    query: [{name: lat, var: lat, required: true}, {name: lng, var: lng, required: true}, {name: include, var: include, style: multi}, {name: apikey, var: apikey}]
    header: [{name: x-api-key, var: x_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lat: $lat, lng: $lng, include: $include, apikey: $apikey, x_api_key: $x_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
