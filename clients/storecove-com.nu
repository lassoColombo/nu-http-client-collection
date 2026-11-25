# Auto-generated client for Storecove API v2.0.1
# Source: https://api.apis.guru/v2/specs/storecove.com/2.0.1/openapi.json
# Auth: --token flag or $env.STORECOVE_API_TOKEN

const CLIENT = {
  base_url: "https://api.storecove.com/api/v2"
  token_env_var: "STORECOVE_API_TOKEN"
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

def base-url-completer [] { ["https://api.storecove.com/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def evidence-type-completer [] { ["clearing" "sending"] }
def mode-completer [] { ["direct"] }
def country-completer [] { ["AD" "AE" "AF" "AG" "AI" "AL" "AM" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AX" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BL" "BM" "BN" "BO" "BQ" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CU" "CV" "CW" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GG" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IM" "IN" "IO" "IQ" "IR" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KP" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MF" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SD" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "SS" "ST" "SV" "SX" "SY" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TL" "TM" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "XI" "YE" "YT" "ZA" "ZM" "ZW"] }
def package-version-completer [] { ["aunz" "peppol_bis_v3" "sg"] }
def packaging-completer [] { ["ubl"] }
def parse-strategy-completer [] { ["rfc822"] }
def packaging-completer-1 [] { ["json" "original" "ubl"] }
def package-version-completer-1 [] { ["aunz" "en16931" "jp" "original" "sg" "si11" "si12" "si20"] }
def syntax-completer [] { ["json" "original"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    discovery-exists: "record<code: string, email: bool>"
    discovery-identifiers: "record<countries: table<country: string, receiver: record, region: string, sender: record>>"
    discovery-receives: "record<code: string, email: bool>"
    create-document-submission: "record<guid: string>"
    show-document-submission-evidence: "record<documents: table<document: string, expires_at: string, mime_type: string>, evidence: record<message_id: string, receiving_accesspoint: string, remote_mta_ip: string, reporting_mta: string, smtp_response: string, timestamp: string, transmission_id: string, xml: string>, network: string, receiver: string, sender: string>"
    create-invoice-submission: "record<guid: string>"
    preflight-invoice-recipient: "record<code: string>"
    show-invoice-submission-evidence: "record<actions: table<receiver_response: string, transmission_datetime: string, transmission_result: string, transmission_type: string, transmitted_document: string>, guid: string, status: string>"
    create-legal-entity: "record<advertisements: list<string>, city: string, country: string, county: string, id: int, line1: string, line2: string, party_name: string, public: bool, rea: record<capital: float, identifier: string, liquidation_status: string, partners: string, province: string>, smart_inbox: string, tenant_id: string, third_party_password: string, third_party_username: string, zip: string, peppol_identifiers: table<corppass: record, identifier: string, scheme: string, superscheme: string>, additional_tax_identifiers: table<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string>, api_keys: list<string>>"
    get-legal-entity: "record<advertisements: list<string>, city: string, country: string, county: string, id: int, line1: string, line2: string, party_name: string, public: bool, rea: record<capital: float, identifier: string, liquidation_status: string, partners: string, province: string>, smart_inbox: string, tenant_id: string, third_party_password: string, third_party_username: string, zip: string, peppol_identifiers: table<corppass: record, identifier: string, scheme: string, superscheme: string>, additional_tax_identifiers: table<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string>, api_keys: list<string>>"
    update-legal-entity: "record<advertisements: list<string>, city: string, country: string, county: string, id: int, line1: string, line2: string, party_name: string, public: bool, rea: record<capital: float, identifier: string, liquidation_status: string, partners: string, province: string>, smart_inbox: string, tenant_id: string, third_party_password: string, third_party_username: string, zip: string, peppol_identifiers: table<corppass: record, identifier: string, scheme: string, superscheme: string>, additional_tax_identifiers: table<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string>, api_keys: list<string>>"
    create-additional-tax-identifier: "record<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string>"
    get-additional-tax-identifier: "record<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string>"
    update-additional-tax-identifier: "record<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string>"
    create-administration: "record<email: string, id: int, legal_entity_id: int, package_version: string, packaging: string, sender_email_identity_id: int>"
    get-administration: "record<email: string, id: int, legal_entity_id: int, package_version: string, packaging: string, sender_email_identity_id: int>"
    update-administration: "record<email: string, id: int, legal_entity_id: int, package_version: string, packaging: string, sender_email_identity_id: int>"
    create-peppol-identifier: "record<corppass: record<client_redirect_fail_url: string, client_redirect_success_url: string, corppass_url: string, enabled: bool, flow_type: string, signer_email: string, signer_name: string, simulate_corppass: bool, status: string>, identifier: string, scheme: string, superscheme: string>"
    receive-documenht: "record<guid: string>"
    get-invoice-json: "record<accounting: record<code: string, list: string, list_version: string, name: string>, accounting_cost: string, allowance_charge: float, allowance_charges: table<amount_excluding_tax: float, amount_excluding_vat: string, reason: string, tax: record, vat: record>, amount_including_vat: float, attachments: table<content_type: string, document: string>, billing_reference: string, buyer_reference: string, contract_document_reference: string, delivery: record<actual_date: string, location: record<building_number: string, city: string, country: string, county: string, department: string, id: string, line1: string, line2: string, neighborhood: string, scheme_id: string, secondary_number: string, zip: string>, party: record<name: string>>, document: string, document_currency_code: string, document_totals: record<payable: float, prepaid: float, rounding: float, total: float>, document_type: string, due_date: string, external_key: string, external_user_id: string, guid: string, invoice_lines: table<accounting: record, allowance_charge: float, allowance_charge_array: list, allowance_charges: list, amount_excluding_tax: float, amount_excluding_vat: float, description: string, name: string, period_end: string, period_start: string, price: record, tax: record, units: record, vat: record>, invoice_number: string, invoice_type: string, issue_date: string, legal_entity_id: int, note: string, order_reference: string, payment_means: record<iban: string, id: string>, payment_means_array: table<account: string, branch_code: string, holder: string, mandate: string, network: string, payment_id: string, type: any>, payment_means_payment_id: string, payment_terms_note: string, period_end: string, period_start: string, project_reference: string, sender: record<billing_contact: record<email: string, first_name: string, last_name: string>, building_number: string, city: string, country: string, county: string, department: string, identifiers: list<record>, legal_name: string, line1: string, line2: string, neighborhood: string, party_name: string, peppol_identifiers: record<corppass: record, identifier: string, scheme: string, superscheme: string>, secondary_number: string, zip: string>, source: string, sub_type: string, system_generated_primary_image: bool, tax_point_date: string, tax_subtotals: table<amount_excluding_tax: float, amount_excluding_vat: string, tax: record, vat: record>, tax_system: string, vat_reverse_charge: bool>"
    get-invoice-ubl: "record<external_key: string, external_user_id: string, guid: string, legal_entity_id: int, system_generated_primary_image: bool, tax_system: string, ubl: string>"
    get-invoice-ubl-versioned: "record<external_key: string, external_user_id: string, guid: string, legal_entity_id: int, system_generated_primary_image: bool, tax_system: string, ubl: string>"
    create-received-document: "record<guid: string>"
    get-received-document: "record<guid: string>"
    get-webhook-instances: "record<body: string, guid: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["discovery-exists" "discovery-identifiers" "discovery-receives" "create-document-submission" "show-document-submission-evidence" "create-invoice-submission" "preflight-invoice-recipient" "show-invoice-submission-evidence" "create-legal-entity" "delete-legal-entity" "get-legal-entity" "update-legal-entity" "create-additional-tax-identifier" "delete-additional-tax-identifier" "get-additional-tax-identifier" "update-additional-tax-identifier" "create-administration" "delete-administration" "get-administration" "update-administration" "create-peppol-identifier" "delete-peppol-identifier" "receive-documenht" "get-invoice-json" "get-invoice-ubl" "get-invoice-ubl-versioned" "create-received-document" "get-received-document" "get-webhook-instances" "delete-webhook-instance" "commands"] | sort) } | get name | first)
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

# Discover Network Participant Existence
#
# POST /discovery/exists
# Returns: record<code: string, email: bool>
# operationId: discovery_exists
export def "discovery-exists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-types: list<string> # An array of document types to discover. The default is '["invoice", "creditnote"]'. This is ignored when only checking existence.
  identifier: string # The actual identifier.
  --meta-scheme: string # The meta scheme of the identifier. For Peppol this is always 'iso6523-actorid-upis'. (default: iso6523-actorid-upis)
  --network: string # The network to check. Currently only 'peppol' is supported. (default: peppol)
  scheme: string # The scheme of the identifier. See <<_receiver_identifiers_list>> for a list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/discovery/exists"
    body: {content_type: "application/json", kind: json, fields: [{name: documentTypes, var: document_types}, {name: identifier, var: identifier}, {name: metaScheme, var: meta_scheme}, {name: network, var: network}, {name: scheme, var: scheme}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document_types: $document_types, identifier: $identifier, meta_scheme: $meta_scheme, network: $network, scheme: $scheme
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Discover Country Identifiers ** EXPERIMENTAL
#
# GET /discovery/identifiers
# Returns: record<countries: table<country: string, receiver: record, region: string, sender: record>>
# operationId: discovery_identifiers
export def "discovery-identifiers" [
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
    path: "/discovery/identifiers"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disover Network Participant
#
# POST /discovery/receives
# Returns: record<code: string, email: bool>
# operationId: discovery_receives
export def "discovery-receives" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-types: list<string> # An array of document types to discover. The default is '["invoice", "creditnote"]'. This is ignored when only checking existence.
  identifier: string # The actual identifier.
  --meta-scheme: string # The meta scheme of the identifier. For Peppol this is always 'iso6523-actorid-upis'. (default: iso6523-actorid-upis)
  --network: string # The network to check. Currently only 'peppol' is supported. (default: peppol)
  scheme: string # The scheme of the identifier. See <<_receiver_identifiers_list>> for a list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/discovery/receives"
    body: {content_type: "application/json", kind: json, fields: [{name: documentTypes, var: document_types}, {name: identifier, var: identifier}, {name: metaScheme, var: meta_scheme}, {name: network, var: network}, {name: scheme, var: scheme}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document_types: $document_types, identifier: $identifier, meta_scheme: $meta_scheme, network: $network, scheme: $scheme
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a new document.
#
# POST /document_submissions
# Returns: record<guid: string>
# operationId: create_document_submission
export def "create-document-submission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachments: list # DEPRECATED. Use the attachments array inside the 'document' property. An array of attachments. You may provide up to 10 attchments, but the total size must not exceed 10MB after Base64 encoding. — item shape: {description?: string, document: string, documentId?: string, filename?: string, mimeType: "application/pdf", primaryImage?: bool}
  --create-primary-image: oneof<nothing, bool> # DEPRECATED. In the future we will no longer support creating PDF invoices. Whether or not to create a primary image (PDF) if one is not provided. For customers who started from December 1st 2022, the default is false. For customers who started before that, the default is true.
  --document: record # The document to send. — shape: {documentType: "invoice"|"invoice_response"|"order", invoice?: record, invoiceResponse?: record, order?: record, rawDocumentData?: record}
  --idempotency-guid: string # A guid that you generated for this DocumentSubmission to achieve idempotency. If you submit multiple documents with the same idempotencyGuid, only the first one will be processed and any subsequent ones will trigger an HTTP 422 Unprocessable Entity response.
  --legal-entity-id: int # The id of the LegalEntity this document should be sent on behalf of. Either legalEntityId or receiveGuid is mandatory.
  --receive-guid: string # The GUID that was in the received_document webhook. Either legalEntityId or receiveGuid is mandatory. This field is used for sending response documents, such as InvoiceReponse and OrderResponse.
  --routing: record # The different ways to send the invoice to the recipient. The publicIdentifiers are used to send via the Peppol network, if the recipient is not registered on the Peppol network, the invoice will be sent to the email addresses in the emails property. This property is only mandatory when sending the invoice data using the <<_openapi_invoice>> property, not when sending using the <<_openapi_invoicedata>> property, in which case this information will be extracted from the <<_openapi_invoicedata>> object. If you do specify an <<_openapi_invoicerecipient>> object and an <<_openapi_invoicedata>> object, the data from the two will be merged. — shape: {clearWithoutSending?: bool, eIdentifiers?: list, emails?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/document_submissions"
    body: {content_type: "application/json", kind: json, fields: [{name: attachments, var: attachments}, {name: createPrimaryImage, var: create_primary_image}, {name: document, var: document}, {name: idempotencyGuid, var: idempotency_guid}, {name: legalEntityId, var: legal_entity_id}, {name: receiveGuid, var: receive_guid}, {name: routing, var: routing}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attachments: $attachments, create_primary_image: $create_primary_image, document: $document, idempotency_guid: $idempotency_guid, legal_entity_id: $legal_entity_id, receive_guid: $receive_guid, routing: $routing
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get DocumentSubmission Evidence
#
# GET /document_submissions/{guid}/evidence/{evidence_type}
# Returns: record<documents: table<document: string, expires_at: string, mime_type: string>, evidence: record<message_id: string, receiving_accesspoint: string, remote_mta_ip: string, reporting_mta: string, smtp_response: string, timestamp: string, transmission_id: string, xml: string>, network: string, receiver: string, sender: string>
# operationId: show_document_submission_evidence
export def "show-document-submission-evidence" [
  guid: string
  evidence_type: string@evidence-type-completer
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
    path: "/document_submissions/{guid}/evidence/{evidence_type}"
    path_params: [{name: guid, var: guid}, {name: evidence_type, var: evidence_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    guid: $guid, evidence_type: $evidence_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a new invoice
#
# POST /invoice_submissions
# Returns: record<guid: string>
# operationId: create_invoice_submission
export def "create-invoice-submission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachments: list # An array of attachments. You may provide up to 10 attchments, but the total size must not exceed 10MB after Base64 encoding. — item shape: {description?: string, document: string, documentId?: string, filename?: string, mimeType: "application/pdf", primaryImage?: bool}
  --create-primary-image: oneof<nothing, bool> # DEPRECATED. In the future we will no longer support creating PDF invoices. Whether or not to create a primary image (PDF) if one is not provided. For customers who started from December 1st 2022, the default is false. For customers who started before that, the default is true.
  --document: string # DEPRECATED. Use attachments.
  --document-url: string # DEPRECATED. Use attachments. (format: uri)
  --idempotency-guid: string # A guid that you generated for this InvoiceSubmission to achieve idempotency. If you submit multiple documents with the same idempotencyGuid, only the first one will be processed.
  --invoice: record # The invoice to send. Provide either invoice, or invoiceData, but not both. — shape: {accountingCost?: string, accountingCurrencyTaxAmount?: float, ... (42 more fields)}
  --invoice-data: record # The invoice to send, in base64 encoded format. Provide either invoice, or invoiceData, but not both. — shape: {conversionStrategy?: "ubl"|"cii"|"idoc", document?: string}
  --invoice-recipient: record # The different ways to send the invoice to the recipient. The publicIdentifiers are used to send via the Peppol network, if the recipient is not registered on the Peppol network, the invoice will be sent to the email addresses in the emails property. This property is only mandatory when sending the invoice data using the <<_openapi_invoice>> property, not when sending using the <<_openapi_invoicedata>> property, in which case this information will be extracted from the <<_openapi_invoicedata>> object. If you do specify an <<_openapi_invoicerecipient>> object and an <<_openapi_invoicedata>> object, the data from the two will be merged. — shape: {emails?: list<string>, publicIdentifiers?: list}
  --legal-entity-id: int # The id of the LegalEntity this invoice should be sent for.
  --legal-supplier-id: int # DEPRECATED. Use legalEntityId
  --mode: string@mode-completer # DEPRECATED.
  --routing: record # The different ways to send the invoice to the recipient. The publicIdentifiers are used to send via the Peppol network, if the recipient is not registered on the Peppol network, the invoice will be sent to the email addresses in the emails property. This property is only mandatory when sending the invoice data using the <<_openapi_invoice>> property, not when sending using the <<_openapi_invoicedata>> property, in which case this information will be extracted from the <<_openapi_invoicedata>> object. If you do specify an <<_openapi_invoicerecipient>> object and an <<_openapi_invoicedata>> object, the data from the two will be merged. — shape: {clearWithoutSending?: bool, eIdentifiers?: list, emails?: list<string>}
  --supplier-id: int # DEPRECATED.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invoice_submissions"
    body: {content_type: "application/json", kind: json, fields: [{name: attachments, var: attachments}, {name: createPrimaryImage, var: create_primary_image}, {name: document, var: document}, {name: documentUrl, var: document_url}, {name: idempotencyGuid, var: idempotency_guid}, {name: invoice, var: invoice}, {name: invoiceData, var: invoice_data}, {name: invoiceRecipient, var: invoice_recipient}, {name: legalEntityId, var: legal_entity_id}, {name: legalSupplierId, var: legal_supplier_id}, {name: mode, var: mode}, {name: routing, var: routing}, {name: supplierId, var: supplier_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attachments: $attachments, create_primary_image: $create_primary_image, document: $document, document_url: $document_url, idempotency_guid: $idempotency_guid, invoice: $invoice, invoice_data: $invoice_data, invoice_recipient: $invoice_recipient, legal_entity_id: $legal_entity_id, legal_supplier_id: $legal_supplier_id, mode: $mode, routing: $routing, supplier_id: $supplier_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEPRECATED. Preflight an invoice recipient
#
# POST /invoice_submissions/preflight
# Returns: record<code: string>
# operationId: preflight_invoice_recipient
export def "preflight-invoice-recipient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --public-identifiers: list # A list of public identifiers that uniquely identify this customer. — item shape: {id: string, scheme: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invoice_submissions/preflight"
    body: {content_type: "application/json", kind: json, fields: [{name: publicIdentifiers, var: public_identifiers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    public_identifiers: $public_identifiers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEPRECATED. Get InvoiceSubmission Evidence
#
# GET /invoice_submissions/{guid}/evidence
# Returns: record<actions: table<receiver_response: string, transmission_datetime: string, transmission_result: string, transmission_type: string, transmitted_document: string>, guid: string, status: string>
# operationId: show_invoice_submission_evidence
export def "show-invoice-submission-evidence" [
  guid: string
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
    path: "/invoice_submissions/{guid}/evidence"
    path_params: [{name: guid, var: guid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    guid: $guid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new LegalEntity
#
# POST /legal_entities
# Returns: record<advertisements: list<string>, city: string, country: string, county: string, id: int, line1: string, line2: string, party_name: string, public: bool, rea: record<capital: float, identifier: string, liquidation_status: string, partners: string, province: string>, smart_inbox: string, tenant_id: string, third_party_password: string, third_party_username: string, zip: string, peppol_identifiers: table<corppass: record, identifier: string, scheme: string, superscheme: string>, additional_tax_identifiers: table<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string>, api_keys: list<string>>
# operationId: create_legal_entity
export def "create-legal-entity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --advertisements: list<string> # A list of document types to advertise. Use if this LegalEntity needs the ability to receive more than only invoice documents. (default: [invoice])
  city: string # The city.
  country: string@country-completer # An ISO 3166-1 alpha-2 country code.
  --county: string # County, if applicable
  line1: string # The first address line.
  --line2: string # The second address line, if applicable
  party_name: string # The name of the company.
  --public: oneof<nothing, bool> # Whether or not this LegalEntity is public. Public means it will be entered into the PEPPOL directory at https://directory.peppol.eu/ (default: true)
  --rea: any # shape: {capital?: float, identifier?: string, liquidation_status?: "LN"|"LS", partners?: "SU"|"SM", ... (1 more fields)}
  --tenant-id: string # The id of the tenant, to be used in case of single-tenant solutions that share webhook URLs. This property will included in webhook events.
  --third-party-password: string # The password to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN LegalEntity.
  --third-party-username: string # The username to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN LegalEntity.
  zip: string # The zipcode.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/legal_entities"
    body: {content_type: "application/json", kind: json, fields: [{name: advertisements, var: advertisements}, {name: city, var: city}, {name: country, var: country}, {name: county, var: county}, {name: line1, var: line1}, {name: line2, var: line2}, {name: party_name, var: party_name}, {name: public, var: public}, {name: rea, var: rea}, {name: tenant_id, var: tenant_id}, {name: third_party_password, var: third_party_password}, {name: third_party_username, var: third_party_username}, {name: zip, var: zip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    advertisements: $advertisements, city: $city, country: $country, county: $county, line1: $line1, line2: $line2, party_name: $party_name, public: $public, rea: $rea, tenant_id: $tenant_id, third_party_password: $third_party_password, third_party_username: $third_party_username, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete LegalEntity
#
# DELETE /legal_entities/{id}
# operationId: delete_legal_entity
export def "delete-legal-entity" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/legal_entities/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get LegalEntity
#
# GET /legal_entities/{id}
# Returns: record<advertisements: list<string>, city: string, country: string, county: string, id: int, line1: string, line2: string, party_name: string, public: bool, rea: record<capital: float, identifier: string, liquidation_status: string, partners: string, province: string>, smart_inbox: string, tenant_id: string, third_party_password: string, third_party_username: string, zip: string, peppol_identifiers: table<corppass: record, identifier: string, scheme: string, superscheme: string>, additional_tax_identifiers: table<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string>, api_keys: list<string>>
# operationId: get_legal_entity
export def "get-legal-entity" [
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
    path: "/legal_entities/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update LegalEntity
#
# PATCH /legal_entities/{id}
# Returns: record<advertisements: list<string>, city: string, country: string, county: string, id: int, line1: string, line2: string, party_name: string, public: bool, rea: record<capital: float, identifier: string, liquidation_status: string, partners: string, province: string>, smart_inbox: string, tenant_id: string, third_party_password: string, third_party_username: string, zip: string, peppol_identifiers: table<corppass: record, identifier: string, scheme: string, superscheme: string>, additional_tax_identifiers: table<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string>, api_keys: list<string>>
# operationId: update_legal_entity
export def "update-legal-entity" [
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
  --advertisements: list<string> # A list of document types to advertise. Use if this LegalEntity needs the ability to receive more than only invoice documents. (default: [invoice])
  --city: string # The city.
  --country: string@country-completer # An ISO 3166-1 alpha-2 country code.
  --county: string # County, if applicable
  --body-id: int # The Storecove assigned id for the LegalEntity. (format: int64) (spec name: id)
  --line1: string # The first address line.
  --line2: string # The second address line, if applicable
  --party-name: string # The name of the company.
  --public: oneof<nothing, bool> # Whether or not this LegalEntity is public. Public means it will be listed in the PEPPOL directory at https://directory.peppol.eu/ which is normally what you want. If you have a good reason to not want the LegalEntity listed, provide false. This property is ignored when for country SG, where it is always true. (default: true)
  --rea: any # shape: {capital?: float, identifier?: string, liquidation_status?: "LN"|"LS", partners?: "SU"|"SM", ... (1 more fields)}
  --smart-inbox: string # DEPRECATED. Use the <<_openapi_receiveddocuments_resource>> endpoint. The email address of the Smart Inbox for this LegalEntity.
  --tenant-id: string # The id of the tenant, to be used in case of multi-tenant solutions. This property will included in webhook events.
  --third-party-password: string # The password to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN LegalEntity.
  --third-party-username: string # The username to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN LegalEntity.
  --zip: string # The zipcode.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/legal_entities/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: advertisements, var: advertisements}, {name: city, var: city}, {name: country, var: country}, {name: county, var: county}, {name: id, var: body_id}, {name: line1, var: line1}, {name: line2, var: line2}, {name: party_name, var: party_name}, {name: public, var: public}, {name: rea, var: rea}, {name: smart_inbox, var: smart_inbox}, {name: tenant_id, var: tenant_id}, {name: third_party_password, var: third_party_password}, {name: third_party_username, var: third_party_username}, {name: zip, var: zip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, advertisements: $advertisements, city: $city, country: $country, county: $county, body_id: $body_id, line1: $line1, line2: $line2, party_name: $party_name, public: $public, rea: $rea, smart_inbox: $smart_inbox, tenant_id: $tenant_id, third_party_password: $third_party_password, third_party_username: $third_party_username, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new AdditionalTaxIdentifier
#
# POST /legal_entities/{legal_entity_id}/additional_tax_identifiers
# Returns: record<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string>
# operationId: create_additional_tax_identifier
export def "create-additional-tax-identifier" [
  legal_entity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  country: string # The ISO3166 country code to use this identifier for in case of consumerTaxMode.
  --county: string # The county/state inside the country code to use this identifier for in case of consumerTaxMode. Leave empty to create an additional tax identifier for the entire country. For India, use the two last characters of ISO 3166-2:IN (https://en.wikipedia.org/wiki/States_and_union_territories_of_India).
  identifier: string # The identifier.
  scheme: string # The scheme of the identifier.
  superscheme: string # The superscheme of the identifier. Should always be "iso6523-actorid-upis".
  --third-party-password: string # The password to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN tax identifier.
  --third-party-username: string # The username to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN tax identifier.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/legal_entities/{legal_entity_id}/additional_tax_identifiers"
    path_params: [{name: legal_entity_id, var: legal_entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: county, var: county}, {name: identifier, var: identifier}, {name: scheme, var: scheme}, {name: superscheme, var: superscheme}, {name: third_party_password, var: third_party_password}, {name: third_party_username, var: third_party_username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    legal_entity_id: $legal_entity_id, country: $country, county: $county, identifier: $identifier, scheme: $scheme, superscheme: $superscheme, third_party_password: $third_party_password, third_party_username: $third_party_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete AdditionalTaxIdentifier
#
# DELETE /legal_entities/{legal_entity_id}/additional_tax_identifiers/{id}
# operationId: delete_additional_tax_identifier
export def "delete-additional-tax-identifier" [
  legal_entity_id: int
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/legal_entities/{legal_entity_id}/additional_tax_identifiers/{id}"
    path_params: [{name: legal_entity_id, var: legal_entity_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    legal_entity_id: $legal_entity_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get AdditionalTaxIdentifier
#
# GET /legal_entities/{legal_entity_id}/additional_tax_identifiers/{id}
# Returns: record<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string>
# operationId: get_additional_tax_identifier
export def "get-additional-tax-identifier" [
  legal_entity_id: int
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
    path: "/legal_entities/{legal_entity_id}/additional_tax_identifiers/{id}"
    path_params: [{name: legal_entity_id, var: legal_entity_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    legal_entity_id: $legal_entity_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update AdditionalTaxIdentifier
#
# PATCH /legal_entities/{legal_entity_id}/additional_tax_identifiers/{id}
# Returns: record<country: string, county: string, id: int, identifier: string, scheme: string, superscheme: string>
# operationId: update_additional_tax_identifier
export def "update-additional-tax-identifier" [
  legal_entity_id: int
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
  identifier: string # The identifier.
  --third-party-password: string # The password to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN tax identifier.
  --third-party-username: string # The username to use to authenticate to a system through which to send the document, or to obtain tax authority approval to send it. This field is currently relevant only for India and mandatory when creating an IN tax identifier.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/legal_entities/{legal_entity_id}/additional_tax_identifiers/{id}"
    path_params: [{name: legal_entity_id, var: legal_entity_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: identifier, var: identifier}, {name: third_party_password, var: third_party_password}, {name: third_party_username, var: third_party_username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    legal_entity_id: $legal_entity_id, id: $id, identifier: $identifier, third_party_password: $third_party_password, third_party_username: $third_party_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Administration
#
# POST /legal_entities/{legal_entity_id}/administrations
# Returns: record<email: string, id: int, legal_entity_id: int, package_version: string, packaging: string, sender_email_identity_id: int>
# operationId: create_administration
export def "create-administration" [
  legal_entity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address to send the received document to
  --body-legal-entity-id: int # The LegalEntity the Administration belongs to. (format: int64) (spec name: legal_entity_id)
  --package-version: string@package-version-completer # The version of the package. (default: peppol_bis_v3)
  --packaging: string@packaging-completer # How to package the purchase invoice. (default: ubl)
  --sender-email-identity-id: int # The id of the SenderEmailIdentity. If not provided, the Storecove default sender will be used (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/legal_entities/{legal_entity_id}/administrations"
    path_params: [{name: legal_entity_id, var: legal_entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: legal_entity_id, var: body_legal_entity_id}, {name: package_version, var: package_version}, {name: packaging, var: packaging}, {name: sender_email_identity_id, var: sender_email_identity_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    legal_entity_id: $legal_entity_id, email: $email, body_legal_entity_id: $body_legal_entity_id, package_version: $package_version, packaging: $packaging, sender_email_identity_id: $sender_email_identity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Administration
#
# DELETE /legal_entities/{legal_entity_id}/administrations/{id}
# operationId: delete_administration
export def "delete-administration" [
  legal_entity_id: int
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/legal_entities/{legal_entity_id}/administrations/{id}"
    path_params: [{name: legal_entity_id, var: legal_entity_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    legal_entity_id: $legal_entity_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Administration
#
# GET /legal_entities/{legal_entity_id}/administrations/{id}
# Returns: record<email: string, id: int, legal_entity_id: int, package_version: string, packaging: string, sender_email_identity_id: int>
# operationId: get_administration
export def "get-administration" [
  legal_entity_id: int
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
    path: "/legal_entities/{legal_entity_id}/administrations/{id}"
    path_params: [{name: legal_entity_id, var: legal_entity_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    legal_entity_id: $legal_entity_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Administration
#
# PATCH /legal_entities/{legal_entity_id}/administrations/{id}
# Returns: record<email: string, id: int, legal_entity_id: int, package_version: string, packaging: string, sender_email_identity_id: int>
# operationId: update_administration
export def "update-administration" [
  legal_entity_id: int
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
  --email: string # The email address to send the received document to
  --package-version: string@package-version-completer # The version of the package.
  --packaging: string@packaging-completer # How to package the purchase invoice.
  --sender-email-identity-id: int # The id of the SenderEmailIdentity. If not provided, the Storecove default sender will be used (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/legal_entities/{legal_entity_id}/administrations/{id}"
    path_params: [{name: legal_entity_id, var: legal_entity_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: package_version, var: package_version}, {name: packaging, var: packaging}, {name: sender_email_identity_id, var: sender_email_identity_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    legal_entity_id: $legal_entity_id, id: $id, email: $email, package_version: $package_version, packaging: $packaging, sender_email_identity_id: $sender_email_identity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new PeppolIdentifier
#
# POST /legal_entities/{legal_entity_id}/peppol_identifiers
# Returns: record<corppass: record<client_redirect_fail_url: string, client_redirect_success_url: string, corppass_url: string, enabled: bool, flow_type: string, signer_email: string, signer_name: string, simulate_corppass: bool, status: string>, identifier: string, scheme: string, superscheme: string>
# operationId: create_peppol_identifier
export def "create-peppol-identifier" [
  legal_entity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --corppass: any # shape: {client_redirect_fail_url?: string, client_redirect_success_url?: string, enabled?: bool, flow_type: "corppass_flow_redirect"|"corppass_flow_email", signer_email?: string, signer_name?: string, simulate_corppass?: bool}
  identifier: string # The identifier.
  scheme: string # The scheme of the identifier. See <<_receiver_identifiers_list>> for a list.
  superscheme: string # The superscheme of the identifier. Should always be "iso6523-actorid-upis".
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/legal_entities/{legal_entity_id}/peppol_identifiers"
    path_params: [{name: legal_entity_id, var: legal_entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: corppass, var: corppass}, {name: identifier, var: identifier}, {name: scheme, var: scheme}, {name: superscheme, var: superscheme}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    legal_entity_id: $legal_entity_id, corppass: $corppass, identifier: $identifier, scheme: $scheme, superscheme: $superscheme
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete PeppolIdentifier
#
# DELETE /legal_entities/{legal_entity_id}/peppol_identifiers/{superscheme}/{scheme}/{identifier}
# operationId: delete_peppol_identifier
export def "delete-peppol-identifier" [
  legal_entity_id: int
  superscheme: string
  scheme: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/legal_entities/{legal_entity_id}/peppol_identifiers/{superscheme}/{scheme}/{identifier}"
    path_params: [{name: legal_entity_id, var: legal_entity_id}, {name: superscheme, var: superscheme}, {name: scheme, var: scheme}, {name: identifier, var: identifier}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    legal_entity_id: $legal_entity_id, superscheme: $superscheme, scheme: $scheme, identifier: $identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Receive a new Document
#
# POST /legal_entities/{legal_entity_id}/received_documents
# Returns: record<guid: string>
# operationId: receive_documenht
export def "receive-documenht" [
  legal_entity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document: string # The Base64 encoded document.
  --body-legal-entity-id: int # The of the LegalEntity this document was received for. (format: int64) (spec name: legal_entity_id)
  --parse-strategy: string@parse-strategy-completer # The attachment content type (mime type).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/legal_entities/{legal_entity_id}/received_documents"
    path_params: [{name: legal_entity_id, var: legal_entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: document, var: document}, {name: legal_entity_id, var: body_legal_entity_id}, {name: parseStrategy, var: parse_strategy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    legal_entity_id: $legal_entity_id, document: $document, body_legal_entity_id: $body_legal_entity_id, parse_strategy: $parse_strategy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Purchase invoice data as JSON
#
# GET /purchase_invoices/{guid}
# Returns: record<accounting: record<code: string, list: string, list_version: string, name: string>, accounting_cost: string, allowance_charge: float, allowance_charges: table<amount_excluding_tax: float, amount_excluding_vat: string, reason: string, tax: record, vat: record>, amount_including_vat: float, attachments: table<content_type: string, document: string>, billing_reference: string, buyer_reference: string, contract_document_reference: string, delivery: record<actual_date: string, location: record<building_number: string, city: string, country: string, county: string, department: string, id: string, line1: string, line2: string, neighborhood: string, scheme_id: string, secondary_number: string, zip: string>, party: record<name: string>>, document: string, document_currency_code: string, document_totals: record<payable: float, prepaid: float, rounding: float, total: float>, document_type: string, due_date: string, external_key: string, external_user_id: string, guid: string, invoice_lines: table<accounting: record, allowance_charge: float, allowance_charge_array: list, allowance_charges: list, amount_excluding_tax: float, amount_excluding_vat: float, description: string, name: string, period_end: string, period_start: string, price: record, tax: record, units: record, vat: record>, invoice_number: string, invoice_type: string, issue_date: string, legal_entity_id: int, note: string, order_reference: string, payment_means: record<iban: string, id: string>, payment_means_array: table<account: string, branch_code: string, holder: string, mandate: string, network: string, payment_id: string, type: any>, payment_means_payment_id: string, payment_terms_note: string, period_end: string, period_start: string, project_reference: string, sender: record<billing_contact: record<email: string, first_name: string, last_name: string>, building_number: string, city: string, country: string, county: string, department: string, identifiers: list<record>, legal_name: string, line1: string, line2: string, neighborhood: string, party_name: string, peppol_identifiers: record<corppass: record, identifier: string, scheme: string, superscheme: string>, secondary_number: string, zip: string>, source: string, sub_type: string, system_generated_primary_image: bool, tax_point_date: string, tax_subtotals: table<amount_excluding_tax: float, amount_excluding_vat: string, tax: record, vat: record>, tax_system: string, vat_reverse_charge: bool>
# operationId: get_invoice_json
export def "get-invoice-json" [
  guid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pmv: string # The PaymentMeans version. The default (and deprecated) version 1.0 will give BankPaymentMean, DirectDebitPaymentMean, CardPaymentMean, NppPaymentMean, SeBankGiroPaymentMean, SePlusGiroPaymentMean, SgCardPaymentMean, SgGiroPaymentMean, SgPaynowPaymentMean. Version 2.0 deprecates BankPaymentMean (now CreditTransferPaymentMean), CardPaymentMean (now CreditCardPaymentMean), NppPaymentMean (now AunzNppPayidPaymentMean), SeBankGiroPaymentMean (now SeBankgiroPaymentMean -- note the lower 'g' in 'bankgiro'). It also adds OnlinePaymentServicePaymentMean, StandingAgreementPaymentMean, AunzNppPaytoPaymentMean, AunzBpayPaymentMean, AunzPostbillpayPaymentMean, AunzUriPaymentMean. (default: 1.0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/purchase_invoices/{guid}"
    path_params: [{name: guid, var: guid}]
    query: [{name: pmv, var: pmv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    guid: $guid, pmv: $pmv
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Purchase invoice data in a selectable format
#
# GET /purchase_invoices/{guid}/{packaging}
# Returns: record<external_key: string, external_user_id: string, guid: string, legal_entity_id: int, system_generated_primary_image: bool, tax_system: string, ubl: string>
# operationId: get_invoice_ubl
export def "get-invoice-ubl" [
  guid: string
  packaging: string@packaging-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pmv: string # The PaymentMeans version. The default (and deprecated) version 1.0 will give BankPaymentMean, DirectDebitPaymentMean, CardPaymentMean, NppPaymentMean, SeBankGiroPaymentMean, SePlusGiroPaymentMean, SgCardPaymentMean, SgGiroPaymentMean, SgPaynowPaymentMean. Version 2.0 deprecates BankPaymentMean (now CreditTransferPaymentMean), CardPaymentMean (now CreditCardPaymentMean), NppPaymentMean (now AunzNppPayidPaymentMean), SeBankGiroPaymentMean (now SeBankgiroPaymentMean -- note the lower 'g' in 'bankgiro'). It also adds OnlinePaymentServicePaymentMean, StandingAgreementPaymentMean, AunzNppPaytoPaymentMean, AunzBpayPaymentMean, AunzPostbillpayPaymentMean, AunzUriPaymentMean. (default: 1.0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/purchase_invoices/{guid}/{packaging}"
    path_params: [{name: guid, var: guid}, {name: packaging, var: packaging}]
    query: [{name: pmv, var: pmv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    guid: $guid, packaging: $packaging, pmv: $pmv
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Purchase invoice data as JSON with a Base64-encoded UBL string in the specified version
#
# GET /purchase_invoices/{guid}/{packaging}/{package_version}
# Returns: record<external_key: string, external_user_id: string, guid: string, legal_entity_id: int, system_generated_primary_image: bool, tax_system: string, ubl: string>
# operationId: get_invoice_ubl_versioned
export def "get-invoice-ubl-versioned" [
  guid: string
  packaging: string@packaging-completer
  package_version: string@package-version-completer-1
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
    path: "/purchase_invoices/{guid}/{packaging}/{package_version}"
    path_params: [{name: guid, var: guid}, {name: packaging, var: packaging}, {name: package_version, var: package_version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    guid: $guid, packaging: $packaging, package_version: $package_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new received document
#
# POST /received_documents
# Returns: record<guid: string>
# operationId: create_received_document
export def "create-received-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document: string # The Base64 encoded document.
  --legal-entity-id: int # The of the LegalEntity this document was received for. (format: int64)
  --parse-strategy: string@parse-strategy-completer # The attachment content type (mime type).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/received_documents"
    body: {content_type: "application/json", kind: json, fields: [{name: document, var: document}, {name: legal_entity_id, var: legal_entity_id}, {name: parseStrategy, var: parse_strategy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document: $document, legal_entity_id: $legal_entity_id, parse_strategy: $parse_strategy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a new ReceivedDocument
#
# GET /received_documents/{guid}/{format}
# Returns: record<guid: string>
# operationId: get_received_document
export def "get-received-document" [
  guid: string
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --syntax: string@syntax-completer # The syntax in which to receive the received document. (required, default: json)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/received_documents/{guid}/{format}"
    path_params: [{name: guid, var: guid}, {name: format, var: format}]
    query: [{name: syntax, var: syntax, required: true, default: json}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    guid: $guid, format: $format, syntax: $syntax
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET a WebhookInstance
#
# GET /webhook_instances/
# Returns: record<body: string, guid: string>
# operationId: get_webhook_instances
export def "get-webhook-instances" [
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
    path: "/webhook_instances/"
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE a WebhookInstance
#
# DELETE /webhook_instances/{guid}
# operationId: delete_webhook_instance
export def "delete-webhook-instance" [
  guid: string
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
    path: "/webhook_instances/{guid}"
    path_params: [{name: guid, var: guid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    guid: $guid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
