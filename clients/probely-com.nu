# Auto-generated client for Probely Developers v1.2.0
# Source: https://api.apis.guru/v2/specs/probely.com/1.2.0/openapi.json
# Auth: --token flag or $env.PROBELY_DEVELOPERS_TOKEN

const CLIENT = {
  base_url: "https://api.probely.com"
  token_env_var: "PROBELY_DEVELOPERS_TOKEN"
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

def base-url-completer [] { ["https://api.probely.com"] }
def auth-scheme-completer [] { ["bearer" "none"] }

# Completers for enum parameters
def environment-completer [] { ["production" "testing"] }
def report-type-completer [] { ["default" "owasp" "pci"] }
def scan-profile-completer [] { ["full" "lightning" "normal" "safe"] }
def type-completer [] { ["free" "multi" "single"] }
def status-completer [] { ["canceled" "canceling" "completed" "completed_with_errors" "failed" "queued" "started" "under_review"] }
def type-completer-1 [] { ["dns" "file"] }
def severity-completer [] { ["10" "20" "30"] }
def state-completer [] { ["accepted" "fixed" "invalid" "notfixed"] }
def recurrence-completer [] { ["" "d" "m" "q" "w"] }
def api-version-completer [] { ["v1"] }
def title-completer [] { ["ceo" "cso" "cto" "dev" "devop" "manager" "other" "seceng"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-account: "record<auto_collection: string, balance: int, balance_currency_code: string, free_target_quantity: int, has_used_trial: bool, heroku: bool, next_billing_at: string, plan: record<allowed_scan_profiles: list<string>, charge_model: string, currency_code: string, description: string, id: string, is_trial: bool, name: string, period: string, period_unit: string, price: int>, plan_target_quantity: int, pool_size: int, status: string, trialEnd: string>"
    post-auth-obtain: "record<token: string, ttl: int>"
    post-auth-refresh: "record<token: string, ttl: int>"
    post-auth-revoke: "record<token: string, ttl: int>"
    post-auth-verify: "record<token: string, ttl: int>"
    get-billing: "record<address: string, city: string, country: string, email: string, first_name: string, last_name: string, other: string, reg_number: string, vat_number: string, zip: string>"
    patch-billing: "record<address: string, city: string, country: string, email: string, first_name: string, last_name: string, other: string, reg_number: string, vat_number: string, zip: string>"
    put-billing: "record<address: string, city: string, country: string, email: string, first_name: string, last_name: string, other: string, reg_number: string, vat_number: string, zip: string>"
    post-billing-actions: "record<action: string>"
    post-billing-estimate: "record<amount_due: int, amount_paid: int, currency_code: string, discounts: table<amount: int, description: string>, line_items: table<amount: int, description: string, discount_amount: int, quantity: int, tax_amount: int, unit_amount: int>, plan: string, plan_id: string, sub_total: int, taxes: table<tax_amount: int, tax_name: string, tax_rate: float>, total: int>"
    post-billing-subscribe: "record<amount_due: int, amount_paid: int, currency_code: string, discounts: table<amount: int, description: string>, line_items: table<amount: int, description: string, discount_amount: int, quantity: int, tax_amount: int, unit_amount: int>, plan: string, plan_id: string, sub_total: int, taxes: table<tax_amount: int, tax_name: string, tax_rate: float>, total: int>"
    post-check: "record<message: string>"
    post-enterprise-auth-obtain: "record<token: string, ttl: int>"
    post-enterprise-auth-refresh: "record<token: string, ttl: int>"
    post-enterprise-auth-revoke: "record<token: string, ttl: int>"
    post-enterprise-auth-verify: "record<token: string, ttl: int>"
    get-events: "record<count: int, length: int, page: int, page_total: int, results: table<content: record, event_type: string, id: string, object_type: string, ocurred_at: string, webhooks: list>>"
    get-events-id: "record<content: record, event_type: string, id: string, object_type: string, ocurred_at: string, webhooks: table<api_version: string, changed: string, changed_by: record, check_cert: bool, created: string, created_by: record, id: string, name: string, url: string>>"
    get-frameworks: "record<count: int, length: int, page: int, page_total: int, results: table<desc: string, id: string, name: string>>"
    get-frameworks-id: "record<desc: string, id: string, name: string>"
    get-integrations: "record<available: record<heroku: bool, jira_cloud: bool, jira_server: bool, slack: bool>, installed: record<heroku: bool, jira_cloud: bool, jira_server: bool, slack: bool>>"
    get-integrations-jira-cloud-projects: "table<id: string, name: string>"
    get-integrations-jira-cloud-projects-project-id-issue-types: "table<id: string, name: string>"
    get-integrations-jira-cloud-projects-project-id-issue-types-issue-type-id-priorities: "table<id: string, name: string>"
    get-integrations-jira-cloud-projects-project-id-issue-types-issue-type-id-status: "table<id: string, name: string>"
    get-integrations-jira-server-projects: "table<id: string, name: string>"
    get-integrations-jira-server-projects-project-id-issue-types: "table<id: string, name: string>"
    get-integrations-jira-server-projects-project-id-issue-types-issue-type-id-priorities: "table<id: string, name: string>"
    get-integrations-jira-server-projects-project-id-issue-types-issue-type-id-status: "table<id: string, name: string>"
    get-keys: "record<count: int, length: int, page: int, page_total: int, results: table<id: string, key: string, name: string>>"
    post-keys: "record<id: string, key: string, name: string>"
    get-keys-id: "record<id: string, key: string, name: string>"
    get-labels: "record<count: int, length: int, page: int, page_total: int, results: table<id: string, name: string>>"
    post-labels: "record<id: string, name: string>"
    get-labels-id: "record<id: string, name: string>"
    patch-labels-id: "record<id: string, name: string>"
    put-labels-id: "record<id: string, name: string>"
    get-plans: "table<allowed_scan_profiles: list<string>, charge_model: string, currency_code: string, description: string, id: string, is_trial: bool, name: string, period: string, period_unit: string, price: int>"
    get-profile: "record<changed: string, changed_by: record<email: string, id: string, name: string>, email: string, id: string, is_active: bool, is_admin: bool, is_billing_admin: bool, name: string, title: string>"
    post-profile-change-password: "record<message: string>"
    post-reset: "record<message: string>"
    post-setpassword: "record<message: string>"
    post-target-actions: "table<action: string, label: string>"
    get-targets: "record<length: int, page: int, page_total: int, pagination_count: int, results: table<allowed_scan_profiles: list, assets: list, changed: string, changed_by: record, connected_target: string, enabled: bool, environment: string, id: string, labels: list, name: string, report_type: string, scan_profile: string, site: record, type: string>>"
    post-targets: "record<allowed_scan_profiles: table<id: string, name: string>, assets: table<changed: string, changed_by: record, cookies: list, desc: string, headers: list, host: string, id: string, include: bool, name: string, stack: list, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool>, changed: string, changed_by: record<email: string, id: string, name: string>, connected_target: string, enabled: bool, environment: string, id: string, labels: list<string>, name: string, report_type: string, scan_profile: string, site: record<basic_auth: record<password: string, username: string>, changed: string, changed_by: record<email: string, id: string, name: string>, cookies: list<record>, desc: string, form_login: list<record>, form_login_check_pattern: string, form_login_url: string, has_basic_auth: bool, has_form_login: bool, headers: list<record>, host: string, id: string, name: string, stack: list<string>, url: string, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool, whitelist: list<string>>, type: string>"
    post-targets-activate: "list<string>"
    get-targets-all-average-fix-time: "record<results: record<high: int, low: int, medium: int>>"
    get-targets-all-needs-attention-pie: "record<\"0\": record<\"0\": string, \"1\": int, \"2\": string>, \"1\": record<\"0\": string, \"1\": int, \"2\": string>>"
    get-targets-all-needs-attention-top: "table<highs: int, id: string, lows: int, mediums: int, name: string, url: string>"
    get-targets-all-risk-trend: "table<\"0\": string, \"1\": int>"
    get-targets-all-scans: "record<count: int, length: int, page: int, page_total: int, results: table<changed: string, changed_by: record, completed: string, crawler: record, created: string, created_by: record, fingerprinter: record, highs: int, id: string, lows: int, mediums: int, scan_profile: string, scanner: record, started: string, status: string, target: record>>"
    get-targets-all-scheduledscans-expanded: "record<results: table<changed: string, changed_by: record, date_time: string, id: string, recurrence: string, target: record>>"
    get-targets-all-severity-trend: "record<results: record<high: list<record>, low: list<record>, medium: list<record>>, step: float>"
    get-targets-all-top-vulns: "table<\"0\": string, \"1\": string>"
    post-targets-archive: "list<string>"
    post-targets-archived: "record<length: int, page: int, page_total: int, pagination_count: int, results: table<allowed_scan_profiles: list, assets: list, changed: string, changed_by: record, connected_target: string, enabled: bool, environment: string, id: string, labels: list, name: string, report_type: string, scan_profile: string, site: record, type: string>>"
    get-targets-id: "record<allowed_scan_profiles: table<id: string, name: string>, assets: table<changed: string, changed_by: record, cookies: list, desc: string, headers: list, host: string, id: string, include: bool, name: string, stack: list, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool>, changed: string, changed_by: record<email: string, id: string, name: string>, connected_target: string, enabled: bool, environment: string, id: string, labels: list<string>, name: string, report_type: string, scan_profile: string, site: record<basic_auth: record<password: string, username: string>, changed: string, changed_by: record<email: string, id: string, name: string>, cookies: list<record>, desc: string, form_login: list<record>, form_login_check_pattern: string, form_login_url: string, has_basic_auth: bool, has_form_login: bool, headers: list<record>, host: string, id: string, name: string, stack: list<string>, url: string, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool, whitelist: list<string>>, type: string>"
    patch-targets-id: "record<allowed_scan_profiles: table<id: string, name: string>, assets: table<changed: string, changed_by: record, cookies: list, desc: string, headers: list, host: string, id: string, include: bool, name: string, stack: list, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool>, changed: string, changed_by: record<email: string, id: string, name: string>, connected_target: string, enabled: bool, environment: string, id: string, labels: list<string>, name: string, report_type: string, scan_profile: string, site: record<basic_auth: record<password: string, username: string>, changed: string, changed_by: record<email: string, id: string, name: string>, cookies: list<record>, desc: string, form_login: list<record>, form_login_check_pattern: string, form_login_url: string, has_basic_auth: bool, has_form_login: bool, headers: list<record>, host: string, id: string, name: string, stack: list<string>, url: string, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool, whitelist: list<string>>, type: string>"
    put-targets-id: "record<allowed_scan_profiles: table<id: string, name: string>, assets: table<changed: string, changed_by: record, cookies: list, desc: string, headers: list, host: string, id: string, include: bool, name: string, stack: list, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool>, changed: string, changed_by: record<email: string, id: string, name: string>, connected_target: string, enabled: bool, environment: string, id: string, labels: list<string>, name: string, report_type: string, scan_profile: string, site: record<basic_auth: record<password: string, username: string>, changed: string, changed_by: record<email: string, id: string, name: string>, cookies: list<record>, desc: string, form_login: list<record>, form_login_check_pattern: string, form_login_url: string, has_basic_auth: bool, has_form_login: bool, headers: list<record>, host: string, id: string, name: string, stack: list<string>, url: string, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool, whitelist: list<string>>, type: string>"
    get-targets-target-id-assets: "record<count: int, length: int, page: int, page_total: int, results: table<changed: string, changed_by: record, cookies: list, desc: string, headers: list, host: string, id: string, include: bool, name: string, stack: list, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool>>"
    post-targets-target-id-assets: "record<changed: string, changed_by: record<email: string, id: string, name: string>, cookies: table<name: string, value: string>, desc: string, headers: table<name: string, value: string>, host: string, id: string, include: bool, name: string, stack: list<string>, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool>"
    get-targets-target-id-assets-id: "record<changed: string, changed_by: record<email: string, id: string, name: string>, cookies: table<name: string, value: string>, desc: string, headers: table<name: string, value: string>, host: string, id: string, include: bool, name: string, stack: list<string>, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool>"
    patch-targets-target-id-assets-id: "record<changed: string, changed_by: record<email: string, id: string, name: string>, cookies: table<name: string, value: string>, desc: string, headers: table<name: string, value: string>, host: string, id: string, include: bool, name: string, stack: list<string>, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool>"
    put-targets-target-id-assets-id: "record<changed: string, changed_by: record<email: string, id: string, name: string>, cookies: table<name: string, value: string>, desc: string, headers: table<name: string, value: string>, host: string, id: string, include: bool, name: string, stack: list<string>, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool>"
    post-targets-target-id-assets-id-verify: "record<message: string>"
    get-targets-target-id-average-fix-time: "record<results: record<high: int, low: int, medium: int>>"
    get-targets-target-id-events: "record<count: int, length: int, page: int, page_total: int, results: table<content: record, event_type: string, id: string, object_type: string, ocurred_at: string, webhooks: list>>"
    get-targets-target-id-events-id: "record<content: record, event_type: string, id: string, object_type: string, ocurred_at: string, webhooks: table<api_version: string, changed: string, changed_by: record, check_cert: bool, created: string, created_by: record, id: string, name: string, url: string>>"
    get-targets-target-id-findings: "record<count: int, length: int, page: int, page_total: int, results: table<assignee: record, changed: string, changed_by: record, comment: string, cvss_score: float, cvss_vector: string, definition: record, evidence: string, extra: string, fix: string, id: string, insertion_point: string, labels: list, last_found: string, method: string, parameter: string, params: string, path: string, reporter: record, requests: list, scans: list, severity: string, state: string, target: record, url: string, value: string>>"
    get-targets-target-id-findings-report: "binary"
    get-targets-target-id-findings-id: "record<assignee: record<email: string, id: string, name: string>, changed: string, changed_by: record<email: string, id: string, name: string>, comment: string, cvss_score: float, cvss_vector: string, definition: record<desc: string, id: string, name: string>, evidence: string, extra: string, fix: string, id: string, insertion_point: string, labels: list<string>, last_found: string, method: string, parameter: string, params: string, path: string, reporter: record<email: string, id: string, name: string>, requests: table<request: string, response: string>, scans: list<string>, severity: string, state: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>, url: string, value: string>"
    patch-targets-target-id-findings-id: "record<assignee: record<email: string, id: string, name: string>, changed: string, changed_by: record<email: string, id: string, name: string>, comment: string, cvss_score: float, cvss_vector: string, definition: record<desc: string, id: string, name: string>, evidence: string, extra: string, fix: string, id: string, insertion_point: string, labels: list<string>, last_found: string, method: string, parameter: string, params: string, path: string, reporter: record<email: string, id: string, name: string>, requests: table<request: string, response: string>, scans: list<string>, severity: string, state: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>, url: string, value: string>"
    put-targets-target-id-findings-id: "record<assignee: record<email: string, id: string, name: string>, changed: string, changed_by: record<email: string, id: string, name: string>, comment: string, cvss_score: float, cvss_vector: string, definition: record<desc: string, id: string, name: string>, evidence: string, extra: string, fix: string, id: string, insertion_point: string, labels: list<string>, last_found: string, method: string, parameter: string, params: string, path: string, reporter: record<email: string, id: string, name: string>, requests: table<request: string, response: string>, scans: list<string>, severity: string, state: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>, url: string, value: string>"
    get-targets-target-id-findings-id-integrations-jira-cloud: "record<issue_id: string, selective_sync: bool>"
    patch-targets-target-id-findings-id-integrations-jira-cloud: "record<issue_id: string, selective_sync: bool>"
    put-targets-target-id-findings-id-integrations-jira-cloud: "record<issue_id: string, selective_sync: bool>"
    get-targets-target-id-findings-id-integrations-jira-server: "record<issue_id: string, selective_sync: bool>"
    patch-targets-target-id-findings-id-integrations-jira-server: "record<issue_id: string, selective_sync: bool>"
    put-targets-target-id-findings-id-integrations-jira-server: "record<issue_id: string, selective_sync: bool>"
    get-targets-target-id-findings-id-log: "table<change: int, changed: string, changed_by: record<email: string, id: string, name: string>, field: string, old_value: string, value: string>"
    post-targets-target-id-findings-id-retest: "record<changed: string, changed_by: record<email: string, id: string, name: string>, completed: string, crawler: record<error: list<string>, state: string, status: record<\"0\": int, \"1\": int>, warning: list<string>>, created: string, created_by: record<email: string, id: string, name: string>, fingerprinter: record<count: int, error: list<string>, state: string, warning: list<string>>, highs: int, id: string, lows: int, mediums: int, scan_profile: string, scanner: record<error: list<string>, state: string, status: record<\"0\": int, \"1\": int>, warning: list<string>>, started: string, status: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>>"
    get-targets-target-id-integrations: "record<available: record<heroku: bool, jira_cloud: bool, jira_server: bool, slack: bool>, installed: record<heroku: bool, jira_cloud: bool, jira_server: bool, slack: bool>>"
    get-targets-target-id-integrations-jira-cloud: "record<allow_jira: bool, auto_sync: bool, issue_type_id: string, priority_mapping: record<\"10\": string, \"20\": string, \"30\": string>, project_id: string, status_mapping: record<accepted: string, fixed: string, invalid: string, notfixed: string>>"
    patch-targets-target-id-integrations-jira-cloud: "record<allow_jira: bool, auto_sync: bool, issue_type_id: string, priority_mapping: record<\"10\": string, \"20\": string, \"30\": string>, project_id: string, status_mapping: record<accepted: string, fixed: string, invalid: string, notfixed: string>>"
    put-targets-target-id-integrations-jira-cloud: "record<allow_jira: bool, auto_sync: bool, issue_type_id: string, priority_mapping: record<\"10\": string, \"20\": string, \"30\": string>, project_id: string, status_mapping: record<accepted: string, fixed: string, invalid: string, notfixed: string>>"
    get-targets-target-id-integrations-jira-server: "record<allow_jira: bool, auto_sync: bool, issue_type_id: string, priority_mapping: record<\"10\": string, \"20\": string, \"30\": string>, project_id: string, status_mapping: record<accepted: string, fixed: string, invalid: string, notfixed: string>>"
    patch-targets-target-id-integrations-jira-server: "record<allow_jira: bool, auto_sync: bool, issue_type_id: string, priority_mapping: record<\"10\": string, \"20\": string, \"30\": string>, project_id: string, status_mapping: record<accepted: string, fixed: string, invalid: string, notfixed: string>>"
    put-targets-target-id-integrations-jira-server: "record<allow_jira: bool, auto_sync: bool, issue_type_id: string, priority_mapping: record<\"10\": string, \"20\": string, \"30\": string>, project_id: string, status_mapping: record<accepted: string, fixed: string, invalid: string, notfixed: string>>"
    get-targets-target-id-integrations-slack: "record<notify_finding_fixed: bool, notify_high_findings: bool, notify_low_findings: bool, notify_medium_findings: bool, notify_scan_completed: bool, notify_scan_started: bool, webhook_url: string>"
    patch-targets-target-id-integrations-slack: "record<notify_finding_fixed: bool, notify_high_findings: bool, notify_low_findings: bool, notify_medium_findings: bool, notify_scan_completed: bool, notify_scan_started: bool, webhook_url: string>"
    put-targets-target-id-integrations-slack: "record<notify_finding_fixed: bool, notify_high_findings: bool, notify_low_findings: bool, notify_medium_findings: bool, notify_scan_completed: bool, notify_scan_started: bool, webhook_url: string>"
    get-targets-target-id-keys: "record<count: int, length: int, page: int, page_total: int, results: table<id: string, key: string, name: string>>"
    post-targets-target-id-keys: "record<id: string, key: string, name: string>"
    get-targets-target-id-keys-id: "record<id: string, key: string, name: string>"
    get-targets-target-id-risk-trend: "table<\"0\": string, \"1\": int>"
    post-targets-target-id-scan-now: "record<changed: string, changed_by: record<email: string, id: string, name: string>, completed: string, crawler: record<error: list<string>, state: string, status: record<\"0\": int, \"1\": int>, warning: list<string>>, created: string, created_by: record<email: string, id: string, name: string>, fingerprinter: record<count: int, error: list<string>, state: string, warning: list<string>>, highs: int, id: string, lows: int, mediums: int, scan_profile: string, scanner: record<error: list<string>, state: string, status: record<\"0\": int, \"1\": int>, warning: list<string>>, started: string, status: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>>"
    get-targets-target-id-scans: "record<count: int, length: int, page: int, page_total: int, results: table<changed: string, changed_by: record, completed: string, crawler: record, created: string, created_by: record, fingerprinter: record, highs: int, id: string, lows: int, mediums: int, scan_profile: string, scanner: record, started: string, status: string, target: record>>"
    get-targets-target-id-scans-dates: "list<string>"
    get-targets-target-id-scans-retrieve-page: "record<page: int>"
    get-targets-target-id-scans-id: "record<changed: string, changed_by: record<email: string, id: string, name: string>, completed: string, crawler: record<error: list<string>, state: string, status: record<\"0\": int, \"1\": int>, warning: list<string>>, created: string, created_by: record<email: string, id: string, name: string>, fingerprinter: record<count: int, error: list<string>, state: string, warning: list<string>>, highs: int, id: string, lows: int, mediums: int, scan_profile: string, scanner: record<error: list<string>, state: string, status: record<\"0\": int, \"1\": int>, warning: list<string>>, started: string, status: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>>"
    post-targets-target-id-scans-id-cancel: "record<changed: string, changed_by: record<email: string, id: string, name: string>, completed: string, crawler: record<error: list<string>, state: string, status: record<\"0\": int, \"1\": int>, warning: list<string>>, created: string, created_by: record<email: string, id: string, name: string>, fingerprinter: record<count: int, error: list<string>, state: string, warning: list<string>>, highs: int, id: string, lows: int, mediums: int, scan_profile: string, scanner: record<error: list<string>, state: string, status: record<\"0\": int, \"1\": int>, warning: list<string>>, started: string, status: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>>"
    get-targets-target-id-scans-id-endpoints: "binary"
    get-targets-target-id-scans-id-report: "binary"
    get-targets-target-id-scans-id-report-default: "binary"
    get-targets-target-id-scans-id-report-owasp: "binary"
    get-targets-target-id-scans-id-report-pci: "binary"
    get-targets-target-id-scheduledscans: "record<count: int, length: int, page: int, page_total: int, results: table<changed: string, changed_by: record, date_time: string, id: string, recurrence: string, target: record>>"
    post-targets-target-id-scheduledscans: "record<changed: string, changed_by: record<email: string, id: string, name: string>, date_time: string, id: string, recurrence: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>>"
    get-targets-target-id-scheduledscans-expanded: "record<results: table<changed: string, changed_by: record, date_time: string, id: string, recurrence: string, target: record>>"
    get-targets-target-id-scheduledscans-id: "record<changed: string, changed_by: record<email: string, id: string, name: string>, date_time: string, id: string, recurrence: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>>"
    patch-targets-target-id-scheduledscans-id: "record<changed: string, changed_by: record<email: string, id: string, name: string>, date_time: string, id: string, recurrence: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>>"
    put-targets-target-id-scheduledscans-id: "record<changed: string, changed_by: record<email: string, id: string, name: string>, date_time: string, id: string, recurrence: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>>"
    get-targets-target-id-severity-trend: "record<results: record<high: list<record>, low: list<record>, medium: list<record>>, step: float>"
    get-targets-target-id-site: "record<basic_auth: record<password: string, username: string>, changed: string, changed_by: record<email: string, id: string, name: string>, cookies: table<name: string, value: string>, desc: string, form_login: table<name: string, value: string>, form_login_check_pattern: string, form_login_url: string, has_basic_auth: bool, has_form_login: bool, headers: table<name: string, value: string>, host: string, id: string, name: string, stack: list<string>, url: string, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool, whitelist: list<string>>"
    patch-targets-target-id-site: "record<basic_auth: record<password: string, username: string>, changed: string, changed_by: record<email: string, id: string, name: string>, cookies: table<name: string, value: string>, desc: string, form_login: table<name: string, value: string>, form_login_check_pattern: string, form_login_url: string, has_basic_auth: bool, has_form_login: bool, headers: table<name: string, value: string>, host: string, id: string, name: string, stack: list<string>, url: string, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool, whitelist: list<string>>"
    put-targets-target-id-site: "record<basic_auth: record<password: string, username: string>, changed: string, changed_by: record<email: string, id: string, name: string>, cookies: table<name: string, value: string>, desc: string, form_login: table<name: string, value: string>, form_login_check_pattern: string, form_login_url: string, has_basic_auth: bool, has_form_login: bool, headers: table<name: string, value: string>, host: string, id: string, name: string, stack: list<string>, url: string, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool, whitelist: list<string>>"
    post-targets-target-id-site-verify: "record<message: string>"
    get-targets-target-id-top-vulns: "table<\"0\": string, \"1\": string>"
    get-targets-target-id-webhooks: "record<count: int, length: int, page: int, page_total: int, results: table<api_version: string, changed: string, changed_by: record, check_cert: bool, created: string, created_by: record, id: string, name: string, url: string>>"
    post-targets-target-id-webhooks: "record<api_version: string, changed: string, changed_by: record<email: string, id: string, name: string>, check_cert: bool, created: string, created_by: record<email: string, id: string, name: string>, id: string, name: string, url: string>"
    get-targets-target-id-webhooks-id: "record<api_version: string, changed: string, changed_by: record<email: string, id: string, name: string>, check_cert: bool, created: string, created_by: record<email: string, id: string, name: string>, id: string, name: string, url: string>"
    patch-targets-target-id-webhooks-id: "record<api_version: string, changed: string, changed_by: record<email: string, id: string, name: string>, check_cert: bool, created: string, created_by: record<email: string, id: string, name: string>, id: string, name: string, url: string>"
    put-targets-target-id-webhooks-id: "record<api_version: string, changed: string, changed_by: record<email: string, id: string, name: string>, check_cert: bool, created: string, created_by: record<email: string, id: string, name: string>, id: string, name: string, url: string>"
    get-users: "record<count: int, length: int, page: int, page_total: int, results: table<changed: string, changed_by: record, email: string, id: string, is_active: bool, is_admin: bool, is_billing_admin: bool, name: string, title: string>>"
    post-users: "record<changed: string, changed_by: record<email: string, id: string, name: string>, email: string, id: string, is_active: bool, is_admin: bool, is_billing_admin: bool, name: string, title: string>"
    get-users-id: "record<changed: string, changed_by: record<email: string, id: string, name: string>, email: string, id: string, is_active: bool, is_admin: bool, is_billing_admin: bool, name: string, title: string>"
    patch-users-id: "record<changed: string, changed_by: record<email: string, id: string, name: string>, email: string, id: string, is_active: bool, is_admin: bool, is_billing_admin: bool, name: string, title: string>"
    put-users-id: "record<changed: string, changed_by: record<email: string, id: string, name: string>, email: string, id: string, is_active: bool, is_admin: bool, is_billing_admin: bool, name: string, title: string>"
    get-vulnerability-definitions: "record<count: int, length: int, page: int, page_total: int, results: table<changed: string, desc: string, id: string, name: string>>"
    get-vulnerability-definitions-id: "record<changed: string, desc: string, id: string, name: string>"
    get-webhooks: "record<count: int, length: int, page: int, page_total: int, results: table<api_version: string, changed: string, changed_by: record, check_cert: bool, created: string, created_by: record, id: string, name: string, url: string>>"
    post-webhooks: "record<api_version: string, changed: string, changed_by: record<email: string, id: string, name: string>, check_cert: bool, created: string, created_by: record<email: string, id: string, name: string>, id: string, name: string, url: string>"
    get-webhooks-id: "record<api_version: string, changed: string, changed_by: record<email: string, id: string, name: string>, check_cert: bool, created: string, created_by: record<email: string, id: string, name: string>, id: string, name: string, url: string>"
    patch-webhooks-id: "record<api_version: string, changed: string, changed_by: record<email: string, id: string, name: string>, check_cert: bool, created: string, created_by: record<email: string, id: string, name: string>, id: string, name: string, url: string>"
    put-webhooks-id: "record<api_version: string, changed: string, changed_by: record<email: string, id: string, name: string>, check_cert: bool, created: string, created_by: record<email: string, id: string, name: string>, id: string, name: string, url: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-account" "post-auth-obtain" "post-auth-refresh" "post-auth-revoke" "post-auth-verify" "get-billing" "patch-billing" "put-billing" "post-billing-actions" "post-billing-estimate" "post-billing-subscribe" "post-check" "post-enterprise-auth-obtain" "post-enterprise-auth-refresh" "post-enterprise-auth-revoke" "post-enterprise-auth-verify" "get-events" "get-events-id" "get-frameworks" "get-frameworks-id" "get-integrations" "get-integrations-jira-cloud-projects" "get-integrations-jira-cloud-projects-project-id-issue-types" "get-integrations-jira-cloud-projects-project-id-issue-types-issue-type-id-priorities" "get-integrations-jira-cloud-projects-project-id-issue-types-issue-type-id-status" "get-integrations-jira-server-projects" "get-integrations-jira-server-projects-project-id-issue-types" "get-integrations-jira-server-projects-project-id-issue-types-issue-type-id-priorities" "get-integrations-jira-server-projects-project-id-issue-types-issue-type-id-status" "get-keys" "post-keys" "delete-keys-id" "get-keys-id" "get-labels" "post-labels" "delete-labels-id" "get-labels-id" "patch-labels-id" "put-labels-id" "get-plans" "get-profile" "post-profile-change-password" "post-reset" "post-setpassword" "post-target-actions" "get-targets" "post-targets" "post-targets-activate" "get-targets-all-average-fix-time" "get-targets-all-needs-attention-pie" "get-targets-all-needs-attention-top" "get-targets-all-risk-trend" "get-targets-all-scans" "get-targets-all-scheduledscans-expanded" "get-targets-all-severity-trend" "get-targets-all-top-vulns" "post-targets-archive" "post-targets-archived" "delete-targets-id" "get-targets-id" "patch-targets-id" "put-targets-id" "get-targets-target-id-assets" "post-targets-target-id-assets" "delete-targets-target-id-assets-id" "get-targets-target-id-assets-id" "patch-targets-target-id-assets-id" "put-targets-target-id-assets-id" "post-targets-target-id-assets-id-verify" "get-targets-target-id-average-fix-time" "get-targets-target-id-events" "get-targets-target-id-events-id" "get-targets-target-id-findings" "post-targets-target-id-findings-bulk-report" "post-targets-target-id-findings-bulk-retest" "patch-targets-target-id-findings-bulk-update" "get-targets-target-id-findings-report" "get-targets-target-id-findings-id" "patch-targets-target-id-findings-id" "put-targets-target-id-findings-id" "get-targets-target-id-findings-id-integrations-jira-cloud" "patch-targets-target-id-findings-id-integrations-jira-cloud" "put-targets-target-id-findings-id-integrations-jira-cloud" "get-targets-target-id-findings-id-integrations-jira-server" "patch-targets-target-id-findings-id-integrations-jira-server" "put-targets-target-id-findings-id-integrations-jira-server" "get-targets-target-id-findings-id-log" "post-targets-target-id-findings-id-retest" "get-targets-target-id-integrations" "get-targets-target-id-integrations-jira-cloud" "patch-targets-target-id-integrations-jira-cloud" "put-targets-target-id-integrations-jira-cloud" "get-targets-target-id-integrations-jira-server" "patch-targets-target-id-integrations-jira-server" "put-targets-target-id-integrations-jira-server" "get-targets-target-id-integrations-slack" "patch-targets-target-id-integrations-slack" "put-targets-target-id-integrations-slack" "get-targets-target-id-keys" "post-targets-target-id-keys" "delete-targets-target-id-keys-id" "get-targets-target-id-keys-id" "get-targets-target-id-risk-trend" "post-targets-target-id-scan-now" "get-targets-target-id-scans" "get-targets-target-id-scans-dates" "get-targets-target-id-scans-retrieve-page" "get-targets-target-id-scans-id" "post-targets-target-id-scans-id-cancel" "get-targets-target-id-scans-id-endpoints" "get-targets-target-id-scans-id-report" "get-targets-target-id-scans-id-report-default" "get-targets-target-id-scans-id-report-owasp" "get-targets-target-id-scans-id-report-pci" "get-targets-target-id-scheduledscans" "post-targets-target-id-scheduledscans" "get-targets-target-id-scheduledscans-expanded" "delete-targets-target-id-scheduledscans-id" "get-targets-target-id-scheduledscans-id" "patch-targets-target-id-scheduledscans-id" "put-targets-target-id-scheduledscans-id" "get-targets-target-id-severity-trend" "get-targets-target-id-site" "patch-targets-target-id-site" "put-targets-target-id-site" "post-targets-target-id-site-verify" "get-targets-target-id-top-vulns" "get-targets-target-id-webhooks" "post-targets-target-id-webhooks" "delete-targets-target-id-webhooks-id" "get-targets-target-id-webhooks-id" "patch-targets-target-id-webhooks-id" "put-targets-target-id-webhooks-id" "get-users" "post-users" "delete-users-id" "get-users-id" "patch-users-id" "put-users-id" "get-vulnerability-definitions" "get-vulnerability-definitions-id" "get-webhooks" "post-webhooks" "delete-webhooks-id" "get-webhooks-id" "patch-webhooks-id" "put-webhooks-id" "commands"] | sort) } | get name | first)
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

# Retrieve account information
#
# GET /account/
# Returns: record<auto_collection: string, balance: int, balance_currency_code: string, free_target_quantity: int, has_used_trial: bool, heroku: bool, next_billing_at: string, plan: record<allowed_scan_profiles: list<string>, charge_model: string, currency_code: string, description: string, id: string, is_trial: bool, name: string, period: string, period_unit: string, price: int>, plan_target_quantity: int, pool_size: int, status: string, trialEnd: string>
export def "get-account" [
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
    path: "/account/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authenticate user
#
# POST /auth/obtain/
# Returns: record<token: string, ttl: int>
export def "post-auth-obtain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # e.g. dolphins
  username: string # e.g. example@probely.com
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/obtain/"
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace token with a new one
#
# POST /auth/refresh/
# Returns: record<token: string, ttl: int>
export def "post-auth-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # Authentication token (e.g. eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJKR3ZRSTkzSTJhc0oiLCJ0ZW5hbnQiOiJwcm9iZWx5IiwidXNlcm5hbWUiOiJxd2VAZGVmbnVsbC5ldSJ9.7KtUn-Oy8aevOCv2lAnDroAJojLXmm7m2A4CX5cjwAk) (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/refresh/"
    body: {content_type: "application/json", kind: json, fields: [{name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revoke a token
#
# POST /auth/revoke/
# Returns: record<token: string, ttl: int>
export def "post-auth-revoke" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # Authentication token (e.g. eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJKR3ZRSTkzSTJhc0oiLCJ0ZW5hbnQiOiJwcm9iZWx5IiwidXNlcm5hbWUiOiJxd2VAZGVmbnVsbC5ldSJ9.7KtUn-Oy8aevOCv2lAnDroAJojLXmm7m2A4CX5cjwAk) (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/revoke/"
    body: {content_type: "application/json", kind: json, fields: [{name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify a token
#
# POST /auth/verify/
# Returns: record<token: string, ttl: int>
export def "post-auth-verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # Authentication token (e.g. eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJKR3ZRSTkzSTJhc0oiLCJ0ZW5hbnQiOiJwcm9iZWx5IiwidXNlcm5hbWUiOiJxd2VAZGVmbnVsbC5ldSJ9.7KtUn-Oy8aevOCv2lAnDroAJojLXmm7m2A4CX5cjwAk) (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/verify/"
    body: {content_type: "application/json", kind: json, fields: [{name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve billing information
#
# GET /billing/
# Returns: record<address: string, city: string, country: string, email: string, first_name: string, last_name: string, other: string, reg_number: string, vat_number: string, zip: string>
export def "get-billing" [
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
    path: "/billing/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partial update billing information
#
# PATCH /billing/
# Returns: record<address: string, city: string, country: string, email: string, first_name: string, last_name: string, other: string, reg_number: string, vat_number: string, zip: string>
export def "patch-billing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # Address
  city: string # City (e.g. Munich)
  country: string # ISO 3166 alpha-2 country code (e.g. DE)
  email: string # Contact email
  first_name: string # First name
  last_name: string # Last name
  --other: string # Extra data
  --reg-number: string # Company registration number
  vat_number: string # Company VAT registration number
  zip: string # Address ZIP code
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/billing/"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: city, var: city}, {name: country, var: country}, {name: email, var: email}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: other, var: other}, {name: reg_number, var: reg_number}, {name: vat_number, var: vat_number}, {name: zip, var: zip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address: $address, city: $city, country: $country, email: $email, first_name: $first_name, last_name: $last_name, other: $other, reg_number: $reg_number, vat_number: $vat_number, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update billing information
#
# PUT /billing/
# Returns: record<address: string, city: string, country: string, email: string, first_name: string, last_name: string, other: string, reg_number: string, vat_number: string, zip: string>
export def "put-billing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # Address
  city: string # City (e.g. Munich)
  country: string # ISO 3166 alpha-2 country code (e.g. DE)
  email: string # Contact email
  first_name: string # First name
  last_name: string # Last name
  --other: string # Extra data
  --reg-number: string # Company registration number
  vat_number: string # Company VAT registration number
  zip: string # Address ZIP code
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/billing/"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: city, var: city}, {name: country, var: country}, {name: email, var: email}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: other, var: other}, {name: reg_number, var: reg_number}, {name: vat_number, var: vat_number}, {name: zip, var: zip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address: $address, city: $city, country: $country, email: $email, first_name: $first_name, last_name: $last_name, other: $other, reg_number: $reg_number, vat_number: $vat_number, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Action that should be taken to enable the selected targets
#
# POST /billing/actions/
# Returns: record<action: string>
export def "post-billing-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/billing/actions/"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Estimate costs of updating a subscription
#
# POST /billing/estimate/
# Returns: record<amount_due: int, amount_paid: int, currency_code: string, discounts: table<amount: int, description: string>, line_items: table<amount: int, description: string, discount_amount: int, quantity: int, tax_amount: int, unit_amount: int>, plan: string, plan_id: string, sub_total: int, taxes: table<tax_amount: int, tax_name: string, tax_rate: float>, total: int>
export def "post-billing-estimate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --coupon-ids: list<string> # Coupon ids
  --target-ids: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/billing/estimate/"
    body: {content_type: "application/json", kind: json, fields: [{name: coupon_ids, var: coupon_ids}, {name: target_ids, var: target_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    coupon_ids: $coupon_ids, target_ids: $target_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a subscription
#
# POST /billing/subscribe/
# Returns: record<amount_due: int, amount_paid: int, currency_code: string, discounts: table<amount: int, description: string>, line_items: table<amount: int, description: string, discount_amount: int, quantity: int, tax_amount: int, unit_amount: int>, plan: string, plan_id: string, sub_total: int, taxes: table<tax_amount: int, tax_name: string, tax_rate: float>, total: int>
export def "post-billing-subscribe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --coupon-ids: list<string> # Coupon ids
  --target-ids: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/billing/subscribe/"
    body: {content_type: "application/json", kind: json, fields: [{name: coupon_ids, var: coupon_ids}, {name: target_ids, var: target_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    coupon_ids: $coupon_ids, target_ids: $target_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check validity of password reset token
#
# POST /check/
# Returns: record<message: string>
export def "post-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # Reset token received in the user email (e.g. KJUUCY2VIVEHO5KJGVHQ====-PJZXGNKSGNQVSODFPJGQ====-GYZDKOI=-8065bfbf8a0192774f3f/) (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/check/"
    body: {content_type: "application/json", kind: json, fields: [{name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enterprise user authentication
#
# POST /enterprise/auth/obtain/
# Returns: record<token: string, ttl: int>
export def "post-enterprise-auth-obtain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # e.g. dolphins
  username: string # e.g. example@probely.com
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/enterprise/auth/obtain/"
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enterprise token refresh
#
# POST /enterprise/auth/refresh/
# Returns: record<token: string, ttl: int>
export def "post-enterprise-auth-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # Authentication token (e.g. eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJKR3ZRSTkzSTJhc0oiLCJ0ZW5hbnQiOiJwcm9iZWx5IiwidXNlcm5hbWUiOiJxd2VAZGVmbnVsbC5ldSJ9.7KtUn-Oy8aevOCv2lAnDroAJojLXmm7m2A4CX5cjwAk) (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/enterprise/auth/refresh/"
    body: {content_type: "application/json", kind: json, fields: [{name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enterprise token revokation
#
# POST /enterprise/auth/revoke/
# Returns: record<token: string, ttl: int>
export def "post-enterprise-auth-revoke" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # Authentication token (e.g. eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJKR3ZRSTkzSTJhc0oiLCJ0ZW5hbnQiOiJwcm9iZWx5IiwidXNlcm5hbWUiOiJxd2VAZGVmbnVsbC5ldSJ9.7KtUn-Oy8aevOCv2lAnDroAJojLXmm7m2A4CX5cjwAk) (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/enterprise/auth/revoke/"
    body: {content_type: "application/json", kind: json, fields: [{name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enterprise token verification
#
# POST /enterprise/auth/verify/
# Returns: record<token: string, ttl: int>
export def "post-enterprise-auth-verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # Authentication token (e.g. eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJKR3ZRSTkzSTJhc0oiLCJ0ZW5hbnQiOiJwcm9iZWx5IiwidXNlcm5hbWUiOiJxd2VAZGVmbnVsbC5ldSJ9.7KtUn-Oy8aevOCv2lAnDroAJojLXmm7m2A4CX5cjwAk) (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/enterprise/auth/verify/"
    body: {content_type: "application/json", kind: json, fields: [{name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List account events
#
# GET /events/
# Returns: record<count: int, length: int, page: int, page_total: int, results: table<content: record, event_type: string, id: string, object_type: string, ocurred_at: string, webhooks: list>>
export def "get-events" [
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
    path: "/events/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve account event
#
# GET /events/{id}/
# Returns: record<content: record, event_type: string, id: string, object_type: string, ocurred_at: string, webhooks: table<api_version: string, changed: string, changed_by: record, check_cert: bool, created: string, created_by: record, id: string, name: string, url: string>>
export def "get-events-id" [
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
    path: "/events/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List frameworks
#
# GET /frameworks/
# Returns: record<count: int, length: int, page: int, page_total: int, results: table<desc: string, id: string, name: string>>
export def "get-frameworks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number within the paginated result set (e.g. 1)
  --length: int # Number of results to return per page (default: 10)
  --ordering: string # Which field to use when ordering the results, prefix with `-` to invert ordering. (e.g. -changed)
  --search: string # Search term
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/frameworks/"
    query: [{name: page, var: page}, {name: length, var: length}, {name: ordering, var: ordering}, {name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, length: $length, ordering: $ordering, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve framework
#
# GET /frameworks/{id}/
# Returns: record<desc: string, id: string, name: string>
export def "get-frameworks-id" [
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
    path: "/frameworks/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Integrations available and installed in the account
#
# GET /integrations/
# Returns: record<available: record<heroku: bool, jira_cloud: bool, jira_server: bool, slack: bool>, installed: record<heroku: bool, jira_cloud: bool, jira_server: bool, slack: bool>>
export def "get-integrations" [
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
    path: "/integrations/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Jira Projects
#
# GET /integrations/jira-cloud/projects/
# Returns: table<id: string, name: string>
export def "get-integrations-jira-cloud-projects" [
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
    path: "/integrations/jira-cloud/projects/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve project issue types
#
# GET /integrations/jira-cloud/projects/{project_id}/issue_types/
# Returns: table<id: string, name: string>
export def "get-integrations-jira-cloud-projects-project-id-issue-types" [
  project_id: string
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
    path: "/integrations/jira-cloud/projects/{project_id}/issue_types/"
    path_params: [{name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve issue priorities
#
# GET /integrations/jira-cloud/projects/{project_id}/issue_types/{issue_type_id}/priorities/
# Returns: table<id: string, name: string>
export def "get-integrations-jira-cloud-projects-project-id-issue-types-issue-type-id-priorities" [
  project_id: string
  issue_type_id: string
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
    path: "/integrations/jira-cloud/projects/{project_id}/issue_types/{issue_type_id}/priorities/"
    path_params: [{name: project_id, var: project_id}, {name: issue_type_id, var: issue_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, issue_type_id: $issue_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve issue statuses
#
# GET /integrations/jira-cloud/projects/{project_id}/issue_types/{issue_type_id}/status/
# Returns: table<id: string, name: string>
export def "get-integrations-jira-cloud-projects-project-id-issue-types-issue-type-id-status" [
  project_id: string
  issue_type_id: string
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
    path: "/integrations/jira-cloud/projects/{project_id}/issue_types/{issue_type_id}/status/"
    path_params: [{name: project_id, var: project_id}, {name: issue_type_id, var: issue_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, issue_type_id: $issue_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Jira Projects
#
# GET /integrations/jira-server/projects/
# Returns: table<id: string, name: string>
export def "get-integrations-jira-server-projects" [
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
    path: "/integrations/jira-server/projects/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve project issue types
#
# GET /integrations/jira-server/projects/{project_id}/issue_types/
# Returns: table<id: string, name: string>
export def "get-integrations-jira-server-projects-project-id-issue-types" [
  project_id: string
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
    path: "/integrations/jira-server/projects/{project_id}/issue_types/"
    path_params: [{name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve issue priorities
#
# GET /integrations/jira-server/projects/{project_id}/issue_types/{issue_type_id}/priorities/
# Returns: table<id: string, name: string>
export def "get-integrations-jira-server-projects-project-id-issue-types-issue-type-id-priorities" [
  project_id: string
  issue_type_id: string
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
    path: "/integrations/jira-server/projects/{project_id}/issue_types/{issue_type_id}/priorities/"
    path_params: [{name: project_id, var: project_id}, {name: issue_type_id, var: issue_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, issue_type_id: $issue_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve issue statuses
#
# GET /integrations/jira-server/projects/{project_id}/issue_types/{issue_type_id}/status/
# Returns: table<id: string, name: string>
export def "get-integrations-jira-server-projects-project-id-issue-types-issue-type-id-status" [
  project_id: string
  issue_type_id: string
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
    path: "/integrations/jira-server/projects/{project_id}/issue_types/{issue_type_id}/status/"
    path_params: [{name: project_id, var: project_id}, {name: issue_type_id, var: issue_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, issue_type_id: $issue_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List API keys allowed to operate on account
#
# GET /keys/
# Returns: record<count: int, length: int, page: int, page_total: int, results: table<id: string, key: string, name: string>>
export def "get-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number within the paginated result set (e.g. 1)
  --length: int # Number of results to return per page (default: 10)
  --ordering: string # Which field to use when ordering the results, prefix with `-` to invert ordering. (e.g. -changed)
  --search: string # Search term
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/keys/"
    query: [{name: page, var: page}, {name: length, var: length}, {name: ordering, var: ordering}, {name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, length: $length, ordering: $ordering, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create account API key
#
# POST /keys/
# Returns: record<id: string, key: string, name: string>
export def "post-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Custom name for the resource (default: "", e.g. Object name)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/keys/"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete account API key
#
# DELETE /keys/{id}/
export def "delete-keys-id" [
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
    path: "/keys/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve account API key
#
# GET /keys/{id}/
# Returns: record<id: string, key: string, name: string>
export def "get-keys-id" [
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
    path: "/keys/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List labels
#
# GET /labels/
# Returns: record<count: int, length: int, page: int, page_total: int, results: table<id: string, name: string>>
export def "get-labels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number within the paginated result set (e.g. 1)
  --length: int # Number of results to return per page (default: 10)
  --ordering: string # Which field to use when ordering the results, prefix with `-` to invert ordering. (e.g. -changed)
  --search: string # Search term
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/labels/"
    query: [{name: page, var: page}, {name: length, var: length}, {name: ordering, var: ordering}, {name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, length: $length, ordering: $ordering, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create label
#
# POST /labels/
# Returns: record<id: string, name: string>
export def "post-labels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Custom name for the resource (default: "", e.g. Object name)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/labels/"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete label
#
# DELETE /labels/{id}/
export def "delete-labels-id" [
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
    path: "/labels/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve framework
#
# GET /labels/{id}/
# Returns: record<id: string, name: string>
export def "get-labels-id" [
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
    path: "/labels/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partial update
#
# PATCH /labels/{id}/
# Returns: record<id: string, name: string>
export def "patch-labels-id" [
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
  --name: string # Custom name for the resource (default: "", e.g. Object name)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/labels/{id}/"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update label
#
# PUT /labels/{id}/
# Returns: record<id: string, name: string>
export def "put-labels-id" [
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
  --name: string # Custom name for the resource (default: "", e.g. Object name)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/labels/{id}/"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscription plans
#
# GET /plans/
# Returns: table<allowed_scan_profiles: list<string>, charge_model: string, currency_code: string, description: string, id: string, is_trial: bool, name: string, period: string, period_unit: string, price: int>
export def "get-plans" [
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
    path: "/plans/"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User data
#
# GET /profile/
# Returns: record<changed: string, changed_by: record<email: string, id: string, name: string>, email: string, id: string, is_active: bool, is_admin: bool, is_billing_admin: bool, name: string, title: string>
export def "get-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number within the paginated result set (e.g. 1)
  --length: int # Number of results to return per page (default: 10)
  --ordering: string # Which field to use when ordering the results, prefix with `-` to invert ordering. (e.g. -changed)
  --search: string # Search term
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/profile/"
    query: [{name: page, var: page}, {name: length, var: length}, {name: ordering, var: ordering}, {name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, length: $length, ordering: $ordering, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change user password
#
# POST /profile/change_password/
# Returns: record<message: string>
export def "post-profile-change-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  confpassword: string # New user password (confirmation)
  current_password: string # Current user password
  password: string # New user password
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/profile/change_password/"
    body: {content_type: "application/json", kind: json, fields: [{name: confpassword, var: confpassword}, {name: current_password, var: current_password}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    confpassword: $confpassword, current_password: $current_password, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send reset password email
#
# POST /reset/
# Returns: record<message: string>
export def "post-reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # e.g. example@probely.com
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reset/"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset password after asking for a reset (with the token sent by email).
#
# POST /setpassword/
# Returns: record<message: string>
export def "post-setpassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  confpassword: string # New user password (confirmation)
  password: string # New user password
  --body-token: string # Reset token received in the user email (e.g. KJUUCY2VIVEHO5KJGVHQ====-PJZXGNKSGNQVSODFPJGQ====-GYZDKOI=-8065bfbf8a0192774f3f/) (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/setpassword/"
    body: {content_type: "application/json", kind: json, fields: [{name: confpassword, var: confpassword}, {name: password, var: password}, {name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    confpassword: $confpassword, password: $password, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Available actions for the selected targets
#
# POST /target-actions/
# Returns: table<action: string, label: string>
export def "post-target-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/target-actions/"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List targets
#
# GET /targets/
# Returns: record<length: int, page: int, page_total: int, pagination_count: int, results: table<allowed_scan_profiles: list, assets: list, changed: string, changed_by: record, connected_target: string, enabled: bool, environment: string, id: string, labels: list, name: string, report_type: string, scan_profile: string, site: record, type: string>>
export def "get-targets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number within the paginated result set (e.g. 1)
  --length: int # Number of results to return per page (default: 10)
  --ordering: string # Which field to use when ordering the results, prefix with `-` to invert ordering. (e.g. -changed)
  --search: string # Search term
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/targets/"
    query: [{name: page, var: page}, {name: length, var: length}, {name: ordering, var: ordering}, {name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, length: $length, ordering: $ordering, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create target
#
# POST /targets/
# Returns: record<allowed_scan_profiles: table<id: string, name: string>, assets: table<changed: string, changed_by: record, cookies: list, desc: string, headers: list, host: string, id: string, include: bool, name: string, stack: list, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool>, changed: string, changed_by: record<email: string, id: string, name: string>, connected_target: string, enabled: bool, environment: string, id: string, labels: list<string>, name: string, report_type: string, scan_profile: string, site: record<basic_auth: record<password: string, username: string>, changed: string, changed_by: record<email: string, id: string, name: string>, cookies: list<record>, desc: string, form_login: list<record>, form_login_check_pattern: string, form_login_url: string, has_basic_auth: bool, has_form_login: bool, headers: list<record>, host: string, id: string, name: string, stack: list<string>, url: string, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool, whitelist: list<string>>, type: string>
export def "post-targets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connected-target: string # Id of the connected target in a multi-environment targets.
  --environment: string@environment-completer # Multi-environment targets can identify environments using this property. (default: testing)
  --labels: list<string> # User labels for the scope. (This feature is currently only available for certain accounts, please contact our support if you are interested in using it)
  --name: string # Custom name for the resource (default: "", e.g. Object name)
  --report-type: string@report-type-completer # * default - default report, no extra information added * owasp - adds table on OWASP Top 10 most critical web application risks * pci - adds table on PCI requirements
  --scan-profile: string@scan-profile-completer # * lightning - fast simple scan * normal - default profile * full - does everything the default profile does and adds boolean based SQL injection tests * safe - doesn't use any content changing methods (no POST, DELETE, etc) and tries fewer payloads for SQL injection tests (default: normal, e.g. normal)
  --site: record # Main resource associated with a target — shape: {basic_auth?: record, cookies?: list, desc?: string, form_login?: list, form_login_check_pattern?: string, form_login_url?: string, has_basic_auth?: bool, has_form_login?: bool, headers?: list, name?: string, url?: string, whitelist?: list<string>}
  --type: string@type-completer # The type of a target determines what the limitations imposed on a target. * free - Every account is allowed to have 5 free targets, these targets do not need to be verified but can only perform lightning scans. * single - Single environment targets need to be verified but are allowed to run any type of scan allowed by the plan. * multi - Multi environment targets are used when you want to scan the same application in different environments. (default: single)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/targets/"
    body: {content_type: "application/json", kind: json, fields: [{name: connected_target, var: connected_target}, {name: environment, var: environment}, {name: labels, var: labels}, {name: name, var: name}, {name: report_type, var: report_type}, {name: scan_profile, var: scan_profile}, {name: site, var: site}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    connected_target: $connected_target, environment: $environment, labels: $labels, name: $name, report_type: $report_type, scan_profile: $scan_profile, site: $site, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate targets
#
# POST /targets/activate/
# Returns: list<string>
export def "post-targets-activate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/targets/activate/"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Average fix time graph data (all targets)
#
# GET /targets/all/average_fix_time/
# Returns: record<results: record<high: int, low: int, medium: int>>
export def "get-targets-all-average-fix-time" [
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
    path: "/targets/all/average_fix_time/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Targets with open vulnerabilities pie chart data
#
# GET /targets/all/needs_attention_pie/
# Returns: record<"0": record<"0": string, "1": int, "2": string>, "1": record<"0": string, "1": int, "2": string>>
export def "get-targets-all-needs-attention-pie" [
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
    path: "/targets/all/needs_attention_pie/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Targets with open vulnerabilities
#
# GET /targets/all/needs_attention_top/
# Returns: table<highs: int, id: string, lows: int, mediums: int, name: string, url: string>
export def "get-targets-all-needs-attention-top" [
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
    path: "/targets/all/needs_attention_top/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Risk trend graph data (all targets)
#
# GET /targets/all/risk_trend/
# Returns: table<"0": string, "1": int>
export def "get-targets-all-risk-trend" [
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
    path: "/targets/all/risk_trend/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List scans for all targets
#
# GET /targets/all/scans/
# Returns: record<count: int, length: int, page: int, page_total: int, results: table<changed: string, changed_by: record, completed: string, crawler: record, created: string, created_by: record, fingerprinter: record, highs: int, id: string, lows: int, mediums: int, scan_profile: string, scanner: record, started: string, status: string, target: record>>
export def "get-targets-all-scans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number within the paginated result set (e.g. 1)
  --length: int # Number of results to return per page (default: 10)
  --ordering: string # Which field to use when ordering the results, prefix with `-` to invert ordering. (e.g. -changed)
  --search: string # Search term
  --started: list<string> # Filter by scan start dates
  --status: string@status-completer # Filter by scan statuses
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/targets/all/scans/"
    query: [{name: page, var: page}, {name: length, var: length}, {name: ordering, var: ordering}, {name: search, var: search}, {name: started, var: started, style: multi}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, length: $length, ordering: $ordering, search: $search, started: $started, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List scheduled scans for all targets expanding recurrence
#
# GET /targets/all/scheduledscans/expanded/
# Returns: record<results: table<changed: string, changed_by: record, date_time: string, id: string, recurrence: string, target: record>>
export def "get-targets-all-scheduledscans-expanded" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --length: int # Number of results to return per page (default: 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/targets/all/scheduledscans/expanded/"
    query: [{name: length, var: length}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    length: $length
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Severity trend graph data (all targets)
#
# GET /targets/all/severity_trend/
# Returns: record<results: record<high: list<record>, low: list<record>, medium: list<record>>, step: float>
export def "get-targets-all-severity-trend" [
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
    path: "/targets/all/severity_trend/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Top 5 vulnerabilities (all targets).
#
# GET /targets/all/top_vulns/
# Returns: table<"0": string, "1": string>
export def "get-targets-all-top-vulns" [
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
    path: "/targets/all/top_vulns/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archive targets
#
# POST /targets/archive/
# Returns: list<string>
export def "post-targets-archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/targets/archive/"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List archived targets
#
# POST /targets/archived/
# Returns: record<length: int, page: int, page_total: int, pagination_count: int, results: table<allowed_scan_profiles: list, assets: list, changed: string, changed_by: record, connected_target: string, enabled: bool, environment: string, id: string, labels: list, name: string, report_type: string, scan_profile: string, site: record, type: string>>
export def "post-targets-archived" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/targets/archived/"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete target
#
# DELETE /targets/{id}/
export def "delete-targets-id" [
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
    path: "/targets/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve target
#
# GET /targets/{id}/
# Returns: record<allowed_scan_profiles: table<id: string, name: string>, assets: table<changed: string, changed_by: record, cookies: list, desc: string, headers: list, host: string, id: string, include: bool, name: string, stack: list, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool>, changed: string, changed_by: record<email: string, id: string, name: string>, connected_target: string, enabled: bool, environment: string, id: string, labels: list<string>, name: string, report_type: string, scan_profile: string, site: record<basic_auth: record<password: string, username: string>, changed: string, changed_by: record<email: string, id: string, name: string>, cookies: list<record>, desc: string, form_login: list<record>, form_login_check_pattern: string, form_login_url: string, has_basic_auth: bool, has_form_login: bool, headers: list<record>, host: string, id: string, name: string, stack: list<string>, url: string, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool, whitelist: list<string>>, type: string>
export def "get-targets-id" [
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
    path: "/targets/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partial update target
#
# PATCH /targets/{id}/
# Returns: record<allowed_scan_profiles: table<id: string, name: string>, assets: table<changed: string, changed_by: record, cookies: list, desc: string, headers: list, host: string, id: string, include: bool, name: string, stack: list, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool>, changed: string, changed_by: record<email: string, id: string, name: string>, connected_target: string, enabled: bool, environment: string, id: string, labels: list<string>, name: string, report_type: string, scan_profile: string, site: record<basic_auth: record<password: string, username: string>, changed: string, changed_by: record<email: string, id: string, name: string>, cookies: list<record>, desc: string, form_login: list<record>, form_login_check_pattern: string, form_login_url: string, has_basic_auth: bool, has_form_login: bool, headers: list<record>, host: string, id: string, name: string, stack: list<string>, url: string, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool, whitelist: list<string>>, type: string>
export def "patch-targets-id" [
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
  --connected-target: string # Id of the connected target in a multi-environment targets.
  --environment: string@environment-completer # Multi-environment targets can identify environments using this property. (default: testing)
  --labels: list<string> # User labels for the scope. (This feature is currently only available for certain accounts, please contact our support if you are interested in using it)
  --name: string # Custom name for the resource (default: "", e.g. Object name)
  --report-type: string@report-type-completer # * default - default report, no extra information added * owasp - adds table on OWASP Top 10 most critical web application risks * pci - adds table on PCI requirements
  --scan-profile: string@scan-profile-completer # * lightning - fast simple scan * normal - default profile * full - does everything the default profile does and adds boolean based SQL injection tests * safe - doesn't use any content changing methods (no POST, DELETE, etc) and tries fewer payloads for SQL injection tests (default: normal, e.g. normal)
  --site: record # Main resource associated with a target — shape: {basic_auth?: record, cookies?: list, desc?: string, form_login?: list, form_login_check_pattern?: string, form_login_url?: string, has_basic_auth?: bool, has_form_login?: bool, headers?: list, name?: string, url?: string, whitelist?: list<string>}
  --type: string@type-completer # The type of a target determines what the limitations imposed on a target. * free - Every account is allowed to have 5 free targets, these targets do not need to be verified but can only perform lightning scans. * single - Single environment targets need to be verified but are allowed to run any type of scan allowed by the plan. * multi - Multi environment targets are used when you want to scan the same application in different environments. (default: single)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/targets/{id}/"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: connected_target, var: connected_target}, {name: environment, var: environment}, {name: labels, var: labels}, {name: name, var: name}, {name: report_type, var: report_type}, {name: scan_profile, var: scan_profile}, {name: site, var: site}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, connected_target: $connected_target, environment: $environment, labels: $labels, name: $name, report_type: $report_type, scan_profile: $scan_profile, site: $site, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update target
#
# PUT /targets/{id}/
# Returns: record<allowed_scan_profiles: table<id: string, name: string>, assets: table<changed: string, changed_by: record, cookies: list, desc: string, headers: list, host: string, id: string, include: bool, name: string, stack: list, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool>, changed: string, changed_by: record<email: string, id: string, name: string>, connected_target: string, enabled: bool, environment: string, id: string, labels: list<string>, name: string, report_type: string, scan_profile: string, site: record<basic_auth: record<password: string, username: string>, changed: string, changed_by: record<email: string, id: string, name: string>, cookies: list<record>, desc: string, form_login: list<record>, form_login_check_pattern: string, form_login_url: string, has_basic_auth: bool, has_form_login: bool, headers: list<record>, host: string, id: string, name: string, stack: list<string>, url: string, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool, whitelist: list<string>>, type: string>
export def "put-targets-id" [
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
  --connected-target: string # Id of the connected target in a multi-environment targets.
  --environment: string@environment-completer # Multi-environment targets can identify environments using this property. (default: testing)
  --labels: list<string> # User labels for the scope. (This feature is currently only available for certain accounts, please contact our support if you are interested in using it)
  --name: string # Custom name for the resource (default: "", e.g. Object name)
  --report-type: string@report-type-completer # * default - default report, no extra information added * owasp - adds table on OWASP Top 10 most critical web application risks * pci - adds table on PCI requirements
  --scan-profile: string@scan-profile-completer # * lightning - fast simple scan * normal - default profile * full - does everything the default profile does and adds boolean based SQL injection tests * safe - doesn't use any content changing methods (no POST, DELETE, etc) and tries fewer payloads for SQL injection tests (default: normal, e.g. normal)
  --site: record # Main resource associated with a target — shape: {basic_auth?: record, cookies?: list, desc?: string, form_login?: list, form_login_check_pattern?: string, form_login_url?: string, has_basic_auth?: bool, has_form_login?: bool, headers?: list, name?: string, url?: string, whitelist?: list<string>}
  --type: string@type-completer # The type of a target determines what the limitations imposed on a target. * free - Every account is allowed to have 5 free targets, these targets do not need to be verified but can only perform lightning scans. * single - Single environment targets need to be verified but are allowed to run any type of scan allowed by the plan. * multi - Multi environment targets are used when you want to scan the same application in different environments. (default: single)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/targets/{id}/"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: connected_target, var: connected_target}, {name: environment, var: environment}, {name: labels, var: labels}, {name: name, var: name}, {name: report_type, var: report_type}, {name: scan_profile, var: scan_profile}, {name: site, var: site}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, connected_target: $connected_target, environment: $environment, labels: $labels, name: $name, report_type: $report_type, scan_profile: $scan_profile, site: $site, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List target's assets
#
# GET /targets/{target_id}/assets/
# Returns: record<count: int, length: int, page: int, page_total: int, results: table<changed: string, changed_by: record, cookies: list, desc: string, headers: list, host: string, id: string, include: bool, name: string, stack: list, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool>>
export def "get-targets-target-id-assets" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number within the paginated result set (e.g. 1)
  --length: int # Number of results to return per page (default: 10)
  --ordering: string # Which field to use when ordering the results, prefix with `-` to invert ordering. (e.g. -changed)
  --search: string # Search term
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/targets/{target_id}/assets/"
    path_params: [{name: target_id, var: target_id}]
    query: [{name: page, var: page}, {name: length, var: length}, {name: ordering, var: ordering}, {name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, page: $page, length: $length, ordering: $ordering, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new asset
#
# POST /targets/{target_id}/assets/
# Returns: record<changed: string, changed_by: record<email: string, id: string, name: string>, cookies: table<name: string, value: string>, desc: string, headers: table<name: string, value: string>, host: string, id: string, include: bool, name: string, stack: list<string>, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool>
export def "post-targets-target-id-assets" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cookies: list # Custom cookies name/value pairs — item shape: {name?: string, value?: string}
  --desc: string # Custom description for the resource (default: "", e.g. Object description)
  --headers: list # Custom headers name value pairs — item shape: {name?: string, value?: string}
  --host: string # Fully qualified hostname
  --include: oneof<nothing, bool> # Use this asset in scans.
  --name: string # Custom name for the resource (default: "", e.g. Object name)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/targets/{target_id}/assets/"
    path_params: [{name: target_id, var: target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: cookies, var: cookies}, {name: desc, var: desc}, {name: headers, var: headers}, {name: host, var: host}, {name: include, var: include}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    target_id: $target_id, cookies: $cookies, desc: $desc, headers: $headers, host: $host, include: $include, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete asset
#
# DELETE /targets/{target_id}/assets/{id}/
export def "delete-targets-target-id-assets-id" [
  target_id: string
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
    path: "/targets/{target_id}/assets/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve asset
#
# GET /targets/{target_id}/assets/{id}/
# Returns: record<changed: string, changed_by: record<email: string, id: string, name: string>, cookies: table<name: string, value: string>, desc: string, headers: table<name: string, value: string>, host: string, id: string, include: bool, name: string, stack: list<string>, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool>
export def "get-targets-target-id-assets-id" [
  target_id: string
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
    path: "/targets/{target_id}/assets/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partial update assets
#
# PATCH /targets/{target_id}/assets/{id}/
# Returns: record<changed: string, changed_by: record<email: string, id: string, name: string>, cookies: table<name: string, value: string>, desc: string, headers: table<name: string, value: string>, host: string, id: string, include: bool, name: string, stack: list<string>, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool>
export def "patch-targets-target-id-assets-id" [
  target_id: string
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
  --cookies: list # Custom cookies name/value pairs — item shape: {name?: string, value?: string}
  --desc: string # Custom description for the resource (default: "", e.g. Object description)
  --headers: list # Custom headers name value pairs — item shape: {name?: string, value?: string}
  --host: string # Fully qualified hostname
  --include: oneof<nothing, bool> # Use this asset in scans.
  --name: string # Custom name for the resource (default: "", e.g. Object name)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/targets/{target_id}/assets/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: cookies, var: cookies}, {name: desc, var: desc}, {name: headers, var: headers}, {name: host, var: host}, {name: include, var: include}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id, cookies: $cookies, desc: $desc, headers: $headers, host: $host, include: $include, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update asset
#
# PUT /targets/{target_id}/assets/{id}/
# Returns: record<changed: string, changed_by: record<email: string, id: string, name: string>, cookies: table<name: string, value: string>, desc: string, headers: table<name: string, value: string>, host: string, id: string, include: bool, name: string, stack: list<string>, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool>
export def "put-targets-target-id-assets-id" [
  target_id: string
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
  --cookies: list # Custom cookies name/value pairs — item shape: {name?: string, value?: string}
  --desc: string # Custom description for the resource (default: "", e.g. Object description)
  --headers: list # Custom headers name value pairs — item shape: {name?: string, value?: string}
  --host: string # Fully qualified hostname
  --include: oneof<nothing, bool> # Use this asset in scans.
  --name: string # Custom name for the resource (default: "", e.g. Object name)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/targets/{target_id}/assets/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: cookies, var: cookies}, {name: desc, var: desc}, {name: headers, var: headers}, {name: host, var: host}, {name: include, var: include}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id, cookies: $cookies, desc: $desc, headers: $headers, host: $host, include: $include, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify asset ownership
#
# POST /targets/{target_id}/assets/{id}/verify/
# Returns: record<message: string>
export def "post-targets-target-id-assets-id-verify" [
  target_id: string
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
  type: string@type-completer-1 # Type of verification: * dns - we look or a TXT record on the host you registered containing `Probely=<verification_token>` * file - on the root of the path you registered we look for a file named `` containing `Probely`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/targets/{target_id}/assets/{id}/verify/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Average vulnerability trend graph data
#
# GET /targets/{target_id}/average_fix_time/
# Returns: record<results: record<high: int, low: int, medium: int>>
export def "get-targets-target-id-average-fix-time" [
  target_id: string
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
    path: "/targets/{target_id}/average_fix_time/"
    path_params: [{name: target_id, var: target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List target events
#
# GET /targets/{target_id}/events/
# Returns: record<count: int, length: int, page: int, page_total: int, results: table<content: record, event_type: string, id: string, object_type: string, ocurred_at: string, webhooks: list>>
export def "get-targets-target-id-events" [
  target_id: string
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
    path: "/targets/{target_id}/events/"
    path_params: [{name: target_id, var: target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve target event
#
# GET /targets/{target_id}/events/{id}/
# Returns: record<content: record, event_type: string, id: string, object_type: string, ocurred_at: string, webhooks: table<api_version: string, changed: string, changed_by: record, check_cert: bool, created: string, created_by: record, id: string, name: string, url: string>>
export def "get-targets-target-id-events-id" [
  target_id: string
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
    path: "/targets/{target_id}/events/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List target findings
#
# GET /targets/{target_id}/findings/
# Returns: record<count: int, length: int, page: int, page_total: int, results: table<assignee: record, changed: string, changed_by: record, comment: string, cvss_score: float, cvss_vector: string, definition: record, evidence: string, extra: string, fix: string, id: string, insertion_point: string, labels: list, last_found: string, method: string, parameter: string, params: string, path: string, reporter: record, requests: list, scans: list, severity: string, state: string, target: record, url: string, value: string>>
export def "get-targets-target-id-findings" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scan: list<string> # Filter by scan ids
  --severity: string@severity-completer # Filter by finding severity
  --state: string@state-completer # Filter by finding states
  --assignee: list<string> # Filter by assignee ids
  --label: list<string> # Filter by finding labels
  --page: int # Page number within the paginated result set (e.g. 1)
  --length: int # Number of results to return per page (default: 10)
  --ordering: string # Which field to use when ordering the results, prefix with `-` to invert ordering. (e.g. -changed)
  --search: string # Search term
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/targets/{target_id}/findings/"
    path_params: [{name: target_id, var: target_id}]
    query: [{name: scan, var: scan, style: multi}, {name: severity, var: severity}, {name: state, var: state}, {name: assignee, var: assignee, style: multi}, {name: label, var: label, style: multi}, {name: page, var: page}, {name: length, var: length}, {name: ordering, var: ordering}, {name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, scan: $scan, severity: $severity, state: $state, assignee: $assignee, label: $label, page: $page, length: $length, ordering: $ordering, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Finding report
#
# POST /targets/{target_id}/findings/bulk/report/
export def "post-targets-target-id-findings-bulk-report" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list<string> # Array of finding ids
]: any -> any {
  $in | http-request {
    method: post
    path: "/targets/{target_id}/findings/bulk/report/"
    path_params: [{name: target_id, var: target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk retest findings
#
# POST /targets/{target_id}/findings/bulk/retest/
export def "post-targets-target-id-findings-bulk-retest" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list<string> # Array of finding ids
  --scan-profile: string@scan-profile-completer # * lightning - fast simple scan * normal - default profile * full - does everything the default profile does and adds boolean based SQL injection tests * safe - doesn't use any content changing methods (no POST, DELETE, etc) and tries fewer payloads for SQL injection tests (default: normal, e.g. normal)
]: any -> any {
  $in | http-request {
    method: post
    path: "/targets/{target_id}/findings/bulk/retest/"
    path_params: [{name: target_id, var: target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}, {name: scan_profile, var: scan_profile}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, ids: $ids, scan_profile: $scan_profile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk update findings
#
# PATCH /targets/{target_id}/findings/bulk/update/
export def "patch-targets-target-id-findings-bulk-update" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list<string> # Array of finding ids
  --assignee: record # Assigned user — shape: {email?: string, id?: string, name?: string}
  --comment: string # User comment left on the finding.
  --labels: list<string> # User labels for the finding.
  --severity: string@severity-completer # Severity, how serious the issue is considered: * 10 - low * 20 - medium * 30 - high
  --state: string@state-completer # Finding state: * notfixed - Issue can still be exploited * invalid - Issue determined to be a false positive * accepted - Issue will not be solved and the risk was accepted * fixed - No problem here anymore
]: any -> any {
  $in | http-request {
    method: patch
    path: "/targets/{target_id}/findings/bulk/update/"
    path_params: [{name: target_id, var: target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}, {name: assignee, var: assignee}, {name: comment, var: comment}, {name: labels, var: labels}, {name: severity, var: severity}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, ids: $ids, assignee: $assignee, comment: $comment, labels: $labels, severity: $severity, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve finding report PDF format
#
# GET /targets/{target_id}/findings/report/
# Returns: binary
export def "get-targets-target-id-findings-report" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # Token received from the finding report endpoint. (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/targets/{target_id}/findings/report/"
    path_params: [{name: target_id, var: target_id}]
    query: [{name: token, var: qp_token, required: true}]
    accept: ["application/pdf"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve finding
#
# GET /targets/{target_id}/findings/{id}/
# Returns: record<assignee: record<email: string, id: string, name: string>, changed: string, changed_by: record<email: string, id: string, name: string>, comment: string, cvss_score: float, cvss_vector: string, definition: record<desc: string, id: string, name: string>, evidence: string, extra: string, fix: string, id: string, insertion_point: string, labels: list<string>, last_found: string, method: string, parameter: string, params: string, path: string, reporter: record<email: string, id: string, name: string>, requests: table<request: string, response: string>, scans: list<string>, severity: string, state: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>, url: string, value: string>
export def "get-targets-target-id-findings-id" [
  target_id: string
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
    path: "/targets/{target_id}/findings/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partial update finding
#
# PATCH /targets/{target_id}/findings/{id}/
# Returns: record<assignee: record<email: string, id: string, name: string>, changed: string, changed_by: record<email: string, id: string, name: string>, comment: string, cvss_score: float, cvss_vector: string, definition: record<desc: string, id: string, name: string>, evidence: string, extra: string, fix: string, id: string, insertion_point: string, labels: list<string>, last_found: string, method: string, parameter: string, params: string, path: string, reporter: record<email: string, id: string, name: string>, requests: table<request: string, response: string>, scans: list<string>, severity: string, state: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>, url: string, value: string>
export def "patch-targets-target-id-findings-id" [
  target_id: string
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
  --assignee: record # Assigned user — shape: {email?: string, id?: string, name?: string}
  --comment: string # User comment left on the finding.
  --labels: list<string> # User labels for the finding.
  --severity: string@severity-completer # Severity, how serious the issue is considered: * 10 - low * 20 - medium * 30 - high
  --state: string@state-completer # Finding state: * notfixed - Issue can still be exploited * invalid - Issue determined to be a false positive * accepted - Issue will not be solved and the risk was accepted * fixed - No problem here anymore
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/targets/{target_id}/findings/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: assignee, var: assignee}, {name: comment, var: comment}, {name: labels, var: labels}, {name: severity, var: severity}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id, assignee: $assignee, comment: $comment, labels: $labels, severity: $severity, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update finding
#
# PUT /targets/{target_id}/findings/{id}/
# Returns: record<assignee: record<email: string, id: string, name: string>, changed: string, changed_by: record<email: string, id: string, name: string>, comment: string, cvss_score: float, cvss_vector: string, definition: record<desc: string, id: string, name: string>, evidence: string, extra: string, fix: string, id: string, insertion_point: string, labels: list<string>, last_found: string, method: string, parameter: string, params: string, path: string, reporter: record<email: string, id: string, name: string>, requests: table<request: string, response: string>, scans: list<string>, severity: string, state: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>, url: string, value: string>
export def "put-targets-target-id-findings-id" [
  target_id: string
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
  --assignee: record # Assigned user — shape: {email?: string, id?: string, name?: string}
  --comment: string # User comment left on the finding.
  --labels: list<string> # User labels for the finding.
  --severity: string@severity-completer # Severity, how serious the issue is considered: * 10 - low * 20 - medium * 30 - high
  --state: string@state-completer # Finding state: * notfixed - Issue can still be exploited * invalid - Issue determined to be a false positive * accepted - Issue will not be solved and the risk was accepted * fixed - No problem here anymore
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/targets/{target_id}/findings/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: assignee, var: assignee}, {name: comment, var: comment}, {name: labels, var: labels}, {name: severity, var: severity}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id, assignee: $assignee, comment: $comment, labels: $labels, severity: $severity, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Jira Cloud finding configuration
#
# GET /targets/{target_id}/findings/{id}/integrations/jira-cloud/
# Returns: record<issue_id: string, selective_sync: bool>
export def "get-targets-target-id-findings-id-integrations-jira-cloud" [
  target_id: string
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
    path: "/targets/{target_id}/findings/{id}/integrations/jira-cloud/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Jira Cloud finding configuration
#
# PATCH /targets/{target_id}/findings/{id}/integrations/jira-cloud/
# Returns: record<issue_id: string, selective_sync: bool>
export def "patch-targets-target-id-findings-id-integrations-jira-cloud" [
  target_id: string
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
  --issue-id: string # Jira issue id connected to this finding
  --selective-sync: oneof<nothing, bool> # Selective sync active for this finding.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/targets/{target_id}/findings/{id}/integrations/jira-cloud/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: issue_id, var: issue_id}, {name: selective_sync, var: selective_sync}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id, issue_id: $issue_id, selective_sync: $selective_sync
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Jira Cloud finding configuration
#
# PUT /targets/{target_id}/findings/{id}/integrations/jira-cloud/
# Returns: record<issue_id: string, selective_sync: bool>
export def "put-targets-target-id-findings-id-integrations-jira-cloud" [
  target_id: string
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
  --issue-id: string # Jira issue id connected to this finding
  --selective-sync: oneof<nothing, bool> # Selective sync active for this finding.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/targets/{target_id}/findings/{id}/integrations/jira-cloud/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: issue_id, var: issue_id}, {name: selective_sync, var: selective_sync}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id, issue_id: $issue_id, selective_sync: $selective_sync
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Jira Server finding configuration
#
# GET /targets/{target_id}/findings/{id}/integrations/jira-server/
# Returns: record<issue_id: string, selective_sync: bool>
export def "get-targets-target-id-findings-id-integrations-jira-server" [
  target_id: string
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
    path: "/targets/{target_id}/findings/{id}/integrations/jira-server/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Jira Server finding configuration
#
# PATCH /targets/{target_id}/findings/{id}/integrations/jira-server/
# Returns: record<issue_id: string, selective_sync: bool>
export def "patch-targets-target-id-findings-id-integrations-jira-server" [
  target_id: string
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
  --issue-id: string # Jira issue id connected to this finding
  --selective-sync: oneof<nothing, bool> # Selective sync active for this finding.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/targets/{target_id}/findings/{id}/integrations/jira-server/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: issue_id, var: issue_id}, {name: selective_sync, var: selective_sync}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id, issue_id: $issue_id, selective_sync: $selective_sync
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Jira Server finding configuration
#
# PUT /targets/{target_id}/findings/{id}/integrations/jira-server/
# Returns: record<issue_id: string, selective_sync: bool>
export def "put-targets-target-id-findings-id-integrations-jira-server" [
  target_id: string
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
  --issue-id: string # Jira issue id connected to this finding
  --selective-sync: oneof<nothing, bool> # Selective sync active for this finding.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/targets/{target_id}/findings/{id}/integrations/jira-server/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: issue_id, var: issue_id}, {name: selective_sync, var: selective_sync}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id, issue_id: $issue_id, selective_sync: $selective_sync
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Finding activity log.
#
# GET /targets/{target_id}/findings/{id}/log/
# Returns: table<change: int, changed: string, changed_by: record<email: string, id: string, name: string>, field: string, old_value: string, value: string>
export def "get-targets-target-id-findings-id-log" [
  target_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/targets/{target_id}/findings/{id}/log/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retest finding
#
# POST /targets/{target_id}/findings/{id}/retest/
# Returns: record<changed: string, changed_by: record<email: string, id: string, name: string>, completed: string, crawler: record<error: list<string>, state: string, status: record<"0": int, "1": int>, warning: list<string>>, created: string, created_by: record<email: string, id: string, name: string>, fingerprinter: record<count: int, error: list<string>, state: string, warning: list<string>>, highs: int, id: string, lows: int, mediums: int, scan_profile: string, scanner: record<error: list<string>, state: string, status: record<"0": int, "1": int>, warning: list<string>>, started: string, status: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>>
export def "post-targets-target-id-findings-id-retest" [
  target_id: string
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
    method: post
    path: "/targets/{target_id}/findings/{id}/retest/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Integrations available and installed for the target
#
# GET /targets/{target_id}/integrations/
# Returns: record<available: record<heroku: bool, jira_cloud: bool, jira_server: bool, slack: bool>, installed: record<heroku: bool, jira_cloud: bool, jira_server: bool, slack: bool>>
export def "get-targets-target-id-integrations" [
  target_id: string
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
    path: "/targets/{target_id}/integrations/"
    path_params: [{name: target_id, var: target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Jira Cloud Target configuration
#
# GET /targets/{target_id}/integrations/jira-cloud/
# Returns: record<allow_jira: bool, auto_sync: bool, issue_type_id: string, priority_mapping: record<"10": string, "20": string, "30": string>, project_id: string, status_mapping: record<accepted: string, fixed: string, invalid: string, notfixed: string>>
export def "get-targets-target-id-integrations-jira-cloud" [
  target_id: string
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
    path: "/targets/{target_id}/integrations/jira-cloud/"
    path_params: [{name: target_id, var: target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Jira Cloud target configuration
#
# PATCH /targets/{target_id}/integrations/jira-cloud/
# Returns: record<allow_jira: bool, auto_sync: bool, issue_type_id: string, priority_mapping: record<"10": string, "20": string, "30": string>, project_id: string, status_mapping: record<accepted: string, fixed: string, invalid: string, notfixed: string>>
export def "patch-targets-target-id-integrations-jira-cloud" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-jira: oneof<nothing, bool> # Is this target allowed Jira integration.
  --auto-sync: oneof<nothing, bool> # Automatically synchronise all findings to Jira issues.
  --issue-type-id: string # Id of the issue type to be created in Jira.
  --priority-mapping: record # shape: {10?: string, 20?: string, 30?: string}
  --project-id: string # Id of the Jira project where issues for this target will be created.
  --status-mapping: record # shape: {accepted?: string, fixed?: string, invalid?: string, notfixed?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/targets/{target_id}/integrations/jira-cloud/"
    path_params: [{name: target_id, var: target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allow_jira, var: allow_jira}, {name: auto_sync, var: auto_sync}, {name: issue_type_id, var: issue_type_id}, {name: priority_mapping, var: priority_mapping}, {name: project_id, var: project_id}, {name: status_mapping, var: status_mapping}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, allow_jira: $allow_jira, auto_sync: $auto_sync, issue_type_id: $issue_type_id, priority_mapping: $priority_mapping, project_id: $project_id, status_mapping: $status_mapping
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Jira Cloud target configuration
#
# PUT /targets/{target_id}/integrations/jira-cloud/
# Returns: record<allow_jira: bool, auto_sync: bool, issue_type_id: string, priority_mapping: record<"10": string, "20": string, "30": string>, project_id: string, status_mapping: record<accepted: string, fixed: string, invalid: string, notfixed: string>>
export def "put-targets-target-id-integrations-jira-cloud" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-jira: oneof<nothing, bool> # Is this target allowed Jira integration.
  --auto-sync: oneof<nothing, bool> # Automatically synchronise all findings to Jira issues.
  --issue-type-id: string # Id of the issue type to be created in Jira.
  --priority-mapping: record # shape: {10?: string, 20?: string, 30?: string}
  --project-id: string # Id of the Jira project where issues for this target will be created.
  --status-mapping: record # shape: {accepted?: string, fixed?: string, invalid?: string, notfixed?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/targets/{target_id}/integrations/jira-cloud/"
    path_params: [{name: target_id, var: target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allow_jira, var: allow_jira}, {name: auto_sync, var: auto_sync}, {name: issue_type_id, var: issue_type_id}, {name: priority_mapping, var: priority_mapping}, {name: project_id, var: project_id}, {name: status_mapping, var: status_mapping}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, allow_jira: $allow_jira, auto_sync: $auto_sync, issue_type_id: $issue_type_id, priority_mapping: $priority_mapping, project_id: $project_id, status_mapping: $status_mapping
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Jira Server Target configuration
#
# GET /targets/{target_id}/integrations/jira-server/
# Returns: record<allow_jira: bool, auto_sync: bool, issue_type_id: string, priority_mapping: record<"10": string, "20": string, "30": string>, project_id: string, status_mapping: record<accepted: string, fixed: string, invalid: string, notfixed: string>>
export def "get-targets-target-id-integrations-jira-server" [
  target_id: string
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
    path: "/targets/{target_id}/integrations/jira-server/"
    path_params: [{name: target_id, var: target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Jira Server target configuration
#
# PATCH /targets/{target_id}/integrations/jira-server/
# Returns: record<allow_jira: bool, auto_sync: bool, issue_type_id: string, priority_mapping: record<"10": string, "20": string, "30": string>, project_id: string, status_mapping: record<accepted: string, fixed: string, invalid: string, notfixed: string>>
export def "patch-targets-target-id-integrations-jira-server" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-jira: oneof<nothing, bool> # Is this target allowed Jira integration.
  --auto-sync: oneof<nothing, bool> # Automatically synchronise all findings to Jira issues.
  --issue-type-id: string # Id of the issue type to be created in Jira.
  --priority-mapping: record # shape: {10?: string, 20?: string, 30?: string}
  --project-id: string # Id of the Jira project where issues for this target will be created.
  --status-mapping: record # shape: {accepted?: string, fixed?: string, invalid?: string, notfixed?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/targets/{target_id}/integrations/jira-server/"
    path_params: [{name: target_id, var: target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allow_jira, var: allow_jira}, {name: auto_sync, var: auto_sync}, {name: issue_type_id, var: issue_type_id}, {name: priority_mapping, var: priority_mapping}, {name: project_id, var: project_id}, {name: status_mapping, var: status_mapping}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, allow_jira: $allow_jira, auto_sync: $auto_sync, issue_type_id: $issue_type_id, priority_mapping: $priority_mapping, project_id: $project_id, status_mapping: $status_mapping
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Jira Server target configuration
#
# PUT /targets/{target_id}/integrations/jira-server/
# Returns: record<allow_jira: bool, auto_sync: bool, issue_type_id: string, priority_mapping: record<"10": string, "20": string, "30": string>, project_id: string, status_mapping: record<accepted: string, fixed: string, invalid: string, notfixed: string>>
export def "put-targets-target-id-integrations-jira-server" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-jira: oneof<nothing, bool> # Is this target allowed Jira integration.
  --auto-sync: oneof<nothing, bool> # Automatically synchronise all findings to Jira issues.
  --issue-type-id: string # Id of the issue type to be created in Jira.
  --priority-mapping: record # shape: {10?: string, 20?: string, 30?: string}
  --project-id: string # Id of the Jira project where issues for this target will be created.
  --status-mapping: record # shape: {accepted?: string, fixed?: string, invalid?: string, notfixed?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/targets/{target_id}/integrations/jira-server/"
    path_params: [{name: target_id, var: target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allow_jira, var: allow_jira}, {name: auto_sync, var: auto_sync}, {name: issue_type_id, var: issue_type_id}, {name: priority_mapping, var: priority_mapping}, {name: project_id, var: project_id}, {name: status_mapping, var: status_mapping}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, allow_jira: $allow_jira, auto_sync: $auto_sync, issue_type_id: $issue_type_id, priority_mapping: $priority_mapping, project_id: $project_id, status_mapping: $status_mapping
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve slack integration data
#
# GET /targets/{target_id}/integrations/slack/
# Returns: record<notify_finding_fixed: bool, notify_high_findings: bool, notify_low_findings: bool, notify_medium_findings: bool, notify_scan_completed: bool, notify_scan_started: bool, webhook_url: string>
export def "get-targets-target-id-integrations-slack" [
  target_id: string
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
    path: "/targets/{target_id}/integrations/slack/"
    path_params: [{name: target_id, var: target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update slack integration data
#
# PATCH /targets/{target_id}/integrations/slack/
# Returns: record<notify_finding_fixed: bool, notify_high_findings: bool, notify_low_findings: bool, notify_medium_findings: bool, notify_scan_completed: bool, notify_scan_started: bool, webhook_url: string>
export def "patch-targets-target-id-integrations-slack" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify-finding-fixed: oneof<nothing, bool> # Notify of fixed findings. (default: false)
  --notify-high-findings: oneof<nothing, bool> # Notify of new high severity findings. (default: false)
  --notify-low-findings: oneof<nothing, bool> # Notify of new low severity findings. (default: false)
  --notify-medium-findings: oneof<nothing, bool> # Notify of new medium severity findings. (default: false)
  --notify-scan-completed: oneof<nothing, bool> # Notify of completed scans. (default: false)
  --notify-scan-started: oneof<nothing, bool> # Notify of started scans. (default: false)
  --webhook-url: string # Slack notification webhook url. (default: "")
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/targets/{target_id}/integrations/slack/"
    path_params: [{name: target_id, var: target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: notify_finding_fixed, var: notify_finding_fixed}, {name: notify_high_findings, var: notify_high_findings}, {name: notify_low_findings, var: notify_low_findings}, {name: notify_medium_findings, var: notify_medium_findings}, {name: notify_scan_completed, var: notify_scan_completed}, {name: notify_scan_started, var: notify_scan_started}, {name: webhook_url, var: webhook_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, notify_finding_fixed: $notify_finding_fixed, notify_high_findings: $notify_high_findings, notify_low_findings: $notify_low_findings, notify_medium_findings: $notify_medium_findings, notify_scan_completed: $notify_scan_completed, notify_scan_started: $notify_scan_started, webhook_url: $webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update slack integration data
#
# PUT /targets/{target_id}/integrations/slack/
# Returns: record<notify_finding_fixed: bool, notify_high_findings: bool, notify_low_findings: bool, notify_medium_findings: bool, notify_scan_completed: bool, notify_scan_started: bool, webhook_url: string>
export def "put-targets-target-id-integrations-slack" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify-finding-fixed: oneof<nothing, bool> # Notify of fixed findings. (default: false)
  --notify-high-findings: oneof<nothing, bool> # Notify of new high severity findings. (default: false)
  --notify-low-findings: oneof<nothing, bool> # Notify of new low severity findings. (default: false)
  --notify-medium-findings: oneof<nothing, bool> # Notify of new medium severity findings. (default: false)
  --notify-scan-completed: oneof<nothing, bool> # Notify of completed scans. (default: false)
  --notify-scan-started: oneof<nothing, bool> # Notify of started scans. (default: false)
  --webhook-url: string # Slack notification webhook url. (default: "")
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/targets/{target_id}/integrations/slack/"
    path_params: [{name: target_id, var: target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: notify_finding_fixed, var: notify_finding_fixed}, {name: notify_high_findings, var: notify_high_findings}, {name: notify_low_findings, var: notify_low_findings}, {name: notify_medium_findings, var: notify_medium_findings}, {name: notify_scan_completed, var: notify_scan_completed}, {name: notify_scan_started, var: notify_scan_started}, {name: webhook_url, var: webhook_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, notify_finding_fixed: $notify_finding_fixed, notify_high_findings: $notify_high_findings, notify_low_findings: $notify_low_findings, notify_medium_findings: $notify_medium_findings, notify_scan_completed: $notify_scan_completed, notify_scan_started: $notify_scan_started, webhook_url: $webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List target specific API keys
#
# GET /targets/{target_id}/keys/
# Returns: record<count: int, length: int, page: int, page_total: int, results: table<id: string, key: string, name: string>>
export def "get-targets-target-id-keys" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number within the paginated result set (e.g. 1)
  --length: int # Number of results to return per page (default: 10)
  --ordering: string # Which field to use when ordering the results, prefix with `-` to invert ordering. (e.g. -changed)
  --search: string # Search term
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/targets/{target_id}/keys/"
    path_params: [{name: target_id, var: target_id}]
    query: [{name: page, var: page}, {name: length, var: length}, {name: ordering, var: ordering}, {name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, page: $page, length: $length, ordering: $ordering, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create target API key
#
# POST /targets/{target_id}/keys/
# Returns: record<id: string, key: string, name: string>
export def "post-targets-target-id-keys" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Custom name for the resource (default: "", e.g. Object name)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/targets/{target_id}/keys/"
    path_params: [{name: target_id, var: target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    target_id: $target_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete target API key
#
# DELETE /targets/{target_id}/keys/{id}/
export def "delete-targets-target-id-keys-id" [
  target_id: string
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
    path: "/targets/{target_id}/keys/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve target API key
#
# GET /targets/{target_id}/keys/{id}/
# Returns: record<id: string, key: string, name: string>
export def "get-targets-target-id-keys-id" [
  target_id: string
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
    path: "/targets/{target_id}/keys/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Risk trend graph data
#
# GET /targets/{target_id}/risk_trend/
# Returns: table<"0": string, "1": int>
export def "get-targets-target-id-risk-trend" [
  target_id: string
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
    path: "/targets/{target_id}/risk_trend/"
    path_params: [{name: target_id, var: target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start a scan on the target
#
# POST /targets/{target_id}/scan_now/
# Returns: record<changed: string, changed_by: record<email: string, id: string, name: string>, completed: string, crawler: record<error: list<string>, state: string, status: record<"0": int, "1": int>, warning: list<string>>, created: string, created_by: record<email: string, id: string, name: string>, fingerprinter: record<count: int, error: list<string>, state: string, warning: list<string>>, highs: int, id: string, lows: int, mediums: int, scan_profile: string, scanner: record<error: list<string>, state: string, status: record<"0": int, "1": int>, warning: list<string>>, started: string, status: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>>
export def "post-targets-target-id-scan-now" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scan-profile: string@scan-profile-completer # Override the target's `scan_profile`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/targets/{target_id}/scan_now/"
    path_params: [{name: target_id, var: target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: scan_profile, var: scan_profile}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, scan_profile: $scan_profile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List scans
#
# GET /targets/{target_id}/scans/
# Returns: record<count: int, length: int, page: int, page_total: int, results: table<changed: string, changed_by: record, completed: string, crawler: record, created: string, created_by: record, fingerprinter: record, highs: int, id: string, lows: int, mediums: int, scan_profile: string, scanner: record, started: string, status: string, target: record>>
export def "get-targets-target-id-scans" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number within the paginated result set (e.g. 1)
  --length: int # Number of results to return per page (default: 10)
  --ordering: string # Which field to use when ordering the results, prefix with `-` to invert ordering. (e.g. -changed)
  --search: string # Search term
  --started: list<string> # Filter by scan start dates
  --status: string@status-completer # Filter by scan statuses
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/targets/{target_id}/scans/"
    path_params: [{name: target_id, var: target_id}]
    query: [{name: page, var: page}, {name: length, var: length}, {name: ordering, var: ordering}, {name: search, var: search}, {name: started, var: started, style: multi}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, page: $page, length: $length, ordering: $ordering, search: $search, started: $started, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dates where scans have ocurred
#
# GET /targets/{target_id}/scans/dates/
# Returns: list<string>
export def "get-targets-target-id-scans-dates" [
  target_id: string
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
    path: "/targets/{target_id}/scans/dates/"
    path_params: [{name: target_id, var: target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Scan page
#
# GET /targets/{target_id}/scans/retrieve_page/
# Returns: record<page: int>
export def "get-targets-target-id-scans-retrieve-page" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --length: int # Number of results to return per page (default: 10)
  --date: string # Date (required, format: date)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/targets/{target_id}/scans/retrieve_page/"
    path_params: [{name: target_id, var: target_id}]
    query: [{name: length, var: length}, {name: date, var: date, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, length: $length, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve scan
#
# GET /targets/{target_id}/scans/{id}/
# Returns: record<changed: string, changed_by: record<email: string, id: string, name: string>, completed: string, crawler: record<error: list<string>, state: string, status: record<"0": int, "1": int>, warning: list<string>>, created: string, created_by: record<email: string, id: string, name: string>, fingerprinter: record<count: int, error: list<string>, state: string, warning: list<string>>, highs: int, id: string, lows: int, mediums: int, scan_profile: string, scanner: record<error: list<string>, state: string, status: record<"0": int, "1": int>, warning: list<string>>, started: string, status: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>>
export def "get-targets-target-id-scans-id" [
  target_id: string
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
    path: "/targets/{target_id}/scans/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel running scan
#
# POST /targets/{target_id}/scans/{id}/cancel/
# Returns: record<changed: string, changed_by: record<email: string, id: string, name: string>, completed: string, crawler: record<error: list<string>, state: string, status: record<"0": int, "1": int>, warning: list<string>>, created: string, created_by: record<email: string, id: string, name: string>, fingerprinter: record<count: int, error: list<string>, state: string, warning: list<string>>, highs: int, id: string, lows: int, mediums: int, scan_profile: string, scanner: record<error: list<string>, state: string, status: record<"0": int, "1": int>, warning: list<string>>, started: string, status: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>>
export def "post-targets-target-id-scans-id-cancel" [
  target_id: string
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
    method: post
    path: "/targets/{target_id}/scans/{id}/cancel/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Scan endpoints file
#
# GET /targets/{target_id}/scans/{id}/endpoints/
# Returns: binary
export def "get-targets-target-id-scans-id-endpoints" [
  target_id: string
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
    method: get
    path: "/targets/{target_id}/scans/{id}/endpoints/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/csv"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Scan report PDF, using the report type specified for the target
#
# GET /targets/{target_id}/scans/{id}/report/
# Returns: binary
export def "get-targets-target-id-scans-id-report" [
  target_id: string
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
    method: get
    path: "/targets/{target_id}/scans/{id}/report/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/pdf"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Scan report PDF, using the default report type
#
# GET /targets/{target_id}/scans/{id}/report/default/
# Returns: binary
export def "get-targets-target-id-scans-id-report-default" [
  target_id: string
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
    method: get
    path: "/targets/{target_id}/scans/{id}/report/default/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/pdf"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Scan report PDF, using the OWASP report type
#
# GET /targets/{target_id}/scans/{id}/report/owasp/
# Returns: binary
export def "get-targets-target-id-scans-id-report-owasp" [
  target_id: string
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
    method: get
    path: "/targets/{target_id}/scans/{id}/report/owasp/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/pdf"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Scan report PDF, using the PCI report type
#
# GET /targets/{target_id}/scans/{id}/report/pci/
# Returns: binary
export def "get-targets-target-id-scans-id-report-pci" [
  target_id: string
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
    method: get
    path: "/targets/{target_id}/scans/{id}/report/pci/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/pdf"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List scheduled scans
#
# GET /targets/{target_id}/scheduledscans/
# Returns: record<count: int, length: int, page: int, page_total: int, results: table<changed: string, changed_by: record, date_time: string, id: string, recurrence: string, target: record>>
export def "get-targets-target-id-scheduledscans" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number within the paginated result set (e.g. 1)
  --length: int # Number of results to return per page (default: 10)
  --ordering: string # Which field to use when ordering the results, prefix with `-` to invert ordering. (e.g. -changed)
  --search: string # Search term
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/targets/{target_id}/scheduledscans/"
    path_params: [{name: target_id, var: target_id}]
    query: [{name: page, var: page}, {name: length, var: length}, {name: ordering, var: ordering}, {name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, page: $page, length: $length, ordering: $ordering, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new scheduled scan
#
# POST /targets/{target_id}/scheduledscans/
# Returns: record<changed: string, changed_by: record<email: string, id: string, name: string>, date_time: string, id: string, recurrence: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>>
export def "post-targets-target-id-scheduledscans" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  date_time: string # Date time of next scan (format: date-time)
  --recurrence: string@recurrence-completer # Scan recurrence: * d - daily * w - weekly * m - monthly * q - quarterly * '' - no recurrence
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/targets/{target_id}/scheduledscans/"
    path_params: [{name: target_id, var: target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: date_time, var: date_time}, {name: recurrence, var: recurrence}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    target_id: $target_id, date_time: $date_time, recurrence: $recurrence
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List scheduled scans expanding recurrence
#
# GET /targets/{target_id}/scheduledscans/expanded/
# Returns: record<results: table<changed: string, changed_by: record, date_time: string, id: string, recurrence: string, target: record>>
export def "get-targets-target-id-scheduledscans-expanded" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --length: int # Number of results to return per page (default: 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/targets/{target_id}/scheduledscans/expanded/"
    path_params: [{name: target_id, var: target_id}]
    query: [{name: length, var: length}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, length: $length
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete
#
# DELETE /targets/{target_id}/scheduledscans/{id}/
export def "delete-targets-target-id-scheduledscans-id" [
  target_id: string
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
    path: "/targets/{target_id}/scheduledscans/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a scheduled scan
#
# GET /targets/{target_id}/scheduledscans/{id}/
# Returns: record<changed: string, changed_by: record<email: string, id: string, name: string>, date_time: string, id: string, recurrence: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>>
export def "get-targets-target-id-scheduledscans-id" [
  target_id: string
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
    path: "/targets/{target_id}/scheduledscans/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partial update
#
# PATCH /targets/{target_id}/scheduledscans/{id}/
# Returns: record<changed: string, changed_by: record<email: string, id: string, name: string>, date_time: string, id: string, recurrence: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>>
export def "patch-targets-target-id-scheduledscans-id" [
  target_id: string
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
  date_time: string # Date time of next scan (format: date-time)
  --recurrence: string@recurrence-completer # Scan recurrence: * d - daily * w - weekly * m - monthly * q - quarterly * '' - no recurrence
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/targets/{target_id}/scheduledscans/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: date_time, var: date_time}, {name: recurrence, var: recurrence}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id, date_time: $date_time, recurrence: $recurrence
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a scheduled scan
#
# PUT /targets/{target_id}/scheduledscans/{id}/
# Returns: record<changed: string, changed_by: record<email: string, id: string, name: string>, date_time: string, id: string, recurrence: string, target: record<desc: string, id: string, name: string, stack: list<string>, url: string>>
export def "put-targets-target-id-scheduledscans-id" [
  target_id: string
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
  date_time: string # Date time of next scan (format: date-time)
  --recurrence: string@recurrence-completer # Scan recurrence: * d - daily * w - weekly * m - monthly * q - quarterly * '' - no recurrence
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/targets/{target_id}/scheduledscans/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: date_time, var: date_time}, {name: recurrence, var: recurrence}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id, date_time: $date_time, recurrence: $recurrence
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Severity trend graph data.
#
# GET /targets/{target_id}/severity_trend/
# Returns: record<results: record<high: list<record>, low: list<record>, medium: list<record>>, step: float>
export def "get-targets-target-id-severity-trend" [
  target_id: string
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
    path: "/targets/{target_id}/severity_trend/"
    path_params: [{name: target_id, var: target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve target's site
#
# GET /targets/{target_id}/site/
# DEPRECATED
# Returns: record<basic_auth: record<password: string, username: string>, changed: string, changed_by: record<email: string, id: string, name: string>, cookies: table<name: string, value: string>, desc: string, form_login: table<name: string, value: string>, form_login_check_pattern: string, form_login_url: string, has_basic_auth: bool, has_form_login: bool, headers: table<name: string, value: string>, host: string, id: string, name: string, stack: list<string>, url: string, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool, whitelist: list<string>>
@deprecated
export def "get-targets-target-id-site" [
  target_id: string
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
    path: "/targets/{target_id}/site/"
    path_params: [{name: target_id, var: target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partial update target's site
#
# PATCH /targets/{target_id}/site/
# DEPRECATED
# Returns: record<basic_auth: record<password: string, username: string>, changed: string, changed_by: record<email: string, id: string, name: string>, cookies: table<name: string, value: string>, desc: string, form_login: table<name: string, value: string>, form_login_check_pattern: string, form_login_url: string, has_basic_auth: bool, has_form_login: bool, headers: table<name: string, value: string>, host: string, id: string, name: string, stack: list<string>, url: string, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool, whitelist: list<string>>
@deprecated
export def "patch-targets-target-id-site" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --basic-auth: record # Basic authentication credentials — shape: {password?: string, username?: string}
  --cookies: list # Custom cookies name/value pairs — item shape: {name?: string, value?: string}
  --desc: string # Custom description for the resource (default: "", e.g. Object description)
  --form-login: list # Form login field name, field input pairs — item shape: {name?: string, value?: string}
  --form-login-check-pattern: string # Pattern to check successful authentication (not used) (default: "")
  --form-login-url: string # URL for the form login (default: "", e.g. https://app.probely.com/)
  --has-basic-auth: oneof<nothing, bool> # Use basic authentication in scan (default: false, e.g. true)
  --has-form-login: oneof<nothing, bool> # Does the resource use form login (default: false, e.g. true)
  --headers: list # Custom headers name value pairs — item shape: {name?: string, value?: string}
  --name: string # Custom name for the resource (default: "", e.g. Object name)
  --url: string # Site URL, it should include the path if the site is not located at the root. This URL can only be set once. (format: URL, default: "", e.g. https://app.probely.com)
  --whitelist: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/targets/{target_id}/site/"
    path_params: [{name: target_id, var: target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: basic_auth, var: basic_auth}, {name: cookies, var: cookies}, {name: desc, var: desc}, {name: form_login, var: form_login}, {name: form_login_check_pattern, var: form_login_check_pattern}, {name: form_login_url, var: form_login_url}, {name: has_basic_auth, var: has_basic_auth}, {name: has_form_login, var: has_form_login}, {name: headers, var: headers}, {name: name, var: name}, {name: url, var: url}, {name: whitelist, var: whitelist}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, basic_auth: $basic_auth, cookies: $cookies, desc: $desc, form_login: $form_login, form_login_check_pattern: $form_login_check_pattern, form_login_url: $form_login_url, has_basic_auth: $has_basic_auth, has_form_login: $has_form_login, headers: $headers, name: $name, url: $url, whitelist: $whitelist
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update target's site
#
# PUT /targets/{target_id}/site/
# DEPRECATED
# Returns: record<basic_auth: record<password: string, username: string>, changed: string, changed_by: record<email: string, id: string, name: string>, cookies: table<name: string, value: string>, desc: string, form_login: table<name: string, value: string>, form_login_check_pattern: string, form_login_url: string, has_basic_auth: bool, has_form_login: bool, headers: table<name: string, value: string>, host: string, id: string, name: string, stack: list<string>, url: string, verification_date: string, verification_last_error: string, verification_method: string, verification_token: string, verified: bool, whitelist: list<string>>
@deprecated
export def "put-targets-target-id-site" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --basic-auth: record # Basic authentication credentials — shape: {password?: string, username?: string}
  --cookies: list # Custom cookies name/value pairs — item shape: {name?: string, value?: string}
  --desc: string # Custom description for the resource (default: "", e.g. Object description)
  --form-login: list # Form login field name, field input pairs — item shape: {name?: string, value?: string}
  --form-login-check-pattern: string # Pattern to check successful authentication (not used) (default: "")
  --form-login-url: string # URL for the form login (default: "", e.g. https://app.probely.com/)
  --has-basic-auth: oneof<nothing, bool> # Use basic authentication in scan (default: false, e.g. true)
  --has-form-login: oneof<nothing, bool> # Does the resource use form login (default: false, e.g. true)
  --headers: list # Custom headers name value pairs — item shape: {name?: string, value?: string}
  --name: string # Custom name for the resource (default: "", e.g. Object name)
  --url: string # Site URL, it should include the path if the site is not located at the root. This URL can only be set once. (format: URL, default: "", e.g. https://app.probely.com)
  --whitelist: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/targets/{target_id}/site/"
    path_params: [{name: target_id, var: target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: basic_auth, var: basic_auth}, {name: cookies, var: cookies}, {name: desc, var: desc}, {name: form_login, var: form_login}, {name: form_login_check_pattern, var: form_login_check_pattern}, {name: form_login_url, var: form_login_url}, {name: has_basic_auth, var: has_basic_auth}, {name: has_form_login, var: has_form_login}, {name: headers, var: headers}, {name: name, var: name}, {name: url, var: url}, {name: whitelist, var: whitelist}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, basic_auth: $basic_auth, cookies: $cookies, desc: $desc, form_login: $form_login, form_login_check_pattern: $form_login_check_pattern, form_login_url: $form_login_url, has_basic_auth: $has_basic_auth, has_form_login: $has_form_login, headers: $headers, name: $name, url: $url, whitelist: $whitelist
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify site ownership
#
# POST /targets/{target_id}/site/verify/
# DEPRECATED
# Returns: record<message: string>
@deprecated
export def "post-targets-target-id-site-verify" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-1 # Type of verification: * dns - we look or a TXT record on the host you registered containing `Probely=<verification_token>` * file - on the root of the path you registered we look for a file named `` containing `Probely`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/targets/{target_id}/site/verify/"
    path_params: [{name: target_id, var: target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Top 5 vulnerabilities
#
# GET /targets/{target_id}/top_vulns/
# Returns: table<"0": string, "1": string>
export def "get-targets-target-id-top-vulns" [
  target_id: string
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
    path: "/targets/{target_id}/top_vulns/"
    path_params: [{name: target_id, var: target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List target webhooks
#
# GET /targets/{target_id}/webhooks/
# Returns: record<count: int, length: int, page: int, page_total: int, results: table<api_version: string, changed: string, changed_by: record, check_cert: bool, created: string, created_by: record, id: string, name: string, url: string>>
export def "get-targets-target-id-webhooks" [
  target_id: string
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
    path: "/targets/{target_id}/webhooks/"
    path_params: [{name: target_id, var: target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new target webhook
#
# POST /targets/{target_id}/webhooks/
# Returns: record<api_version: string, changed: string, changed_by: record<email: string, id: string, name: string>, check_cert: bool, created: string, created_by: record<email: string, id: string, name: string>, id: string, name: string, url: string>
export def "post-targets-target-id-webhooks" [
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # API version for the webhook
  --check-cert: oneof<nothing, bool> # Verify webhook URL HTTPS certificate
  --name: string # Custom name for the resource (default: "", e.g. Object name)
  url: string # URL to post events to (must be https)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/targets/{target_id}/webhooks/"
    path_params: [{name: target_id, var: target_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: api_version, var: api_version}, {name: check_cert, var: check_cert}, {name: name, var: name}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    target_id: $target_id, api_version: $api_version, check_cert: $check_cert, name: $name, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete target webhook
#
# DELETE /targets/{target_id}/webhooks/{id}/
export def "delete-targets-target-id-webhooks-id" [
  target_id: string
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
    path: "/targets/{target_id}/webhooks/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve target webhook
#
# GET /targets/{target_id}/webhooks/{id}/
# Returns: record<api_version: string, changed: string, changed_by: record<email: string, id: string, name: string>, check_cert: bool, created: string, created_by: record<email: string, id: string, name: string>, id: string, name: string, url: string>
export def "get-targets-target-id-webhooks-id" [
  target_id: string
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
    path: "/targets/{target_id}/webhooks/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partial update target webhook
#
# PATCH /targets/{target_id}/webhooks/{id}/
# Returns: record<api_version: string, changed: string, changed_by: record<email: string, id: string, name: string>, check_cert: bool, created: string, created_by: record<email: string, id: string, name: string>, id: string, name: string, url: string>
export def "patch-targets-target-id-webhooks-id" [
  target_id: string
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
  --api-version: string@api-version-completer # API version for the webhook
  --check-cert: oneof<nothing, bool> # Verify webhook URL HTTPS certificate
  --name: string # Custom name for the resource (default: "", e.g. Object name)
  url: string # URL to post events to (must be https)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/targets/{target_id}/webhooks/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: api_version, var: api_version}, {name: check_cert, var: check_cert}, {name: name, var: name}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id, api_version: $api_version, check_cert: $check_cert, name: $name, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update target webhook
#
# PUT /targets/{target_id}/webhooks/{id}/
# Returns: record<api_version: string, changed: string, changed_by: record<email: string, id: string, name: string>, check_cert: bool, created: string, created_by: record<email: string, id: string, name: string>, id: string, name: string, url: string>
export def "put-targets-target-id-webhooks-id" [
  target_id: string
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
  --api-version: string@api-version-completer # API version for the webhook
  --check-cert: oneof<nothing, bool> # Verify webhook URL HTTPS certificate
  --name: string # Custom name for the resource (default: "", e.g. Object name)
  url: string # URL to post events to (must be https)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/targets/{target_id}/webhooks/{id}/"
    path_params: [{name: target_id, var: target_id}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: api_version, var: api_version}, {name: check_cert, var: check_cert}, {name: name, var: name}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, id: $id, api_version: $api_version, check_cert: $check_cert, name: $name, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List users
#
# GET /users/
# Returns: record<count: int, length: int, page: int, page_total: int, results: table<changed: string, changed_by: record, email: string, id: string, is_active: bool, is_admin: bool, is_billing_admin: bool, name: string, title: string>>
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
  --page: int # Page number within the paginated result set (e.g. 1)
  --length: int # Number of results to return per page (default: 10)
  --ordering: string # Which field to use when ordering the results, prefix with `-` to invert ordering. (e.g. -changed)
  --search: string # Search term
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/"
    query: [{name: page, var: page}, {name: length, var: length}, {name: ordering, var: ordering}, {name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, length: $length, ordering: $ordering, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create/Reactivate a user.
#
# POST /users/
# Returns: record<changed: string, changed_by: record<email: string, id: string, name: string>, email: string, id: string, is_active: bool, is_admin: bool, is_billing_admin: bool, name: string, title: string>
export def "post-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # User's email (changing this resets the user's password and revokes existing tokens) (e.g. example@probely.com)
  name: string # User's name (e.g. Henrique Cimento)
  --title: string@title-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: name, var: name}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    email: $email, name: $name, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate a user
#
# DELETE /users/{id}/
export def "delete-users-id" [
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
    path: "/users/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve user
#
# GET /users/{id}/
# Returns: record<changed: string, changed_by: record<email: string, id: string, name: string>, email: string, id: string, is_active: bool, is_admin: bool, is_billing_admin: bool, name: string, title: string>
export def "get-users-id" [
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
    path: "/users/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partial update user
#
# PATCH /users/{id}/
# Returns: record<changed: string, changed_by: record<email: string, id: string, name: string>, email: string, id: string, is_active: bool, is_admin: bool, is_billing_admin: bool, name: string, title: string>
export def "patch-users-id" [
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
  email: string # User's email (changing this resets the user's password and revokes existing tokens) (e.g. example@probely.com)
  name: string # User's name (e.g. Henrique Cimento)
  --title: string@title-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{id}/"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: name, var: name}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, email: $email, name: $name, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update user
#
# PUT /users/{id}/
# Returns: record<changed: string, changed_by: record<email: string, id: string, name: string>, email: string, id: string, is_active: bool, is_admin: bool, is_billing_admin: bool, name: string, title: string>
export def "put-users-id" [
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
  email: string # User's email (changing this resets the user's password and revokes existing tokens) (e.g. example@probely.com)
  name: string # User's name (e.g. Henrique Cimento)
  --title: string@title-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{id}/"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: name, var: name}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, email: $email, name: $name, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List vulnerability definitions
#
# GET /vulnerability_definitions/
# Returns: record<count: int, length: int, page: int, page_total: int, results: table<changed: string, desc: string, id: string, name: string>>
export def "get-vulnerability-definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number within the paginated result set (e.g. 1)
  --length: int # Number of results to return per page (default: 10)
  --ordering: string # Which field to use when ordering the results, prefix with `-` to invert ordering. (e.g. -changed)
  --search: string # Search term
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/vulnerability_definitions/"
    query: [{name: page, var: page}, {name: length, var: length}, {name: ordering, var: ordering}, {name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, length: $length, ordering: $ordering, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve vulnerability definition
#
# GET /vulnerability_definitions/{id}/
# Returns: record<changed: string, desc: string, id: string, name: string>
export def "get-vulnerability-definitions-id" [
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
    path: "/vulnerability_definitions/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List account webhooks
#
# GET /webhooks/
# Returns: record<count: int, length: int, page: int, page_total: int, results: table<api_version: string, changed: string, changed_by: record, check_cert: bool, created: string, created_by: record, id: string, name: string, url: string>>
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
    path: "/webhooks/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new account webhook
#
# POST /webhooks/
# Returns: record<api_version: string, changed: string, changed_by: record<email: string, id: string, name: string>, check_cert: bool, created: string, created_by: record<email: string, id: string, name: string>, id: string, name: string, url: string>
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
  --api-version: string@api-version-completer # API version for the webhook
  --check-cert: oneof<nothing, bool> # Verify webhook URL HTTPS certificate
  --name: string # Custom name for the resource (default: "", e.g. Object name)
  url: string # URL to post events to (must be https)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks/"
    body: {content_type: "application/json", kind: json, fields: [{name: api_version, var: api_version}, {name: check_cert, var: check_cert}, {name: name, var: name}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_version: $api_version, check_cert: $check_cert, name: $name, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete account webhook
#
# DELETE /webhooks/{id}/
export def "delete-webhooks-id" [
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
    path: "/webhooks/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve account webhook
#
# GET /webhooks/{id}/
# Returns: record<api_version: string, changed: string, changed_by: record<email: string, id: string, name: string>, check_cert: bool, created: string, created_by: record<email: string, id: string, name: string>, id: string, name: string, url: string>
export def "get-webhooks-id" [
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
    path: "/webhooks/{id}/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partial update account webhook
#
# PATCH /webhooks/{id}/
# Returns: record<api_version: string, changed: string, changed_by: record<email: string, id: string, name: string>, check_cert: bool, created: string, created_by: record<email: string, id: string, name: string>, id: string, name: string, url: string>
export def "patch-webhooks-id" [
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
  --api-version: string@api-version-completer # API version for the webhook
  --check-cert: oneof<nothing, bool> # Verify webhook URL HTTPS certificate
  --name: string # Custom name for the resource (default: "", e.g. Object name)
  url: string # URL to post events to (must be https)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/webhooks/{id}/"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: api_version, var: api_version}, {name: check_cert, var: check_cert}, {name: name, var: name}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, api_version: $api_version, check_cert: $check_cert, name: $name, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update account webhook
#
# PUT /webhooks/{id}/
# Returns: record<api_version: string, changed: string, changed_by: record<email: string, id: string, name: string>, check_cert: bool, created: string, created_by: record<email: string, id: string, name: string>, id: string, name: string, url: string>
export def "put-webhooks-id" [
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
  --api-version: string@api-version-completer # API version for the webhook
  --check-cert: oneof<nothing, bool> # Verify webhook URL HTTPS certificate
  --name: string # Custom name for the resource (default: "", e.g. Object name)
  url: string # URL to post events to (must be https)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/webhooks/{id}/"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: api_version, var: api_version}, {name: check_cert, var: check_cert}, {name: name, var: name}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, api_version: $api_version, check_cert: $check_cert, name: $name, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
