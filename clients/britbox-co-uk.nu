# Auto-generated client for Rocket Services v3.730.300-ref-1-39-0
# Source: https://api.apis.guru/v2/specs/britbox.co.uk/3.730.300-ref-1-39-0/openapi.json
# Auth: --token flag or $env.ROCKET_SERVICES_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru/api"
  token_env_var: "ROCKET_SERVICES_TOKEN"
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

def base-url-completer [] { ["https://api.apis.guru/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["Card"] }
def resolution-completer [] { ["External" "HD-1080" "HD-4K" "HD-720" "SD"] }
def order-completer [] { ["asc" "desc"] }
def item-type-completer [] { ["channel" "customAsset" "episode" "link" "movie" "program" "season" "show" "trailer"] }
def show-item-type-completer [] { ["episode" "season" "show"] }
def expand-completer [] { ["ancestors" "parent"] }
def order-by-completer [] { ["date-added" "date-modified"] }
def cookie-type-completer [] { ["Persistent" "Session"] }
def provider-completer [] { ["Facebook"] }
def expand-completer-1 [] { ["all" "ancestors" "children" "parent"] }
def select-season-completer [] { ["first" "latest"] }
def item-detail-expand-completer [] { ["all" "ancestors" "children"] }
def item-detail-select-season-completer [] { ["first" "latest"] }
def text-entry-format-completer [] { ["html" "markdown"] }
def order-by-completer-1 [] { ["a-z" "date-added" "release-year"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-account: "record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postcode: string, state: string>, defaultPaymentInstrumentId: string, defaultPaymentMethodId: string, emailVerified: bool, entitlements: table<deliveryType: string, exclusionRules: list, maxDownloads: int, maxPlays: int, ownership: string, playPeriod: int, rentalPeriod: int, resolution: string, scopes: list, activationDate: string, classification: record, creationDate: string, expirationDate: string, itemId: string, itemType: string, mediaDuration: int, planId: string, playCount: int, remainingDownloads: int>, firstName: string, id: string, isFirstTimeSubscriber: bool, lastName: string, marketingEnabled: bool, minRatingPlaybackGuard: string, pinEnabled: bool, primaryProfileId: string, profiles: table<color: string, heroAutoplay: bool, heroWithAudio: bool, id: string, isActive: bool, languageCode: string, marketingEnabled: bool, maxRatingContentFilter: record, minRatingPlaybackGuard: record, name: string, pinEnabled: bool, purchaseEnabled: bool, segments: list>, segments: list<string>, subscriptionCode: string, subscriptions: table<code: string, endDate: string, id: string, isTrialPeriod: bool, planId: string, startDate: string, status: string>, trackingEnabled: bool, usedFreeTrial: bool>"
    get-payment-methods: "table<balance: float, brand: string, currency: string, description: string, expiryMonth: float, expiryYear: float, id: string, lastDigits: float, type: string>"
    add-payment-method: "record<balance: float, brand: string, currency: string, description: string, expiryMonth: float, expiryYear: float, id: string, lastDigits: float, type: string>"
    get-payment-method: "record<balance: float, brand: string, currency: string, description: string, expiryMonth: float, expiryYear: float, id: string, lastDigits: float, type: string>"
    get-purchases: "table<authorizationDate: string, creationDate: string, currency: string, id: string, item: record<id: string, ownership: string, resolution: string, title: string, type: string>, paymentMethodId: string, plan: record<id: string, price: float, subscriptionId: string, title: string, type: string>, total: float>"
    make-purchase: "record<deliveryType: string, exclusionRules: table<description: string, device: string, excludeAirplay: bool, excludeChromecast: bool, excludeDelivery: string, excludeMinResolution: string>, maxDownloads: int, maxPlays: int, ownership: string, playPeriod: int, rentalPeriod: int, resolution: string, scopes: list<string>, activationDate: string, classification: record<code: string, name: string>, creationDate: string, expirationDate: string, itemId: string, itemType: string, mediaDuration: int, planId: string, playCount: int, remainingDownloads: int>"
    get-devices: "record<deregistrationWindow: record<endDate: string, limit: int, periodDays: int, remaining: int, startDate: string>, devices: table<id: string, name: string, registrationDate: string, type: string>, maxRegistered: int, registrationWindow: record<endDate: string, limit: int, periodDays: int, remaining: int, startDate: string>>"
    register-device: "record<id: string, name: string, registrationDate: string, type: string>"
    get-device: "record<id: string, name: string, registrationDate: string, type: string>"
    get-entitlements: "table<deliveryType: string, exclusionRules: list<record>, maxDownloads: int, maxPlays: int, ownership: string, playPeriod: int, rentalPeriod: int, resolution: string, scopes: list<string>, activationDate: string, classification: record<code: string, name: string>, creationDate: string, expirationDate: string, itemId: string, itemType: string, mediaDuration: int, planId: string, playCount: int, remainingDownloads: int>"
    get-item-media-files: "table<channels: int, deliveryType: string, drm: string, format: string, height: int, language: string, name: string, resolution: string, url: string, width: int>"
    get-item-media-files-guarded: "table<channels: int, deliveryType: string, drm: string, format: string, height: int, language: string, name: string, resolution: string, url: string, width: int>"
    generate-nonce: "record<value: string>"
    get-profile: "record<color: string, heroAutoplay: bool, heroWithAudio: bool, id: string, isActive: bool, languageCode: string, marketingEnabled: bool, maxRatingContentFilter: record<code: string, name: string>, minRatingPlaybackGuard: record<code: string, name: string>, name: string, pinEnabled: bool, purchaseEnabled: bool, segments: list<string>, bookmarked: record, rated: record, watched: record>"
    get-bookmarks: "record"
    get-bookmark-list: "record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string>"
    get-item-bookmark: "record<creationDate: string, itemId: string>"
    bookmark-item: "record<creationDate: string, itemId: string>"
    get-continue-watching-list: "record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string>"
    get-next-playback-item: "record<firstWatchedDate: string, lastWatchedDate: string, next: record<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record<code: string, name: string>, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list<string>, hasClosedCaptions: bool, id: string, images: record, offers: list<record>, path: string, releaseYear: int, scopes: list<string>, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list<record>, title: string, type: string, watchPath: string, copyright: string, credits: list<record>, customMetadata: list<record>, description: string, distributor: string, episodes: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, eventDate: string, genrePaths: list<string>, location: string, season: any, seasons: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, show: any, totalUserRatings: int, trailers: list<record>, venue: string>, sourceItemId: string, suggestionType: string>"
    get-ratings: "record"
    get-ratings-list: "record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string>"
    get-item-rating: "record<itemId: string, rating: int>"
    rate-item: "record<itemId: string, rating: int>"
    get-watched: "record"
    get-watched-list: "record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string>"
    get-item-watched-status: "record<firstWatchedDate: string, isFullyWatched: bool, itemId: string, lastWatchedDate: string, position: int>"
    set-item-watched-status: "record<firstWatchedDate: string, isFullyWatched: bool, itemId: string, lastWatchedDate: string, position: int>"
    create-profile: "record<color: string, heroAutoplay: bool, heroWithAudio: bool, id: string, isActive: bool, languageCode: string, marketingEnabled: bool, maxRatingContentFilter: record<code: string, name: string>, minRatingPlaybackGuard: record<code: string, name: string>, name: string, pinEnabled: bool, purchaseEnabled: bool, segments: list<string>, bookmarked: record, rated: record, watched: record>"
    get-profile-with-id: "record<color: string, heroAutoplay: bool, heroWithAudio: bool, id: string, isActive: bool, languageCode: string, marketingEnabled: bool, maxRatingContentFilter: record<code: string, name: string>, minRatingPlaybackGuard: record<code: string, name: string>, name: string, pinEnabled: bool, purchaseEnabled: bool, segments: list<string>>"
    get-account-token: "table<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string>"
    get-account-token-by-code: "table<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string>"
    generate-device-authorization-code: "record<code: string>"
    get-profile-token: "table<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string>"
    refresh-token: "record<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string>"
    single-sign-on: "table<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string>"
    get-plan-by-token: "record<amount: float, ctaText: string, currency: string, description: string, ees07PlanDescription: string, ees07PlanTitle: string, ees07Title: string, headerText: string, heroText: string, id: string, interval: string, intervalCount: int, longText: string, nickname: string, noThanksText: string, product: string, switchingText: string, termsAndConditionsItunes: string, termsAndConditionsStripe: string, trialPeriodDays: int>"
    get-plans: "record<plans: table<amount: float, ctaText: string, currency: string, description: string, ees07PlanDescription: string, ees07PlanTitle: string, ees07Title: string, headerText: string, heroText: string, id: string, interval: string, intervalCount: int, longText: string, nickname: string, noThanksText: string, product: string, switchingText: string, termsAndConditionsItunes: string, termsAndConditionsStripe: string, trialPeriodDays: int>>"
    get-subscription-data: "record<itvData_purchased: record>"
    get-app-config: "record<classification: record, display: record<themes: list<record>>, general: record<currencyCode: string, customFields: record, defaultTimeZone: string, facebookAppId: string, gaToken: string, itemImageTypes: record, mandatorySignIn: bool, maxUserRating: int, stripeKey: string, websiteUrl: string>, i18n: record<languages: list<record>>, linear: record<scheduleCacheMaxAgeMinutes: int, viewingWindowDaysAfter: int, viewingWindowDaysBefore: int>, navigation: record<account: record<children: list, content: record, customFields: record, depth: int, featured: bool, icon: string, label: string, path: string>, copyright: string, customFields: record, footer: record<children: list, content: record, customFields: record, depth: int, featured: bool, icon: string, label: string, path: string>, header: list<record>, mobile: record<children: list, content: record, customFields: record, depth: int, featured: bool, icon: string, label: string, path: string>>, playback: record<chainPlayCountdown: int, chainPlaySqueezeback: int, chainPlayTimeout: int, heartbeatFrequency: int, viewEventPoints: list<float>>, sitemap: table<id: string, isStatic: bool, isSystemPage: bool, key: string, path: string, template: string, title: string>, subscription: record<plans: list<record>>>"
    check-ee-bt-eligibility: "record<eligible: bool, plan: string, source: string>"
    get-eligible-offers: "record<eligibleOffers: table<name: string>>"
    validate-pin-request: "record<pinValid: string, trackingHeader: string>"
    create-pin-request: "record<pinReference: string, trackingHeader: string>"
    get-ee-plans: "record<plans: table<amount: float, ctaText: string, currency: string, description: string, headerText: string, heroText: string, id: string, interval: string, intervalCount: int, longText: string, nickname: string, product: string, trialPeriodDays: int>>"
    get-plan: "record<amount: float, ctaText: string, currency: string, description: string, headerText: string, heroText: string, id: string, interval: string, intervalCount: int, longText: string, nickname: string, product: string, trialPeriodDays: int>"
    create-token: "record<accessToken: string, expiresIn: float, tokenType: string>"
    get-item: "record<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record<code: string, name: string>, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list<string>, hasClosedCaptions: bool, id: string, images: record, offers: table<deliveryType: string, exclusionRules: list, maxDownloads: int, maxPlays: int, ownership: string, playPeriod: int, rentalPeriod: int, resolution: string, scopes: list, availability: string, customFields: record, endDate: string, id: string, name: string, price: float, startDate: string, subscriptionCode: string>, path: string, releaseYear: int, scopes: list<string>, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: table<colors: list, type: string>, title: string, type: string, watchPath: string, copyright: string, credits: table<name: string, path: string, character: string, role: string>, customMetadata: table<name: string, value: string>, description: string, distributor: string, episodes: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, eventDate: string, genrePaths: list<string>, location: string, season: any, seasons: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, show: any, totalUserRatings: int, trailers: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, venue: string>"
    get-item-children-list: "record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string>"
    get-item-related-list: "record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string>"
    get-public-item-media-files: "table<channels: int, deliveryType: string, drm: string, format: string, height: int, language: string, name: string, resolution: string, url: string, width: int>"
    get-anon-next-playback-item: "record<firstWatchedDate: string, lastWatchedDate: string, next: record<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record<code: string, name: string>, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list<string>, hasClosedCaptions: bool, id: string, images: record, offers: list<record>, path: string, releaseYear: int, scopes: list<string>, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list<record>, title: string, type: string, watchPath: string, copyright: string, credits: list<record>, customMetadata: list<record>, description: string, distributor: string, episodes: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, eventDate: string, genrePaths: list<string>, location: string, season: any, seasons: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, show: any, totalUserRatings: int, trailers: list<record>, venue: string>, sourceItemId: string, suggestionType: string>"
    get-billing-history: "record<payment_history: table<card: record, charge: record, invoice: record, subscription: record>>"
    get-card-details: "record<card_type: string, exp_month: int, exp_year: int, last4: string>"
    get-current-entitlement: "record<source: string>"
    get-entitlements-history: "record<cancellations: table<cancelled_at: string, itvId: string, source: string, subscriptionId: string>, entitlements: table<card_type: string, expiry: string, plan: record, source: string, subscriptionId: string>>"
    get-feature-flag: "record<enabled: bool, flag: string>"
    check-previous-entitlements: "record<hasHadEntitlements: bool>"
    get-items-media-clip-files: "record<items: table<clips: list, id: string>>"
    get-item-downloadables: "record<items: table<downloadable: bool, id: string>>"
    get-itv-page: "record<id: string, isStatic: bool, isSystemPage: bool, key: string, path: string, template: string, title: string, customFields: record, entries: table<customFields: record, id: string, images: record, item: record, list: record, people: list, template: string, text: string, title: string, type: string>, item: record<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record<code: string, name: string>, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list<string>, hasClosedCaptions: bool, id: string, images: record, offers: list<record>, path: string, releaseYear: int, scopes: list<string>, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list<record>, title: string, type: string, watchPath: string, copyright: string, credits: list<record>, customMetadata: list<record>, description: string, distributor: string, episodes: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, eventDate: string, genrePaths: list<string>, location: string, season: any, seasons: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, show: any, totalUserRatings: int, trailers: list<record>, venue: string>, list: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, metadata: record<description: string, keywords: list<string>, segments: list<string>>, themes: table<colors: list, type: string>>"
    get-account-token-with-pin: "table<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string>"
    get-itv-plans-platform: "record<plans: table<amount: float, currency: string, description: string, id: string, interval: string, intervalCount: int, nickname: string, product: string, savingLabel: string, switchingText: string, trialPeriodDays: int>>"
    get-itv-profile: "record"
    get-recommended-list: "record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string>"
    get-itv-profile-token: "record<profileToken: string>"
    get-current-subscription: "record<cancelAtPeriodEnd: bool, collectionMethod: string, created: int, currentPeriodEnd: int, currentPeriodStart: int, plan: record, status: string>"
    confirm-purchase: "record<customerId: string, planId: string, subscriptionId: string>"
    confirm-purchase-strong: "record<clientSecret: string, customerId: string, intentId: string, intentType: string, planId: string, status: string, subscriptionId: string>"
    confirm-purchase-with-offer: "record<clientSecret: string, customerId: string, intentId: string, intentType: string, paymentMethodId: string, status: string, subscriptionId: string>"
    resubscribe: "record"
    get-itv-roku-plans: "record<plans: table<amount: float, currency: string, description: string, interval: string, intervalCount: int, nickname: string, product: string, productCode: string, savingLabel: string, trialPeriodDays: int>, termsAndConditions: string>"
    get-save-offer: "record<currency: string, description: string, headline: string, id: string, initialCost: float, longDescription: string, nickname: string, offerdurationperiod: string, shortDescription: string>"
    get-full-price-renewal: "record<fullPriceRenewal: bool, reason: string>"
    get-subscription-status: "record<is_active: bool>"
    get-subscription-state: "record<effective_entitlements: table<card_type: string, expiry: string, plan: record, source: string, subscriptionId: string>, failed_availability_checks: list<string>, purchased: list<string>, source: string>"
    get-upcoming-invoice: "record<currency: string, description: string, headline: string, id: string, initialCost: float, longDescription: string, nickname: string, offerdurationperiod: string, shortDescription: string>"
    update-payment-intent-strong: "record<clientSecret: string, intentId: string, intentType: string, status: string>"
    get-voucher-by-id: "record<display: record<currency: string, discountPrice: string, duration: string, durationInMonths: float, headlineLabel: string, initialCost: float, longDescription: string, percentOff: float, savingLabel: string, shortDescription: string>, id: string, links: record<redeem: record<href: string>, self: record<href: string>>, offerType: string>"
    check-voucher: "record<display: record<currency: string, discountPrice: string, duration: string, durationInMonths: float, headlineLabel: string, initialCost: float, longDescription: string, percentOff: float, savingLabel: string, shortDescription: string>, id: string, links: record<redeem: record<href: string>, self: record<href: string>>, offerType: string>"
    get-lists: "table<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>"
    get-list: "record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string>"
    get-page: "record<id: string, isStatic: bool, isSystemPage: bool, key: string, path: string, template: string, title: string, customFields: record, entries: table<customFields: record, id: string, images: record, item: record, list: record, people: list, template: string, text: string, title: string, type: string>, item: record<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record<code: string, name: string>, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list<string>, hasClosedCaptions: bool, id: string, images: record, offers: list<record>, path: string, releaseYear: int, scopes: list<string>, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list<record>, title: string, type: string, watchPath: string, copyright: string, credits: list<record>, customMetadata: list<record>, description: string, distributor: string, episodes: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, eventDate: string, genrePaths: list<string>, location: string, season: any, seasons: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, show: any, totalUserRatings: int, trailers: list<record>, venue: string>, list: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, metadata: record<description: string, keywords: list<string>, segments: list<string>>, themes: table<colors: list, type: string>>"
    get-plans-id: "record<alias: string, benefits: list<string>, billingPeriodFrequency: int, billingPeriodType: string, currency: string, customFields: record, hasTrialPeriod: bool, id: string, isActive: bool, isFeatured: bool, isPrivate: bool, price: float, revenueType: string, subscriptionCode: string, tagline: string, termsAndConditions: string, title: string, trialPeriodDays: int, type: string>"
    register: "table<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string>"
    get-public-preview: "record<expires: int, expires_only: bool, sections: table<position: int, tiles: list, title: string>>"
    get-schedules: "table<channelId: string, endDate: string, schedules: list<record>, startDate: string>"
    search: "record<items: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, movies: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, other: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, people: table<name: string, path: string>, term: string, total: int, tv: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-account" "update-account" "get-payment-methods" "add-payment-method" "remove-payment-method" "get-payment-method" "get-purchases" "make-purchase" "cancel-subscription" "update-subscription" "get-devices" "register-device" "authorize-device" "deregister-device" "get-device" "rename-device" "get-entitlements" "get-item-media-files" "get-item-media-files-guarded" "generate-nonce" "change-password" "change-pin" "get-profile" "get-bookmarks" "get-bookmark-list" "delete-item-bookmark" "get-item-bookmark" "bookmark-item" "get-continue-watching-list" "get-next-playback-item" "get-ratings" "get-ratings-list" "get-item-rating" "rate-item" "delete-watched" "get-watched" "get-watched-list" "get-item-watched-status" "set-item-watched-status" "create-profile" "delete-profile-with-id" "get-profile-with-id" "update-profile-with-id" "request-email-verification" "sign-out" "get-account-token" "get-account-token-by-code" "generate-device-authorization-code" "get-profile-token" "refresh-token" "single-sign-on" "get-plan-by-token" "get-plans" "assign-token" "check-user-token" "get-subscription-data" "get-app-config" "check-ee-bt-eligibility" "assign-msisdn" "get-eligible-offers" "validate-pin-request" "create-pin-request" "get-ee-plans" "get-plan" "create-token" "get-item" "get-item-children-list" "get-item-related-list" "get-public-item-media-files" "get-anon-next-playback-item" "get-billing-history" "get-card-details" "change-card-details" "change-email" "change-marketing" "delete-account" "get-current-entitlement" "get-entitlements-history" "get-feature-flag" "google-pay-subscription" "check-previous-entitlements" "get-items-media-clip-files" "get-item-downloadables" "get-itv-itemsummary-external-id" "get-itv-page" "get-account-token-with-pin" "upgrade-plan" "get-itv-plans-platform" "get-itv-profile" "update-profile" "get-recommended-list" "get-itv-profile-token" "delete-itv-purchase-platform" "get-current-subscription" "confirm-purchase" "confirm-purchase-strong" "confirm-purchase-with-offer" "resubscribe" "get-itv-roku-plans" "execute-transaction" "get-save-offer" "activate-save-offer" "get-full-price-renewal" "get-subscription-status" "get-subscription-state" "get-upcoming-invoice" "update-payment-intent-strong" "update-payment-method-strong" "get-voucher-by-id" "check-voucher" "get-lists" "get-list" "get-page" "get-plans-id" "register" "forgot-password" "reset-password" "get-public-preview" "get-schedules" "search" "verify-email" "commands"] | sort) } | get name | first)
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

# Get the details of an account along with the profiles and entitlements under it.
#
# GET /account
# Returns: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postcode: string, state: string>, defaultPaymentInstrumentId: string, defaultPaymentMethodId: string, emailVerified: bool, entitlements: table<deliveryType: string, exclusionRules: list, maxDownloads: int, maxPlays: int, ownership: string, playPeriod: int, rentalPeriod: int, resolution: string, scopes: list, activationDate: string, classification: record, creationDate: string, expirationDate: string, itemId: string, itemType: string, mediaDuration: int, planId: string, playCount: int, remainingDownloads: int>, firstName: string, id: string, isFirstTimeSubscriber: bool, lastName: string, marketingEnabled: bool, minRatingPlaybackGuard: string, pinEnabled: bool, primaryProfileId: string, profiles: table<color: string, heroAutoplay: bool, heroWithAudio: bool, id: string, isActive: bool, languageCode: string, marketingEnabled: bool, maxRatingContentFilter: record, minRatingPlaybackGuard: record, name: string, pinEnabled: bool, purchaseEnabled: bool, segments: list>, segments: list<string>, subscriptionCode: string, subscriptions: table<code: string, endDate: string, id: string, isTrialPeriod: bool, planId: string, startDate: string, status: string>, trackingEnabled: bool, usedFreeTrial: bool>
# operationId: getAccount
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
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the details of an account. With the exception of the address, this supports partial updates, so you can send just the properties you wish to update. When the address is provided any properties which are omitted from the address will be cleared.
#
# PATCH /account
# operationId: updateAccount
export def "update-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postcode?: string, state?: string}
  --default-payment-instrument-id: string # The id of the payment instrument to use by default for account transactions. **DEPRECATED** The property `defaultPaymentMethodId` is now preferred.
  --default-payment-method-id: string # The id of the payment method to use by default for account transactions.
  --first-name: string # The first name of the account holder.
  --last-name: string # The last name of the account holder.
  --min-rating-playback-guard: string # The classification rating defining the minimum rating level a user should be forced to enter the account pin code for playback. Anything at this rating level or above will require the pin for playback. e.g. AUOFLC-MA15+ If you want to disable this guard pass an empty string or `null`.
  --segments: list<string> # The segments an account should be placed under
  --tracking-enabled: oneof<nothing, bool> # Whether usage tracking is associated with an account or anonymous.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/account"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: defaultPaymentInstrumentId, var: default_payment_instrument_id}, {name: defaultPaymentMethodId, var: default_payment_method_id}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: minRatingPlaybackGuard, var: min_rating_playback_guard}, {name: segments, var: segments}, {name: trackingEnabled, var: tracking_enabled}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ff: $ff, lang: $lang, address: $address, default_payment_instrument_id: $default_payment_instrument_id, default_payment_method_id: $default_payment_method_id, first_name: $first_name, last_name: $last_name, min_rating_playback_guard: $min_rating_playback_guard, segments: $segments, tracking_enabled: $tracking_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the available payment methods under an account.
#
# GET /account/billing/methods
# Returns: table<balance: float, brand: string, currency: string, description: string, expiryMonth: float, expiryYear: float, id: string, lastDigits: float, type: string>
# operationId: getPaymentMethods
export def "get-payment-methods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/billing/methods"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new payment method to an account.
#
# POST /account/billing/methods
# Returns: record<balance: float, brand: string, currency: string, description: string, expiryMonth: float, expiryYear: float, id: string, lastDigits: float, type: string>
# operationId: addPaymentMethod
export def "add-payment-method" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --make-default: oneof<nothing, bool> # Whether this payment method should become the account default when making purchases. Note that if this is the first payment method of type Card being added to an account then it will become the default whether this property is true or false.
  --body-token: string # The payment provider token representing a payment method, obtained by submitting payment method details to your third party provider. (spec name: token)
  type: string@type-completer # The type of payment method.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/billing/methods"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: makeDefault, var: make_default}, {name: token, var: body_token, required: true}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang, make_default: $make_default, body_token: $body_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a payment method from an account.
#
# DELETE /account/billing/methods/{id}
# operationId: removePaymentMethod
export def "remove-payment-method" [
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
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> any {
  http-request {
    method: delete
    path: "/account/billing/methods/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a payment method under an account.
#
# GET /account/billing/methods/{id}
# Returns: record<balance: float, brand: string, currency: string, description: string, expiryMonth: float, expiryYear: float, id: string, lastDigits: float, type: string>
# operationId: getPaymentMethod
export def "get-payment-method" [
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
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/billing/methods/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all purchases made under an account.
#
# GET /account/billing/purchases
# Returns: table<authorizationDate: string, creationDate: string, currency: string, id: string, item: record<id: string, ownership: string, resolution: string, title: string, type: string>, paymentMethodId: string, plan: record<id: string, price: float, subscriptionId: string, title: string, type: string>, total: float>
# operationId: getPurchases
export def "get-purchases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/billing/purchases"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Purchase a plan or item offer. The result of a successful transaction is a new entitlement.
#
# POST /account/billing/purchases
# Returns: record<deliveryType: string, exclusionRules: table<description: string, device: string, excludeAirplay: bool, excludeChromecast: bool, excludeDelivery: string, excludeMinResolution: string>, maxDownloads: int, maxPlays: int, ownership: string, playPeriod: int, rentalPeriod: int, resolution: string, scopes: list<string>, activationDate: string, classification: record<code: string, name: string>, creationDate: string, expirationDate: string, itemId: string, itemType: string, mediaDuration: int, planId: string, playCount: int, remainingDownloads: int>
# operationId: makePurchase
export def "make-purchase" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --item-id: string # The identifier of the item to purchase. Both `itemId` and `offerId` are required for item purchases.
  --offer-id: string # The identifier of the item offer to purchase. Both `itemId` and `offerId` are required for item purchases.
  --payment-method-id: string # The identifier of the payment method to use. If omitted, or if purchasing a plan, the default payment method will be used.
  --plan-id: string # The identifier of the plan to purchase.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/billing/purchases"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: itemId, var: item_id}, {name: offerId, var: offer_id}, {name: paymentMethodId, var: payment_method_id}, {name: planId, var: plan_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang, item_id: $item_id, offer_id: $offer_id, payment_method_id: $payment_method_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel a plan subscription. A cancelled subscription will continue to be valid until the subscription expiry date or next renewal date.
#
# DELETE /account/billing/subscriptions/{id}
# operationId: cancelSubscription
export def "cancel-subscription" [
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
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> any {
  http-request {
    method: delete
    path: "/account/billing/subscriptions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Renew a cancelled subscription or switch subscription to a different plan. When renewing a cancelled subscription membership, hit this endpoint with the id of subscription to renew. To switch plans provide the id of the current active subscription membership of the account, and in the query specify the id of the plan to switch to.
#
# PUT /account/billing/subscriptions/{id}
# operationId: updateSubscription
export def "update-subscription" [
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
  --plan-id: string # The id of the plan to switch to if switching plans.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> any {
  http-request {
    method: put
    path: "/account/billing/subscriptions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: planId, var: plan_id}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, plan_id: $plan_id, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all devices registered under this account. Also includes information around device registration and deregistration limits.
#
# GET /account/devices
# Returns: record<deregistrationWindow: record<endDate: string, limit: int, periodDays: int, remaining: int, startDate: string>, devices: table<id: string, name: string, registrationDate: string, type: string>, maxRegistered: int, registrationWindow: record<endDate: string, limit: int, periodDays: int, remaining: int, startDate: string>>
# operationId: getDevices
export def "get-devices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/devices"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a playback device under an account. If a device with the same id already exists a `409` conflict will be returned.
#
# POST /account/devices
# Returns: record<id: string, name: string, registrationDate: string, type: string>
# operationId: registerDevice
export def "register-device" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  id: string # The unique identifier for this device e.g. serial number.
  name: string # A human recognisable name for this device.
  type: string # The device type e.g. web_browser.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/devices"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang, id: $id, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authorize a device from a generated device authorization code. This is the second step in the process of authorizing a device by pin code. Firstly the device must request a generated authorization code via the `/authorization/device/code` endpoint. This endpoint then authorizes the device associated with the code to sign in to a user account. Typically this endpoint will be called from a page presented in the web app under the account section. Once authorized, the device will then be able to sign in to that account via the `/authorization/device` endpoint, without needing to provide the credentials of the user.
#
# POST /account/devices/authorization
# operationId: authorizeDevice
export def "authorize-device" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  code: string # The generated device authorization code.
]: any -> any {
  $in | http-request {
    method: post
    path: "/account/devices/authorization"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ff: $ff, lang: $lang, code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deregister a playback device from an account.
#
# DELETE /account/devices/{id}
# operationId: deregisterDevice
export def "deregister-device" [
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
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> any {
  http-request {
    method: delete
    path: "/account/devices/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a registered device.
#
# GET /account/devices/{id}
# Returns: record<id: string, name: string, registrationDate: string, type: string>
# operationId: getDevice
export def "get-device" [
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
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/devices/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rename a device
#
# PUT /account/devices/{id}/name
# operationId: renameDevice
export def "rename-device" [
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
  --name: string # The new name for the device. (required)
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> any {
  http-request {
    method: put
    path: "/account/devices/{id}/name"
    path_params: [{name: id, var: id}]
    query: [{name: name, var: name, required: true}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, name: $name, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all entitlements under the account. This list is returned under the call to get account information so a call here is only required when wishing to refresh a local copy of entitlements.
#
# GET /account/entitlements
# Returns: table<deliveryType: string, exclusionRules: list<record>, maxDownloads: int, maxPlays: int, ownership: string, playPeriod: int, rentalPeriod: int, resolution: string, scopes: list<string>, activationDate: string, classification: record<code: string, name: string>, creationDate: string, expirationDate: string, itemId: string, itemType: string, mediaDuration: int, planId: string, playCount: int, remainingDownloads: int>
# operationId: getEntitlements
export def "get-entitlements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/entitlements"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the video files associated with an item given maximum resolution, device type and one or more delivery types. This endpoint accepts an Account Catalog token, however if when requesting playback files you receive an *403 status code with error code 1* then the file you're requesting is classification restricted. This means you should switch to target the `/account/items/{id}/videos-guarded` endpoint, passing it an Account Playback token. If not already obtained, this token can be requested via the `/itv/pinauthorization` endpoint with an account level pin. For convenience you may also access free / public files through this endpoint instead of the /items/{id}/videos endpoint, when authenticated. Returns an array of video file objects which each include a url to a video. The first entry in the array contains what is predicted to be the best match. The remainder of the entries, if any, may contain resolutions below what was requests. For example if you request HD-720 the response may also contain SD entries. If you specify multiple delivery types, then the response array will insert types in the order you specify them in the query. For example `stream,progressive` would return an array with 0 or more stream files followed by 0 or more progressive files. If no files are found a 404 is returned.
#
# GET /account/items/{id}/videos
# Returns: table<channels: int, deliveryType: string, drm: string, format: string, height: int, language: string, name: string, resolution: string, url: string, width: int>
# operationId: getItemMediaFiles
export def "get-item-media-files" [
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
  --delivery: list<string> # The video delivery type you require. (required)
  --resolution: string@resolution-completer # The maximum resolution the device to playback the media can present. (required)
  --formats: list<string> # The set of media file formats that the device supports, in the order of preference. When provided, Rocket API returns only media files in formats specified in this parameter. For each resolution, only the first media file of matching supported format is returned. Files of different resolutions may be of different supported media file formats. `external` value is reserved for project customizations where the real MIME type of the file on the specified URL is unknown at the time of ingestion. When not provided, Rocket API uses the legacy `User-Agent` header-based logic to find matching media files.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/items/{id}/videos"
    path_params: [{name: id, var: id}]
    query: [{name: delivery, var: delivery, style: csv, required: true}, {name: resolution, var: resolution, required: true}, {name: formats, var: formats, style: csv}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, delivery: $delivery, resolution: $resolution, formats: $formats, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the video files associated with an item given maximum resolution, device type and one or more delivery types. This endpoint is identical to the `/account/items/{id}/videos` however it expects an Account Playback token. This token, and in association this endpoint, is specifically for use when playback files are classification restricted and require an account level pin to access them. Returns an array of video file objects which each include a url to a video. The first entry in the array contains what is predicted to be the best match. The remainder of the entries, if any, may contain resolutions below what was requests. For example if you request HD-720 the response may also contain SD entries. If you specify multiple delivery types, then the response array will insert types in the order you specify them in the query. For example `stream,progressive` would return an array with 0 or more stream files followed by 0 or more progressive files. If no files are found a 404 is returned.
#
# GET /account/items/{id}/videos-guarded
# Returns: table<channels: int, deliveryType: string, drm: string, format: string, height: int, language: string, name: string, resolution: string, url: string, width: int>
# operationId: getItemMediaFilesGuarded
export def "get-item-media-files-guarded" [
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
  --delivery: list<string> # The video delivery type you require. (required)
  --resolution: string@resolution-completer # The maximum resolution the device to playback the media can present. (required)
  --formats: list<string> # The set of media file formats that the device supports, in the order of preference. When provided, Rocket API returns only media files in formats specified in this parameter. For each resolution, only the first media file of matching supported format is returned. Files of different resolutions may be of different supported media file formats. `external` value is reserved for project customizations where the real MIME type of the file on the specified URL is unknown at the time of ingestion. When not provided, Rocket API uses the legacy `User-Agent` header-based logic to find matching media files.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/items/{id}/videos-guarded"
    path_params: [{name: id, var: id}]
    query: [{name: delivery, var: delivery, style: csv, required: true}, {name: resolution, var: resolution, required: true}, {name: formats, var: formats, style: csv}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, delivery: $delivery, resolution: $resolution, formats: $formats, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate a new account nonce. A nonce may be required to help sign a response from a third party service which will be passed back to these services. For example a Facebook single-sign-on request initiated by a client application may first get a nonce from here to include in the request. Facebook will then include the nonce in the auth token it issues. This token can be passed back to our services and the nonce checked for validity.
#
# GET /account/nonce
# Returns: record<value: string>
# operationId: generateNonce
export def "generate-nonce" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/nonce"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change the password of an account. The expected token scope is Settings.
#
# PUT /account/password
# operationId: changePassword
export def "change-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  password: string # The new password for the account.
  profile_token: string # The ITV profile token.
]: any -> any {
  $in | http-request {
    method: put
    path: "/account/password"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: profileToken, var: profile_token}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ff: $ff, lang: $lang, password: $password, profile_token: $profile_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change the pin of an account.
#
# PUT /account/pin
# operationId: changePin
export def "change-pin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  pin: string # The new pin to set.
]: any -> any {
  $in | http-request {
    method: put
    path: "/account/pin"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: pin, var: pin}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ff: $ff, lang: $lang, pin: $pin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the details of the active profile, including watched, bookmarked and rated items.
#
# GET /account/profile
# Returns: record<color: string, heroAutoplay: bool, heroWithAudio: bool, id: string, isActive: bool, languageCode: string, marketingEnabled: bool, maxRatingContentFilter: record<code: string, name: string>, minRatingPlaybackGuard: record<code: string, name: string>, name: string, pinEnabled: bool, purchaseEnabled: bool, segments: list<string>, bookmarked: record, rated: record, watched: record>
# operationId: getProfile
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
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/profile"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the map of bookmarked item ids (itemId => creationDate) under the active profile.
#
# GET /account/profile/bookmarks
# Returns: record
# operationId: getBookmarks
export def "get-bookmarks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/profile/bookmarks"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of bookmarked items under the active profile.
#
# GET /account/profile/bookmarks/list
# Returns: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string>
# operationId: getBookmarkList
export def "get-bookmark-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of items to load. Starts from page 1. (format: int32)
  --page-size: int # The number of items to return in a page. (format: int32)
  --order: string@order-completer # The list sort order, either 'asc' or 'desc'. (default: desc)
  --item-type: string@item-type-completer # The item type to filter by. Defaults to unspecified.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/profile/bookmarks/list"
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: order, var: order}, {name: item_type, var: item_type}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size, order: $order, item_type: $item_type, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unbookmark an item under the active profile.
#
# DELETE /account/profile/bookmarks/{itemId}
# operationId: deleteItemBookmark
export def "delete-item-bookmark" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> any {
  http-request {
    method: delete
    path: "/account/profile/bookmarks/{itemId}"
    path_params: [{name: itemId, var: item_id}]
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    item_id: $item_id, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the bookmark for an item under the active profile.
#
# GET /account/profile/bookmarks/{itemId}
# Returns: record<creationDate: string, itemId: string>
# operationId: getItemBookmark
export def "get-item-bookmark" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/profile/bookmarks/{itemId}"
    path_params: [{name: itemId, var: item_id}]
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bookmark an item under the active profile. Creates one if it doesn't exist, overwrites one if it does.
#
# PUT /account/profile/bookmarks/{itemId}
# Returns: record<creationDate: string, itemId: string>
# operationId: bookmarkItem
export def "bookmark-item" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/account/profile/bookmarks/{itemId}"
    path_params: [{name: itemId, var: item_id}]
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of items which have been watched but not completed under the active profile. Multiple episodes under the same show may be watched or in progress, however only a single item belonging to a particular show will be included in the returned list. The next episode to continue watching for a particular show will be the most recent incompletely watched episode, or the next episode following the most recently completely watched episode. Based on the specified `show_item_type` type, either the next episode, the season of the next episode, or the show will be included in the list.
#
# GET /account/profile/continue-watching/list
# Returns: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string>
# operationId: getContinueWatchingList
export def "get-continue-watching-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-item-type: string@show-item-type-completer # The item type to be returned for continue watching items belonging to a show. Multiple episodes under the same show may be watched or in progress, however only a single item belonging to a particular show will be included in the returned list. The next episode to continue watching for a particular show will be the most recent incompletely watched episode, or the next episode following the most recently completely watched episode. Based on the specified `show_item_type` type, either the next episode, the season of the next episode, or the show will be included in the list. If `episode` is specified, then only the next episode to continue watching for a show will be returned. If `season` is specified, then only the season of the next episode will be returned. If `show` is specified, then only the show of the next episode will be returned The recommended value of this parameter should reflect the desitination the user will be sent to when they select this item in the list. So if a user will be sent to the show detail page then this should be `show` and you can use the `include` parameter to get metadata about the episode or season if needed (default: episode)
  --include: list<string> # Include one opr more ancestor/children for items belonging to a show. Extra items will be populated in the `listData` property of the list If no value is specified no dependencies are included. If `episode` is specified, then the next episode will be added for season/show items. Has no effect if `show_item_type` is set to `episode`. If `season` is specified, then the season of the next episode will be added for episode/show items. Has no effect if `show_item_type` is set to `season`. If `show` is specified, then the show of the next episode will be added for episode/season items. Has no effect if `show_item_type` is set to `show`. (default: [])
  --page: int # The page of items to load. Starts from page 1. (format: int32, default: 1)
  --page-size: int # The number of items to return in a page. (format: int32, default: 12)
  --max-rating: string # The maximum rating (inclusive) of an item returned, e.g. 'auoflc-pg'.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/profile/continue-watching/list"
    query: [{name: show_item_type, var: show_item_type}, {name: include, var: include, style: csv}, {name: page, var: page}, {name: page_size, var: page_size}, {name: max_rating, var: max_rating}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    show_item_type: $show_item_type, include: $include, page: $page, page_size: $page_size, max_rating: $max_rating, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the next item to play given a source item id. For an unwatched show it returns the first episode available to the account. For a watched show it returns the last incompletely watched episode by the profile, or the episode that immediately follows the last completely watched episode or nothing. For an episode it always returns the immediately following episode, if available to the account, or nothing. If the response does not contain a `next` property then no item was found.
#
# GET /account/profile/items/{itemId}/next
# Returns: record<firstWatchedDate: string, lastWatchedDate: string, next: record<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record<code: string, name: string>, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list<string>, hasClosedCaptions: bool, id: string, images: record, offers: list<record>, path: string, releaseYear: int, scopes: list<string>, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list<record>, title: string, type: string, watchPath: string, copyright: string, credits: list<record>, customMetadata: list<record>, description: string, distributor: string, episodes: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, eventDate: string, genrePaths: list<string>, location: string, season: any, seasons: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, show: any, totalUserRatings: int, trailers: list<record>, venue: string>, sourceItemId: string, suggestionType: string>
# operationId: getNextPlaybackItem
export def "get-next-playback-item" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-rating: string # The maximum rating (inclusive) of an item returned, e.g. 'auoflc-pg'.
  --expand: string@expand-completer # If no value is specified no dependencies are expanded. If 'parent' is specified then only the direct parent will be expanded. For example if an `Episode` then the `Season` would be included. If 'ancestors' is specified then the full parent chain is expanded. For example if an `Episode` then both the `Season` and `Show` would be included.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/profile/items/{itemId}/next"
    path_params: [{name: itemId, var: item_id}]
    query: [{name: max_rating, var: max_rating}, {name: expand, var: expand}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id, max_rating: $max_rating, expand: $expand, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the map of rated item ids (itemId => rating out of 10) under the active profile.
#
# GET /account/profile/ratings
# Returns: record
# operationId: getRatings
export def "get-ratings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/profile/ratings"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of rated items under the active profile.
#
# GET /account/profile/ratings/list
# Returns: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string>
# operationId: getRatingsList
export def "get-ratings-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of items to load. Starts from page 1. (format: int32, default: 1)
  --page-size: int # The number of items to return in a page. (format: int32, default: 12)
  --order: string@order-completer # The list sort order, either 'asc' or 'desc'. (default: desc)
  --order-by: string@order-by-completer # What to order by. Ordering by `date-modified` equates to ordering by the last rated date. (default: date-added)
  --item-type: string@item-type-completer # The item type to filter by. Defaults to unspecified.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/profile/ratings/list"
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: order, var: order}, {name: order_by, var: order_by}, {name: item_type, var: item_type}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size, order: $order, order_by: $order_by, item_type: $item_type, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the rating info for an item under the active profile.
#
# GET /account/profile/ratings/{itemId}
# Returns: record<itemId: string, rating: int>
# operationId: getItemRating
export def "get-item-rating" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/profile/ratings/{itemId}"
    path_params: [{name: itemId, var: item_id}]
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rate an item under the active profile. Creates one if it doesn't exist, overwrites one if it does.
#
# PUT /account/profile/ratings/{itemId}
# Returns: record<itemId: string, rating: int>
# operationId: rateItem
export def "rate-item" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rating: int # The item rating between 1 and 10 inclusive. (required, format: int32)
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/account/profile/ratings/{itemId}"
    path_params: [{name: itemId, var: item_id}]
    query: [{name: rating, var: rating, required: true}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id, rating: $rating, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove the watched status of items under the active profile. Passing in specific `itemId`s to the `item_ids` query parameter will cause only these items to be removed. **If this list is missing all watched items will be removed**
#
# DELETE /account/profile/watched
# operationId: deleteWatched
export def "delete-watched" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --item-ids: list<string> # List of `itemId`s to delete. Omit this parameter to delete all items
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> any {
  http-request {
    method: delete
    path: "/account/profile/watched"
    query: [{name: item_ids, var: item_ids, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    item_ids: $item_ids, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the map of watched item ids (itemId => last playhead position) under the active profile.
#
# GET /account/profile/watched
# Returns: record
# operationId: getWatched
export def "get-watched" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/profile/watched"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of watched items under the active profile.
#
# GET /account/profile/watched/list
# Returns: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string>
# operationId: getWatchedList
export def "get-watched-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of items to load. Starts from page 1. (format: int32, default: 1)
  --page-size: int # The number of items to return in a page. (format: int32, default: 12)
  --completed: oneof<nothing, bool> # Filter by whether an item has been fully watched (completed) or not. If `undefined` then both partially and fully watched items are returned.
  --order: string@order-completer # The list sort order, either 'asc' or 'desc'. (default: desc)
  --order-by: string@order-by-completer # What to order by. Ordering by `date-modified` equates to ordering by the last watched date. (default: date-added)
  --item-type: string@item-type-completer # The item type to filter by. Defaults to unspecified.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/profile/watched/list"
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: completed, var: completed}, {name: order, var: order}, {name: order_by, var: order_by}, {name: item_type, var: item_type}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size, completed: $completed, order: $order, order_by: $order_by, item_type: $item_type, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the watched status info for an item under the active profile.
#
# GET /account/profile/watched/{itemId}
# Returns: record<firstWatchedDate: string, isFullyWatched: bool, itemId: string, lastWatchedDate: string, position: int>
# operationId: getItemWatchedStatus
export def "get-item-watched-status" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/profile/watched/{itemId}"
    path_params: [{name: itemId, var: item_id}]
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Record the watched playhead position of a video under the active profile. Can be used later to resume a video from where it was last watched. Creates one if it doesn't exist, overwrites one if it does.
#
# PUT /account/profile/watched/{itemId}
# Returns: record<firstWatchedDate: string, isFullyWatched: bool, itemId: string, lastWatchedDate: string, position: int>
# operationId: setItemWatchedStatus
export def "set-item-watched-status" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: int # The playhead position to record. (required, format: int32)
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/account/profile/watched/{itemId}"
    path_params: [{name: itemId, var: item_id}]
    query: [{name: position, var: position, required: true}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    item_id: $item_id, position: $position, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new profile under the active account.
#
# POST /account/profiles
# Returns: record<color: string, heroAutoplay: bool, heroWithAudio: bool, id: string, isActive: bool, languageCode: string, marketingEnabled: bool, maxRatingContentFilter: record<code: string, name: string>, minRatingPlaybackGuard: record<code: string, name: string>, name: string, pinEnabled: bool, purchaseEnabled: bool, segments: list<string>, bookmarked: record, rated: record, watched: record>
# operationId: createProfile
export def "create-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --language-code: string # The code of the preferred language for the profile. Must be a valid ISO language code e.g. "en-US" and must match the code of one of the languages specified in the app config. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  name: string # The unique name of the profile.
  --pin-enabled: oneof<nothing, bool> # Whether an account pin is required to enter the profile. If no account pin is defined this has no impact. (default: false)
  --purchase-enabled: oneof<nothing, bool> # Whether the profile can make purchases with the account payment options. (default: true)
  --segments: list<string> # The segments a profile should be placed under
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/profiles"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: languageCode, var: language_code}, {name: name, var: name}, {name: pinEnabled, var: pin_enabled}, {name: purchaseEnabled, var: purchase_enabled}, {name: segments, var: segments}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    ff: $ff, lang: $lang, language_code: $language_code, name: $name, pin_enabled: $pin_enabled, purchase_enabled: $purchase_enabled, segments: $segments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a profile with a specific id under the active account. Note that you cannot delete the primary profile.
#
# DELETE /account/profiles/{id}
# operationId: deleteProfileWithId
export def "delete-profile-with-id" [
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
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> any {
  http-request {
    method: delete
    path: "/account/profiles/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the summary of a profile with a specific id under the active account.
#
# GET /account/profiles/{id}
# Returns: record<color: string, heroAutoplay: bool, heroWithAudio: bool, id: string, isActive: bool, languageCode: string, marketingEnabled: bool, maxRatingContentFilter: record<code: string, name: string>, minRatingPlaybackGuard: record<code: string, name: string>, name: string, pinEnabled: bool, purchaseEnabled: bool, segments: list<string>>
# operationId: getProfileWithId
export def "get-profile-with-id" [
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
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/profiles/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the summary of a profile with a specific id under the active account. This supports partial updates so you can send just the properties you wish to update.
#
# PATCH /account/profiles/{id}
# operationId: updateProfileWithId
export def "update-profile-with-id" [
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
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --hero-autoplay: oneof<nothing, bool> # Sets the Hero row clip auto playback enabled
  --hero-with-audio: oneof<nothing, bool> # Sets the Hero row clip auto playback audio enabled
  --language-code: string # The code of the preferred language for the profile. Must be a valid ISO language code e.g. "en-US" and must match the code of one of the languages specified in the app config. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --name: string # The unique name of the profile.
  --pin-enabled: oneof<nothing, bool> # Whether an account pin is required to enter the profile. If no account pin is defined this has no impact.
  --purchase-enabled: oneof<nothing, bool> # Whether the profile can make purchases with the account payment options.
  --segments: list<string> # The segments a profile should be placed under
]: any -> any {
  $in | http-request {
    method: patch
    path: "/account/profiles/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: heroAutoplay, var: hero_autoplay}, {name: heroWithAudio, var: hero_with_audio}, {name: languageCode, var: language_code}, {name: name, var: name}, {name: pinEnabled, var: pin_enabled}, {name: purchaseEnabled, var: purchase_enabled}, {name: segments, var: segments}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, ff: $ff, lang: $lang, hero_autoplay: $hero_autoplay, hero_with_audio: $hero_with_audio, language_code: $language_code, name: $name, pin_enabled: $pin_enabled, purchase_enabled: $purchase_enabled, segments: $segments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request that the email address tied to an account be verified. This will send a verification email to the email address of the primary profile containing a link which, once clicked, completes the verification process via the /verify-email endpoint. Note that when an account is created this email is sent automatically so there's no need to call this directly. If the user doesn't click the link before it expires then this endpoint can be called to request a new verification email. In the future it may also be used if we add support for changing an account email address.
#
# POST /account/request-email-verification
# operationId: requestEmailVerification
export def "request-email-verification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> any {
  http-request {
    method: post
    path: "/account/request-email-verification"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# When a user signs out of an application we need to clear some basic cookies we assigned them during token authorization.
#
# DELETE /authorization
# operationId: signOut
export def "sign-out" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> any {
  http-request {
    method: delete
    path: "/authorization"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request one or more `Account` level authorization tokens each with a chosen scope. Tokens are used to access restricted service endpoints. These restricted endpoints will require a specific token type (e.g Account) with a specific scope (e.g. Catalog) before access is granted. For convenience, where a Profile level token with the same scope exists it will also be returned. Authorization with pin is not supported on this endpoint anymore. Use `/itv/pinauthorization` endpoint instead.
#
# POST /authorization
# Returns: table<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string>
# operationId: getAccountToken
export def "get-account-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --cookie-type: string@cookie-type-completer # If you specify a cookie type then a content filter cookie will be returned along with the token(s). This is only intended for web based clients which need to pass the cookies to a server to render a page based on the user's content filters e.g subscription code. If type `Session` the cookie will be session based. If type `Persistent` the cookie will have a medium term lifespan. If undefined no cookies will be set.
  email: string # The email associated with the account.
  password: string # The password associated with the account.
  scopes: list<string> # The scope(s) of the tokens required. For each scope listed an Account and Profile token of that scope will be returned
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/authorization"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: cookieType, var: cookie_type}, {name: email, var: email}, {name: password, var: password}, {name: scopes, var: scopes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang, cookie_type: $cookie_type, email: $email, password: $password, scopes: $scopes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Catalog tokens for an account using a device authorization code. Where a Profile level token of Catalog scope exists it will also be returned. This is the final step in the process of authorizing a device by pin code. Firstly the device must request a generated authorization code via the `/authorization/device/code` endpoint. The code is subsequently used to authorize the device to sign in to a given account via the `/account/devices/authorization` endpoint. Typically this will be from a page presented in the web app under the account section. Once authorized, this endpoint will allow the device to sign in without needing to provide the credentials of the user.
#
# POST /authorization/device
# Returns: table<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string>
# operationId: getAccountTokenByCode
export def "get-account-token-by-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  code: string # The generated device authorization code.
  id: string # The unique identifier for the device e.g. serial number.
  scopes: list<string> # The scope(s) of the token(s) required.
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/authorization/device"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: id, var: id}, {name: scopes, var: scopes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang, code: $code, id: $id, scopes: $scopes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a generated device authorization code. This is the first step in the process of authorizing a device by pin code. The device will make a request to this endpoint providing a unique identifier for the device such as a serial number. This endpoint will then return a generated code which is tied to the given device. The code may subsequently be used to authorize the device to sign in to an account via the `/account/devices/authorization` endpoint. Typically this will be from a page presented in the web app under the account section. Once authorized, the device will then be able to sign in to that account via the `/authorization/device` endpoint, without needing to provide the credentials of the user.
#
# POST /authorization/device/code
# Returns: record<code: string>
# operationId: generateDeviceAuthorizationCode
export def "generate-device-authorization-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  id: string # The unique identifier for this device e.g. serial number.
  name: string # A human recognisable name for this device.
  type: string # The device type e.g. web_browser.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/authorization/device/code"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang, id: $id, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request one or more `Profile` level authorization tokens each with a chosen scope. Tokens are used to access restricted service endpoints. These restriced endpoints will require a specific token type (e.g Profile) with a specific scope (e.g. Catalog) before access is granted.
#
# POST /authorization/profile
# Returns: table<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string>
# operationId: getProfileToken
export def "get-profile-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --cookie-type: string@cookie-type-completer # If you specify a cookie type then a content filter cookie will be returned along with the token(s). This is only intended for web based clients which need to pass the cookies to a server to render a page based on the user's content filters e.g subscription code. If type `Session` the cookie will be session based. If type `Persistent` the cookie will have a medium term lifespan. If undefined no cookies will be set.
  --pin: string # The pin associated with this profile, if any.
  profile_id: string # The id of the profile the token should grant access rights to.
  scopes: list<string> # The scope(s) of the token(s) required.
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/authorization/profile"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: cookieType, var: cookie_type}, {name: pin, var: pin}, {name: profileId, var: profile_id}, {name: scopes, var: scopes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang, cookie_type: $cookie_type, pin: $pin, profile_id: $profile_id, scopes: $scopes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refresh an account or profile level authorization token which is marked as refreshable.
#
# POST /authorization/refresh
# Returns: record<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string>
# operationId: refreshToken
export def "refresh-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --cookie-type: string@cookie-type-completer # If you specify a cookie type then a content filter cookie will be returned along with the token(s). This is only intended for web based clients which need to pass the cookies to a server to render a page based on the user's content filters e.g subscription code. If type `Session` the cookie will be session based. If type `Persistent` the cookie will have a medium term lifespan. If undefined no cookies will be set.
  --body-token: string # The token to refresh. (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/authorization/refresh"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: cookieType, var: cookie_type}, {name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang, cookie_type: $cookie_type, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exchange a third party single-sign-on token for our own authorization tokens.
#
# POST /authorization/sso
# Returns: table<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string>
# operationId: singleSignOn
export def "single-sign-on" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --cookie-type: string@cookie-type-completer # If you specify a cookie type then a content filter cookie will be returned along with the token(s). This is only intended for web based clients which need to pass the cookies to a server to render a page based on the user's content filters e.g subscription code. If type `Session` the cookie will be session based. If type `Persistent` the cookie will have a medium term lifespan. If undefined no cookies will be set.
  --link-accounts: oneof<nothing, bool> # When a user attempts to sign in using single-sign-on, we may find an account created previously through the manual sign up flow with the same email. If this is the case then an option to link the two accounts can be made available. If this flag is set to true then accounts will be linked automatically. If this flag is not set or set to false and an existing account is found then an http 401 with subcode `6001` will be returned. Client apps can then present the option to link the accounts. If the user decides to accept, then the same call can be repeated with this flag set to true.
  provider: string@provider-completer # The third party single-sign-on provider.
  --scopes: list<string> # The scope(s) of the tokens required. For each scope listed an Account and Profile token of that scope will be returned.
  --body-token: string # A token from the third party single-sign-on provider e.g. an identity token from Facebook. (spec name: token)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/authorization/sso"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: cookieType, var: cookie_type}, {name: linkAccounts, var: link_accounts}, {name: provider, var: provider}, {name: scopes, var: scopes}, {name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang, cookie_type: $cookie_type, link_accounts: $link_accounts, provider: $provider, scopes: $scopes, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all the plans available for BT flow including additional description data.
#
# GET /bt/plan/{token}
# Returns: record<amount: float, ctaText: string, currency: string, description: string, ees07PlanDescription: string, ees07PlanTitle: string, ees07Title: string, headerText: string, heroText: string, id: string, interval: string, intervalCount: int, longText: string, nickname: string, noThanksText: string, product: string, switchingText: string, termsAndConditionsItunes: string, termsAndConditionsStripe: string, trialPeriodDays: int>
# operationId: getPlanByToken
export def "get-plan-by-token" [
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
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bt/plan/{token}"
    path_params: [{name: token, var: token_arg}]
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_arg: $token_arg, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all the plans available for BT flow including additional description data.
#
# GET /bt/plans
# Returns: record<plans: table<amount: float, ctaText: string, currency: string, description: string, ees07PlanDescription: string, ees07PlanTitle: string, ees07Title: string, headerText: string, heroText: string, id: string, interval: string, intervalCount: int, longText: string, nickname: string, noThanksText: string, product: string, switchingText: string, termsAndConditionsItunes: string, termsAndConditionsStripe: string, trialPeriodDays: int>>
# operationId: getPlans
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
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bt/plans"
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assigns an UserToken to a profile on the ITV side. Currently throws an exception.
#
# POST /bt/token/assign
# operationId: assignToken
export def "assign-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  profile_token: string # The ITV profile token
  --body-token: string # The validated userToken. (spec name: token)
]: any -> any {
  $in | http-request {
    method: post
    path: "/bt/token/assign"
    query: [{name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: profileToken, var: profile_token}, {name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    lang: $lang, profile_token: $profile_token, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks a provided token for BT eligible user.
#
# GET /bt/token/validate
# operationId: checkUserToken
export def "check-user-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # User token provided by BT. (required)
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> any {
  http-request {
    method: get
    path: "/bt/token/validate"
    query: [{name: id, var: id, required: true}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the details of subscription data for a user with specified id.
#
# GET /check-subscription/{id}
# Returns: record<itvData_purchased: record>
# operationId: getSubscriptionData
export def "get-subscription-data" [
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
    path: "/check-subscription/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the global configuration for an application. Should be called during app statup. This includes things like device and playback rules, classifications, sitemap and subscriptions. You have the option to select specific configuration objects using the 'include' parameter, or if unspecified, getting all configuration.
#
# GET /config
# Returns: record<classification: record, display: record<themes: list<record>>, general: record<currencyCode: string, customFields: record, defaultTimeZone: string, facebookAppId: string, gaToken: string, itemImageTypes: record, mandatorySignIn: bool, maxUserRating: int, stripeKey: string, websiteUrl: string>, i18n: record<languages: list<record>>, linear: record<scheduleCacheMaxAgeMinutes: int, viewingWindowDaysAfter: int, viewingWindowDaysBefore: int>, navigation: record<account: record<children: list, content: record, customFields: record, depth: int, featured: bool, icon: string, label: string, path: string>, copyright: string, customFields: record, footer: record<children: list, content: record, customFields: record, depth: int, featured: bool, icon: string, label: string, path: string>, header: list<record>, mobile: record<children: list, content: record, customFields: record, depth: int, featured: bool, icon: string, label: string, path: string>>, playback: record<chainPlayCountdown: int, chainPlaySqueezeback: int, chainPlayTimeout: int, heartbeatFrequency: int, viewEventPoints: list<float>>, sitemap: table<id: string, isStatic: bool, isSystemPage: bool, key: string, path: string, template: string, title: string>, subscription: record<plans: list<record>>>
# operationId: getAppConfig
export def "get-app-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list<string> # A comma delimited list of config objects to return. If none specified then all configuration is returned.
  --system: string # Classification system to load in case include = classification.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/config"
    query: [{name: include, var: include, style: csv}, {name: system, var: system}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    include: $include, system: $system, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check whether or not a user is eligible for switching to Bt or EE offers.
#
# GET /ee-bt/eligibility
# Returns: record<eligible: bool, plan: string, source: string>
# operationId: checkEeBtEligibility
export def "check-ee-bt-eligibility" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ee-bt/eligibility"
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assigns a msisdn to a profile on ITV side.
#
# POST /ee/msisdn
# operationId: assignMsisdn
export def "assign-msisdn" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  ee_product_id: string # Product id from /ee/offers
  msisdn: string # The validated msisdn.
  profile_token: string # The ITV profile token
  tracking_header: string # trackingHeader
]: any -> any {
  $in | http-request {
    method: post
    path: "/ee/msisdn"
    query: [{name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: eeProductId, var: ee_product_id}, {name: msisdn, var: msisdn}, {name: profileToken, var: profile_token}, {name: trackingHeader, var: tracking_header}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    lang: $lang, ee_product_id: $ee_product_id, msisdn: $msisdn, profile_token: $profile_token, tracking_header: $tracking_header
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns eligible partner specific offers for the querying partner for an EE MSISDN. This call is supposed to be called after we have MSISDN accired. This call should be followed by POST /ee/msisdn.
#
# POST /ee/offers
# Returns: record<eligibleOffers: table<name: string>>
# operationId: getEligibleOffers
export def "get-eligible-offers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  access_token: string # EE API authorization Token received from GET /ee/token/create.
  msisdn: string # The msisdn.
  --tracking-header: string # trackingHeader.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ee/offers"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessToken, var: access_token}, {name: msisdn, var: msisdn}, {name: trackingHeader, var: tracking_header}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang, access_token: $access_token, msisdn: $msisdn, tracking_header: $tracking_header
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate PIN request created by calling POST /ee/pin This call is to validate MSISDN entered by a user not comming through EE network. This call should be called after PUT /ee/pin. This call should be followed by POST /ee/offers.
#
# POST /ee/pin
# Returns: record<pinValid: string, trackingHeader: string>
# operationId: validatePinRequest
export def "validate-pin-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  access_token: string # EE API authorization Token received from GET /ee/token/create.
  pin: string # The pin entered by a user. 6 digits
  pin_reference: string # The pinReference.
  --tracking-header: string # Tracking header to be able to search logs for a specific user requests. If not provided it will be generated. FE should store it for later user.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ee/pin"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessToken, var: access_token}, {name: pin, var: pin}, {name: pinReference, var: pin_reference}, {name: trackingHeader, var: tracking_header}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang, access_token: $access_token, pin: $pin, pin_reference: $pin_reference, tracking_header: $tracking_header
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a PIN request that will send an SMS to the given msisdn. This call is to validate MSISDN entered by a user not comming through EE network. This call should be followed by POST ee/pin.
#
# PUT /ee/pin
# Returns: record<pinReference: string, trackingHeader: string>
# operationId: createPinRequest
export def "create-pin-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  access_token: string # EE API authorization Token received from GET /ee/token/create.
  msisdn: string # The msisdn.
  --tracking-header: string # trackingHeader
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/ee/pin"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessToken, var: access_token}, {name: msisdn, var: msisdn}, {name: trackingHeader, var: tracking_header}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang, access_token: $access_token, msisdn: $msisdn, tracking_header: $tracking_header
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all the plans available for EE flow including additional description data.
#
# GET /ee/plans
# Returns: record<plans: table<amount: float, ctaText: string, currency: string, description: string, headerText: string, heroText: string, id: string, interval: string, intervalCount: int, longText: string, nickname: string, product: string, trialPeriodDays: int>>
export def "get-ee-plans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ee/plans"
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the plan description for EE flow including additional description data.
#
# GET /ee/plans/{id}
# Returns: record<amount: float, ctaText: string, currency: string, description: string, headerText: string, heroText: string, id: string, interval: string, intervalCount: int, longText: string, nickname: string, product: string, trialPeriodDays: int>
# operationId: getPlan
export def "get-plan" [
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
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ee/plans/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a token for later calls to EE API. TTL is one hour. Recommended is FE refreshes this token before each call.
#
# GET /ee/token/create
# Returns: record<accessToken: string, expiresIn: float, tokenType: string>
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ee/token/create"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the details of an item with the specified id.
#
# GET /items/{id}
# Returns: record<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record<code: string, name: string>, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list<string>, hasClosedCaptions: bool, id: string, images: record, offers: table<deliveryType: string, exclusionRules: list, maxDownloads: int, maxPlays: int, ownership: string, playPeriod: int, rentalPeriod: int, resolution: string, scopes: list, availability: string, customFields: record, endDate: string, id: string, name: string, price: float, startDate: string, subscriptionCode: string>, path: string, releaseYear: int, scopes: list<string>, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: table<colors: list, type: string>, title: string, type: string, watchPath: string, copyright: string, credits: table<name: string, path: string, character: string, role: string>, customMetadata: table<name: string, value: string>, description: string, distributor: string, episodes: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, eventDate: string, genrePaths: list<string>, location: string, season: any, seasons: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, show: any, totalUserRatings: int, trailers: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, venue: string>
# operationId: getItem
export def "get-item" [
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
  --max-rating: string # The maximum rating (inclusive) of items returned, e.g. 'auoflc-pg'.
  --expand: string@expand-completer-1 # If no value is specified no dependencies are expanded. If 'children' is specified then the list of any direct children will be expanded. For example seasons of a show or episodes of a season. If 'all' is specified then the parent chain will be expanded along with any child list at each level. For example if an episode is specified then its season will be expanded and that season's episode list. The season will have its show expanded and the show will have its season list expanded. The 'all' options is useful when you deep link into a show/season/episode for the first time as it provides full context for navigating around the show page. Subsequent navigation around children of the show should only need to request expand of children. If 'ancestors' is specified then only the parent chain is included. If 'parent' is specified then only the direct parent is included. If an expand is specified which is not relevant to the item type, it will be ignored.
  --select-season: string@select-season-completer # Given a provided show id, it can be useful to get the details of a child season. This option provides a means to return the `first` or `latest` season of a show given the show id. The `expand` parameter also works here so for example you could land on a show page and request the latest season along with `expand=all`. This would then return the detail of the latest season with its list of child episode summaries, and also expand the detail of the show with its list of seasons summaries. Note the `id` parameter must be a show id for this parameter to work correctly.
  --use-custom-id: oneof<nothing, bool> # Set to true when passing a custom Id as the `id` path parameter.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/items/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: max_rating, var: max_rating}, {name: expand, var: expand}, {name: select_season, var: select_season}, {name: use_custom_id, var: use_custom_id}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, max_rating: $max_rating, expand: $expand, select_season: $select_season, use_custom_id: $use_custom_id, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the List of child summary items under an item. If the item is a Season then the children will be episodes and ordered by episode number. If the item is a Show then the children will be Seasons and ordered by season number. Returns 404 if no children found.
#
# GET /items/{id}/children
# Returns: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string>
# operationId: getItemChildrenList
export def "get-item-children-list" [
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
  --page: int # The page of items to load. Starts from page 1. (format: int32, default: 1)
  --page-size: int # The number of items to return in a page. (format: int32, default: 12)
  --max-rating: string # The maximum rating (inclusive) of items returned, e.g. 'auoflc-pg'.
  --order: string@order-completer # The list sort order, either 'asc' or 'desc'. (default: desc)
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/items/{id}/children"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: max_rating, var: max_rating}, {name: order, var: order}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, page: $page, page_size: $page_size, max_rating: $max_rating, order: $order, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of items related to the parent item. Note for now, due to the size of the list being unknown, only a single page will be returned.
#
# GET /items/{id}/related
# Returns: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string>
# operationId: getItemRelatedList
export def "get-item-related-list" [
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
  --page: int # The page of items to load. Starts from page 1. (format: int32, default: 1)
  --page-size: int # The number of items to return in a page. (format: int32, default: 12)
  --max-rating: string # The maximum rating (inclusive) of items returned, e.g. 'auoflc-pg'.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/items/{id}/related"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: max_rating, var: max_rating}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, page: $page, page_size: $page_size, max_rating: $max_rating, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the free / public video files associated with an item given maximum resolution, device type and one or more delivery types. Returns an array of video file objects which each include a url to a video. The first entry in the array contains what is predicted to be the best match. The remainder of the entries, if any, may contain resolutions below what was requests. For example if you request HD-720 the response may also contain SD entries. If you specify multiple delivery types, then the response array will insert types in the order you specify them in the query. For example `stream,progressive` would return an array with 0 or more stream files followed by 0 or more progressive files. If no files are found a 404 is returned.
#
# GET /items/{id}/videos
# Returns: table<channels: int, deliveryType: string, drm: string, format: string, height: int, language: string, name: string, resolution: string, url: string, width: int>
# operationId: getPublicItemMediaFiles
export def "get-public-item-media-files" [
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
  --delivery: list<string> # The video delivery type you require. (required)
  --resolution: string@resolution-completer # The maximum resolution the device to playback the media can present. (required)
  --formats: list<string> # The set of media file formats that the device supports, in the order of preference. When provided, Rocket API returns only media files in formats specified in this parameter. For each resolution, only the first media file of matching supported format is returned. Files of different resolutions may be of different supported media file formats. `external` value is reserved for project customizations where the real MIME type of the file on the specified URL is unknown at the time of ingestion. When not provided, Rocket API uses the legacy `User-Agent` header-based logic to find matching media files.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/items/{id}/videos"
    path_params: [{name: id, var: id}]
    query: [{name: delivery, var: delivery, style: csv, required: true}, {name: resolution, var: resolution, required: true}, {name: formats, var: formats, style: csv}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, delivery: $delivery, resolution: $resolution, formats: $formats, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Identical to GET /account/profile/items/{itemId}/next route but for users that are not logged in i.e. this endpoint does not require authorisation
#
# GET /items/{itemId}/next
# Returns: record<firstWatchedDate: string, lastWatchedDate: string, next: record<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record<code: string, name: string>, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list<string>, hasClosedCaptions: bool, id: string, images: record, offers: list<record>, path: string, releaseYear: int, scopes: list<string>, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list<record>, title: string, type: string, watchPath: string, copyright: string, credits: list<record>, customMetadata: list<record>, description: string, distributor: string, episodes: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, eventDate: string, genrePaths: list<string>, location: string, season: any, seasons: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, show: any, totalUserRatings: int, trailers: list<record>, venue: string>, sourceItemId: string, suggestionType: string>
# operationId: getAnonNextPlaybackItem
export def "get-anon-next-playback-item" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-rating: string # The maximum rating (inclusive) of an item returned, e.g. 'auoflc-pg'.
  --expand: string@expand-completer # If no value is specified no dependencies are expanded. If 'parent' is specified then only the direct parent will be expanded. For example if an `Episode` then the `Season` would be included. If 'ancestors' is specified then the full parent chain is expanded. For example if an `Episode` then both the `Season` and `Show` would be included.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/items/{itemId}/next"
    path_params: [{name: itemId, var: item_id}]
    query: [{name: max_rating, var: max_rating}, {name: expand, var: expand}, {name: device, var: device}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id, max_rating: $max_rating, expand: $expand, device: $device, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of billing records for specified payment platform.
#
# POST /itv/billinghistory/{platform}
# Returns: record<payment_history: table<card: record, charge: record, invoice: record, subscription: record>>
# operationId: getBillingHistory
export def "get-billing-history" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  profile_token: string # The ITV profile token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/itv/billinghistory/{platform}"
    path_params: [{name: platform, var: platform}]
    query: [{name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: profileToken, var: profile_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    platform: $platform, lang: $lang, profile_token: $profile_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get payment card details.
#
# POST /itv/cards/{platform}
# Returns: record<card_type: string, exp_month: int, exp_year: int, last4: string>
# operationId: getCardDetails
export def "get-card-details" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  profile_token: string # The ITV profile token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/itv/cards/{platform}"
    path_params: [{name: platform, var: platform}]
    query: [{name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: profileToken, var: profile_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    platform: $platform, lang: $lang, profile_token: $profile_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change payment card details.
#
# PUT /itv/cards/{platform}
# operationId: changeCardDetails
export def "change-card-details" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  card_token: string # The credit card token.
  profile_token: string # The ITV profile token.
]: any -> any {
  $in | http-request {
    method: put
    path: "/itv/cards/{platform}"
    path_params: [{name: platform, var: platform}]
    query: [{name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: cardToken, var: card_token}, {name: profileToken, var: profile_token}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    platform: $platform, lang: $lang, card_token: $card_token, profile_token: $profile_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change email address related to account/profile. The expected token scope is Settings.
#
# POST /itv/changeemail
# operationId: changeEmail
export def "change-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  email: string # New email address for account/profile.
  profile_token: string # The ITV profile token.
]: any -> any {
  $in | http-request {
    method: post
    path: "/itv/changeemail"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: profileToken, var: profile_token}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ff: $ff, lang: $lang, email: $email, profile_token: $profile_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change marketing preferences related to account/profile. The expected token scope is Settings.
#
# POST /itv/changemarketing
# operationId: changeMarketing
export def "change-marketing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --email-opt-in: oneof<nothing, bool> # Updated marketing preferences for account/profile.
  profile_token: string # The ITV profile token.
]: any -> any {
  $in | http-request {
    method: post
    path: "/itv/changemarketing"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: emailOptIn, var: email_opt_in, required: true}, {name: profileToken, var: profile_token}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ff: $ff, lang: $lang, email_opt_in: $email_opt_in, profile_token: $profile_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete account in compliance with GDPR. The expected token scope is Settings.
#
# POST /itv/deleteaccount
# operationId: deleteAccount
export def "delete-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  profile_token: string # The ITV profile token.
]: any -> any {
  $in | http-request {
    method: post
    path: "/itv/deleteaccount"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: profileToken, var: profile_token}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ff: $ff, lang: $lang, profile_token: $profile_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns current entitlement.
#
# GET /itv/entitlements/current
# Returns: record<source: string>
# operationId: getCurrentEntitlement
export def "get-current-entitlement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/itv/entitlements/current"
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the state of subscription for any payment platform.
#
# GET /itv/entitlements/history
# Returns: record<cancellations: table<cancelled_at: string, itvId: string, source: string, subscriptionId: string>, entitlements: table<card_type: string, expiry: string, plan: record, source: string, subscriptionId: string>>
# operationId: getEntitlementsHistory
export def "get-entitlements-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/itv/entitlements/history"
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets info whether or not a feature is enabled or disabled using a feature flag. Feature flags are set as a custom field within PM. It also supports custom feature flag data if needed. Such data can be return as well.
#
# GET /itv/featureFlag/{feature}
# Returns: record<enabled: bool, flag: string>
# operationId: getFeatureFlag
export def "get-feature-flag" [
  feature: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/itv/featureFlag/{feature}"
    path_params: [{name: feature, var: feature}]
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    feature: $feature, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of recommended items under the active profile.
#
# POST /itv/googlepay/subscription
# operationId: googlePaySubscription
export def "google-pay-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  purchase_token: string # the unique identifier for this purchase
  subscription_item: string # the SKU of the item from the play console
]: any -> any {
  $in | http-request {
    method: post
    path: "/itv/googlepay/subscription"
    query: [{name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: purchaseToken, var: purchase_token}, {name: subscriptionItem, var: subscription_item}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    lang: $lang, purchase_token: $purchase_token, subscription_item: $subscription_item
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check whether the user has been previously entitled.
#
# GET /itv/had/entitlements
# Returns: record<hasHadEntitlements: bool>
# operationId: checkPreviousEntitlements
export def "check-previous-entitlements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/itv/had/entitlements"
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the media clip files associated with items.
#
# POST /itv/items/clips
# Returns: record<items: table<clips: list, id: string>>
# operationId: getItemsMediaClipFiles
export def "get-items-media-clip-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  ids: string # Comma-separated list of AXIS item ids.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/itv/items/clips"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the details of an item with the specified id.
#
# POST /itv/items/downloadable
# Returns: record<items: table<downloadable: bool, id: string>>
# operationId: getItemDownloadables
export def "get-item-downloadables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  ids: string # Comma-separated list of AXIS item ids.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/itv/items/downloadable"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Redirects to corresponding Axis Item details page.
#
# GET /itv/itemsummary/{externalId}
export def "get-itv-itemsummary-external-id" [
  external_id: string
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
    path: "/itv/itemsummary/{externalId}"
    path_params: [{name: externalId, var: external_id}]
    accept: ["application/json"]
    ok: [302]
    auth: bearer
  } {
    external_id: $external_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a page with the specified id. This is a cut down version for low memory devices.123 If targeting the search page you must url encode the search term as a parameter using the `q` key. For example if your browser path looks like `/search?q=the` then what you pass to this endpoint would look like `/itv/page?path=/search%3Fq%3Dthe`.
#
# GET /itv/page
# Returns: record<id: string, isStatic: bool, isSystemPage: bool, key: string, path: string, template: string, title: string, customFields: record, entries: table<customFields: record, id: string, images: record, item: record, list: record, people: list, template: string, text: string, title: string, type: string>, item: record<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record<code: string, name: string>, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list<string>, hasClosedCaptions: bool, id: string, images: record, offers: list<record>, path: string, releaseYear: int, scopes: list<string>, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list<record>, title: string, type: string, watchPath: string, copyright: string, credits: list<record>, customMetadata: list<record>, description: string, distributor: string, episodes: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, eventDate: string, genrePaths: list<string>, location: string, season: any, seasons: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, show: any, totalUserRatings: int, trailers: list<record>, venue: string>, list: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, metadata: record<description: string, keywords: list<string>, segments: list<string>>, themes: table<colors: list, type: string>>
# operationId: getItvPage
export def "get-itv-page" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The path of the page to load, e.g. '/movies'. (required)
  --list-page-size: int # The number of items to load when prefetching and paging each list in the page row. (format: int32, default: 12)
  --list-page-size-large: int # The number of items to load when prefetching a continuous scroll list entry in a page. By default any list page entry with template pattern `/^CS\d+$/` will be considered a continuous scroll list. (format: int32, default: 50)
  --max-list-prefetch: int # The maximum number of lists to prefetch in the page. (format: int32, default: 2)
  --item-detail-expand: string@item-detail-expand-completer # Only relevant when loading item detail pages as these embed a detailed item in the main page entry. If no value is specified no item dependencies are expanded. If 'children' is specified then the list of any direct children will be expanded. For example seasons of a show or episodes of a season. If 'all' is specified then the parent chain will be expanded along with any child list at each level. For example if an episode is specified then its season will be expanded and that season's episode list. The season will have its show expanded and the show will have its season list expanded. The 'all' options is useful when you deep link into a show/season/episode for the first time as it provides full context for navigating around the show page. Subsequent navigation around children of the show should only need to request expand of children. If 'ancestors' is specified then only the parent chain is included If an expand is specified which is not relevant to the item type, it will be ignored.
  --item-detail-select-season: string@item-detail-select-season-completer # Only relevant when loading show detail pages as these embed a detailed item in the main page entry. Since the introduction of the D1,2,3 templates this parameter is now somewhat redundant, or less likely to have any effect. While it may still be useful in some cases, most of the time the season selection will be dictated by the configuration of the rows scheduled on the show detail page. This parameter will only take effect if there are rows used to schedule episodes of a season, like D1,2,3, or if no rows have a value set for their `seasonOrder` custom field. Given a targeted show page, it can be useful to get the details of a child season. This option provides a means to return the `first` or `latest` season of a show embedded in the page. The `expand` parameter also works here so for example you could land on a show page and request the `item_detail_select_season=latest` along with `item_detail_expand=all`. This would then return the detail of the latest season with its list of child episode summaries, and also expand the detail of the show with its list of seasons summaries.
  --text-entry-format: string@text-entry-format-completer # Only relevant to page entries of type `TextEntry`. Converts the value of a text page entry to the specified format. (default: markdown)
  --max-rating: string # The maximum rating (inclusive) of items returned, e.g. 'auoflc-pg'.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/itv/page"
    query: [{name: path, var: path, required: true}, {name: list_page_size, var: list_page_size}, {name: list_page_size_large, var: list_page_size_large}, {name: max_list_prefetch, var: max_list_prefetch}, {name: item_detail_expand, var: item_detail_expand}, {name: item_detail_select_season, var: item_detail_select_season}, {name: text_entry_format, var: text_entry_format}, {name: max_rating, var: max_rating}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200, 301]
    auth: bearer
  } {
    path: $path, list_page_size: $list_page_size, list_page_size_large: $list_page_size_large, max_list_prefetch: $max_list_prefetch, item_detail_expand: $item_detail_expand, item_detail_select_season: $item_detail_select_season, text_entry_format: $text_entry_format, max_rating: $max_rating, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides authorization with parental control pin. Returns an array containing account token with Playback scope. Requires access token with Catalog scope. Pin must be a 4-digit string
#
# POST /itv/pinauthorization
# Returns: table<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string>
# operationId: getAccountTokenWithPin
export def "get-account-token-with-pin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --cookie-type: string@cookie-type-completer # If you specify a cookie type then a content filter cookie will be returned along with the token(s). This is only intended for web based clients which need to pass the cookies to a server to render a page based on the user's content filters e.g subscription code. If type `Session` the cookie will be session based. If type `Persistent` the cookie will have a medium term lifespan. If undefined no cookies will be set.
  pin: string # The 4-digit parental control pin.
  --scopes: list<string> # The scope(s) of the token(s) required.
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/itv/pinauthorization"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: cookieType, var: cookie_type}, {name: pin, var: pin}, {name: scopes, var: scopes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang, cookie_type: $cookie_type, pin: $pin, scopes: $scopes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upgrades the plan for the current user.
#
# POST /itv/plan/{platform}
# operationId: upgradePlan
export def "upgrade-plan" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  plan_id: string # The identifier of the plan to purchase.
]: any -> any {
  $in | http-request {
    method: post
    path: "/itv/plan/{platform}"
    path_params: [{name: platform, var: platform}]
    query: [{name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: planId, var: plan_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    platform: $platform, lang: $lang, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the plans available for specified payment platform.
#
# GET /itv/plans/{platform}
# Returns: record<plans: table<amount: float, currency: string, description: string, id: string, interval: string, intervalCount: int, nickname: string, product: string, savingLabel: string, switchingText: string, trialPeriodDays: int>>
export def "get-itv-plans-platform" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/itv/plans/{platform}"
    path_params: [{name: platform, var: platform}]
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    platform: $platform, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the ITV profile object.
#
# GET /itv/profile
# Returns: record
export def "get-itv-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/itv/profile"
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update ITV profile. The expected token scope is Settings.
#
# PUT /itv/profile
# operationId: updateProfile
export def "update-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --date-of-birth: string # The date of birth.
  --email: string # The email address.
  --first-name: string # Last name.
  --last-name: string # First name.
  --postcode: string # The postal code.
  profile_token: string # The ITV profile token.
  --title: string # The title.
]: any -> any {
  $in | http-request {
    method: put
    path: "/itv/profile"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: dateOfBirth, var: date_of_birth}, {name: email, var: email}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: postcode, var: postcode}, {name: profileToken, var: profile_token}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ff: $ff, lang: $lang, date_of_birth: $date_of_birth, email: $email, first_name: $first_name, last_name: $last_name, postcode: $postcode, profile_token: $profile_token, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of recommended items under the active profile.
#
# GET /itv/profile/recommendation/list
# Returns: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string>
# operationId: getRecommendedList
export def "get-recommended-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --item-types: list<string> # List of item types to filter the recommendation list (e.g. {item_types: show,movie})
  --page: int # The page of items to load. Starts from page 1. (format: int32, default: 1)
  --page-size: int # The number of items to return in a page. (format: int32, default: 12)
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/itv/profile/recommendation/list"
    query: [{name: item_types, var: item_types, style: csv}, {name: page, var: page}, {name: page_size, var: page_size}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_types: $item_types, page: $page, page_size: $page_size, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the ITV profile token.
#
# POST /itv/profiletoken
# Returns: record<profileToken: string>
# operationId: getItvProfileToken
export def "get-itv-profile-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  password: string # The password.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/itv/profiletoken"
    query: [{name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lang: $lang, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel a plan subscription. A cancelled subscription will continue to be valid until the subscription expiry date or next renewal date.
#
# DELETE /itv/purchase/{platform}
export def "delete-itv-purchase-platform" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  profile_token: string # The ITV profile token.
]: any -> any {
  $in | http-request {
    method: delete
    path: "/itv/purchase/{platform}"
    path_params: [{name: platform, var: platform}]
    query: [{name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: profileToken, var: profile_token}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    platform: $platform, lang: $lang, profile_token: $profile_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the details of current subscription for specified payment platform.
#
# GET /itv/purchase/{platform}
# Returns: record<cancelAtPeriodEnd: bool, collectionMethod: string, created: int, currentPeriodEnd: int, currentPeriodStart: int, plan: record, status: string>
# operationId: getCurrentSubscription
export def "get-current-subscription" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/itv/purchase/{platform}"
    path_params: [{name: platform, var: platform}]
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    platform: $platform, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Confirms purchase and returns the details of purchased subscription for specified payment platform.
#
# POST /itv/purchase/{platform}
# Returns: record<customerId: string, planId: string, subscriptionId: string>
# operationId: confirmPurchase
export def "confirm-purchase" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  card_token: string # The credit card token.
  plan_id: string # The identifier of the plan to purchase.
  profile_token: string # The ITV profile token.
  --voucher: string # A coupon/voucher for a discount.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/itv/purchase/{platform}"
    path_params: [{name: platform, var: platform}]
    query: [{name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: cardToken, var: card_token}, {name: planId, var: plan_id}, {name: profileToken, var: profile_token}, {name: voucher, var: voucher}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    platform: $platform, lang: $lang, card_token: $card_token, plan_id: $plan_id, profile_token: $profile_token, voucher: $voucher
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Confirms purchase and returns the details of purchased subscription for specified payment platform.
#
# POST /itv/purchase/{platform}/strong
# Returns: record<clientSecret: string, customerId: string, intentId: string, intentType: string, planId: string, status: string, subscriptionId: string>
# operationId: confirmPurchaseStrong
export def "confirm-purchase-strong" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --payment-method-from-token: string # A paymentMethodFromToken.
  --payment-method-id: string # A paymentMethodId from Stripe.
  plan_id: string # The identifier of the plan to purchase.
  profile_token: string # The ITV profile token.
  --voucher: string # A coupon/voucher for a discount.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/itv/purchase/{platform}/strong"
    path_params: [{name: platform, var: platform}]
    query: [{name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: paymentMethodFromToken, var: payment_method_from_token}, {name: paymentMethodId, var: payment_method_id}, {name: planId, var: plan_id}, {name: profileToken, var: profile_token}, {name: voucher, var: voucher}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    platform: $platform, lang: $lang, payment_method_from_token: $payment_method_from_token, payment_method_id: $payment_method_id, plan_id: $plan_id, profile_token: $profile_token, voucher: $voucher
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Confirms purchase and returns the details of purchased subscription for specified payment platform.
#
# POST /itv/purchase/{platform}/withoffer
# Returns: record<clientSecret: string, customerId: string, intentId: string, intentType: string, paymentMethodId: string, status: string, subscriptionId: string>
# operationId: confirmPurchaseWithOffer
export def "confirm-purchase-with-offer" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  coupon_id: string # A coupon/voucher for a discount. Can be retrieved from GET itv/voucher/{platform} endpoint
  --payment-method-from-token: string # A paymentMethodFromToken.
  --payment-method-id: string # A paymentMethodId from Stripe.
  plan_id: string # The identifier of the plan to purchase.
  profile_token: string # The ITV profile token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/itv/purchase/{platform}/withoffer"
    path_params: [{name: platform, var: platform}]
    query: [{name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: couponId, var: coupon_id}, {name: paymentMethodFromToken, var: payment_method_from_token}, {name: paymentMethodId, var: payment_method_id}, {name: planId, var: plan_id}, {name: profileToken, var: profile_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    platform: $platform, lang: $lang, coupon_id: $coupon_id, payment_method_from_token: $payment_method_from_token, payment_method_id: $payment_method_id, plan_id: $plan_id, profile_token: $profile_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resubscription for a user.
#
# POST /itv/resubscribe/{platform}
# Returns: record
# operationId: resubscribe
export def "resubscribe" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --plan-id: string # The id of the plan to renew. (required)
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/itv/resubscribe/{platform}"
    path_params: [{name: platform, var: platform}]
    query: [{name: planId, var: plan_id, required: true}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    platform: $platform, plan_id: $plan_id, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets available Roku plans.
#
# GET /itv/roku/plans
# Returns: record<plans: table<amount: float, currency: string, description: string, interval: string, intervalCount: int, nickname: string, product: string, productCode: string, savingLabel: string, trialPeriodDays: int>, termsAndConditions: string>
export def "get-itv-roku-plans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/itv/roku/plans"
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends request to execute specified transaction.
#
# POST /itv/roku/transaction/{transactionid}
# operationId: executeTransaction
export def "execute-transaction" [
  transactionid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  profile_token: string # The ITV profile token.
]: any -> any {
  $in | http-request {
    method: post
    path: "/itv/roku/transaction/{transactionid}"
    path_params: [{name: transactionid, var: transactionid}]
    query: [{name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: profileToken, var: profile_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transactionid: $transactionid, lang: $lang, profile_token: $profile_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks the provided coupon id for a user. Only Stripe platform is currently supported.
#
# GET /itv/save-offer
# Returns: record<currency: string, description: string, headline: string, id: string, initialCost: float, longDescription: string, nickname: string, offerdurationperiod: string, shortDescription: string>
# operationId: getSaveOffer
export def "get-save-offer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/itv/save-offer"
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activates the discount for a user. Only Stripe platform is currently supported.
#
# POST /itv/save-offer
# operationId: activateSaveOffer
export def "activate-save-offer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/itv/save-offer"
    query: [{name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    lang: $lang, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns full price renewal state and reason for specific user.
#
# GET /itv/subscription/fullpricerenewal
# Returns: record<fullPriceRenewal: bool, reason: string>
# operationId: getFullPriceRenewal
export def "get-full-price-renewal" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/itv/subscription/fullpricerenewal"
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns status of latest payment intent.
#
# GET /itv/subscription/status/{platform}
# Returns: record<is_active: bool>
# operationId: getSubscriptionStatus
export def "get-subscription-status" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/itv/subscription/status/{platform}"
    path_params: [{name: platform, var: platform}]
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    platform: $platform, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the state of subscription for any payment platform.
#
# GET /itv/subscriptionstate
# Returns: record<effective_entitlements: table<card_type: string, expiry: string, plan: record, source: string, subscriptionId: string>, failed_availability_checks: list<string>, purchased: list<string>, source: string>
# operationId: getSubscriptionState
export def "get-subscription-state" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/itv/subscriptionstate"
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an upcoming invoice
#
# GET /itv/upcominginvoice
# Returns: record<currency: string, description: string, headline: string, id: string, initialCost: float, longDescription: string, nickname: string, offerdurationperiod: string, shortDescription: string>
# operationId: getUpcomingInvoice
export def "get-upcoming-invoice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/itv/upcominginvoice"
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change payment method details.
#
# PUT /itv/updateIntent/strong/{platform}
# Returns: record<clientSecret: string, intentId: string, intentType: string, status: string>
# operationId: updatePaymentIntentStrong
export def "update-payment-intent-strong" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --payment-method-from-token: string # A paymentMethodFromToken.
  --payment-method-id: string # The paymentMethodId from Stripe.
  profile_token: string # The ITV profile token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/itv/updateIntent/strong/{platform}"
    path_params: [{name: platform, var: platform}]
    query: [{name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: paymentMethodFromToken, var: payment_method_from_token}, {name: paymentMethodId, var: payment_method_id}, {name: profileToken, var: profile_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    platform: $platform, lang: $lang, payment_method_from_token: $payment_method_from_token, payment_method_id: $payment_method_id, profile_token: $profile_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change payment method details.
#
# PUT /itv/updatePayment/strong/{platform}
# operationId: updatePaymentMethodStrong
export def "update-payment-method-strong" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --payment-method-from-token: string # A paymentMethodFromToken.
  --payment-method-id: string # The paymentMethodId from Stripe.
  profile_token: string # The ITV profile token.
]: any -> any {
  $in | http-request {
    method: put
    path: "/itv/updatePayment/strong/{platform}"
    path_params: [{name: platform, var: platform}]
    query: [{name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: paymentMethodFromToken, var: payment_method_from_token}, {name: paymentMethodId, var: payment_method_id}, {name: profileToken, var: profile_token}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    platform: $platform, lang: $lang, payment_method_from_token: $payment_method_from_token, payment_method_id: $payment_method_id, profile_token: $profile_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks the provided coupon id for a user. Only Stripe platform is currently supported.
#
# GET /itv/voucher/{planId}/{voucherId}
# Returns: record<display: record<currency: string, discountPrice: string, duration: string, durationInMonths: float, headlineLabel: string, initialCost: float, longDescription: string, percentOff: float, savingLabel: string, shortDescription: string>, id: string, links: record<redeem: record<href: string>, self: record<href: string>>, offerType: string>
# operationId: getVoucherById
export def "get-voucher-by-id" [
  plan_id: string
  voucher_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/itv/voucher/{planId}/{voucherId}"
    path_params: [{name: planId, var: plan_id}, {name: voucherId, var: voucher_id}]
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    plan_id: $plan_id, voucher_id: $voucher_id, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates the coupon/voucher for specified payment platform.
#
# POST /itv/voucher/{platform}
# Returns: record<display: record<currency: string, discountPrice: string, duration: string, durationInMonths: float, headlineLabel: string, initialCost: float, longDescription: string, percentOff: float, savingLabel: string, shortDescription: string>, id: string, links: record<redeem: record<href: string>, self: record<href: string>>, offerType: string>
# operationId: checkVoucher
export def "check-voucher" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  voucher: string # The voucher.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/itv/voucher/{platform}"
    path_params: [{name: platform, var: platform}]
    query: [{name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: voucher, var: voucher}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    platform: $platform, lang: $lang, voucher: $voucher
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an array of item lists with their first page of content resolved.
#
# GET /lists
# Returns: table<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>
# operationId: getLists
export def "get-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # A comma delimited list of item list identifiers. These can be list ids e.g. `14354,65473,3234` Or more complex sort/filter queries using pipes e.g. `14354|max_rating=AUOFLC-E|order=asc|order_by=year-added,65473|page_size=30,3234` _Note the id must always come first for each encoded list query_ List parameters may be provide without the `param=` prefix e.g. `14354|genre:action` Only the following options can be present. - `order` - `order_by` - `max_rating` - `page_size` - `item_type` - `param` (required)
  --page-size: int # The number of items to return in a page. (format: int32, default: 12)
  --max-rating: string # The maximum rating (inclusive) of items returned, e.g. 'auoflc-pg'.
  --order: string@order-completer # The list sort order, either 'asc' or 'desc'. (default: desc)
  --order-by: string@order-by-completer-1 # What to order by.
  --item-type: string@item-type-completer # The item type to filter by. Defaults to unspecified.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/lists"
    query: [{name: ids, var: ids, style: csv, required: true}, {name: page_size, var: page_size}, {name: max_rating, var: max_rating}, {name: order, var: order}, {name: order_by, var: order_by}, {name: item_type, var: item_type}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, page_size: $page_size, max_rating: $max_rating, order: $order, order_by: $order_by, item_type: $item_type, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of items under the specified item list
#
# GET /lists/{id}
# Returns: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string>
# operationId: getList
export def "get-list" [
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
  --page: int # The page of items to load. Starts from page 1. (format: int32, default: 1)
  --page-size: int # The number of items to return in a page. (format: int32, default: 12)
  --max-rating: string # The maximum rating (inclusive) of items returned, e.g. 'auoflc-pg'.
  --order: string@order-completer # The list sort order, either 'asc' or 'desc'. (default: desc)
  --order-by: string@order-by-completer-1 # What to order by.
  --param: string # The list parameter in format 'key:value', e.g. 'genre:action'.
  --item-type: string@item-type-completer # The item type to filter by. Defaults to unspecified.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/lists/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: max_rating, var: max_rating}, {name: order, var: order}, {name: order_by, var: order_by}, {name: param, var: param}, {name: item_type, var: item_type}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, page: $page, page_size: $page_size, max_rating: $max_rating, order: $order, order_by: $order_by, param: $param, item_type: $item_type, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a page with the specified id. If targeting the search page you must url encode the search term as a parameter using the `q` key. For example if your browser path looks like `/search?q=the` then what you pass to this endpoint would look like `/page?path=/search%3Fq%3Dthe`.
#
# GET /page
# Returns: record<id: string, isStatic: bool, isSystemPage: bool, key: string, path: string, template: string, title: string, customFields: record, entries: table<customFields: record, id: string, images: record, item: record, list: record, people: list, template: string, text: string, title: string, type: string>, item: record<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record<code: string, name: string>, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list<string>, hasClosedCaptions: bool, id: string, images: record, offers: list<record>, path: string, releaseYear: int, scopes: list<string>, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list<record>, title: string, type: string, watchPath: string, copyright: string, credits: list<record>, customMetadata: list<record>, description: string, distributor: string, episodes: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, eventDate: string, genrePaths: list<string>, location: string, season: any, seasons: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, show: any, totalUserRatings: int, trailers: list<record>, venue: string>, list: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, metadata: record<description: string, keywords: list<string>, segments: list<string>>, themes: table<colors: list, type: string>>
# operationId: getPage
export def "get-page" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The path of the page to load, e.g. '/movies'. (required)
  --list-page-size: int # The number of items to load when prefetching and paging each list in the page row. (format: int32, default: 12)
  --list-page-size-large: int # The number of items to load when prefetching a continuous scroll list entry in a page. By default any list page entry with template pattern `/^CS\d+$/` will be considered a continuous scroll list. (format: int32, default: 50)
  --max-list-prefetch: int # The maximum number of lists to prefetch in the page. (format: int32, default: 2)
  --item-detail-expand: string@item-detail-expand-completer # Only relevant when loading item detail pages as these embed a detailed item in the main page entry. If no value is specified no item dependencies are expanded. If 'children' is specified then the list of any direct children will be expanded. For example seasons of a show or episodes of a season. If 'all' is specified then the parent chain will be expanded along with any child list at each level. For example if an episode is specified then its season will be expanded and that season's episode list. The season will have its show expanded and the show will have its season list expanded. The 'all' options is useful when you deep link into a show/season/episode for the first time as it provides full context for navigating around the show page. Subsequent navigation around children of the show should only need to request expand of children. If 'ancestors' is specified then only the parent chain is included If an expand is specified which is not relevant to the item type, it will be ignored.
  --item-detail-select-season: string@item-detail-select-season-completer # Only relevant when loading show detail pages as these embed a detailed item in the main page entry. Since the introduction of the D1,2,3 templates this parameter is now somewhat redundant, or less likely to have any effect. While it may still be useful in some cases, most of the time the season selection will be dictated by the configuration of the rows scheduled on the show detail page. This parameter will only take effect if there are rows used to schedule episodes of a season, like D1,2,3, or if no rows have a value set for their `seasonOrder` custom field. Given a targeted show page, it can be useful to get the details of a child season. This option provides a means to return the `first` or `latest` season of a show embedded in the page. The `expand` parameter also works here so for example you could land on a show page and request the `item_detail_select_season=latest` along with `item_detail_expand=all`. This would then return the detail of the latest season with its list of child episode summaries, and also expand the detail of the show with its list of seasons summaries.
  --text-entry-format: string@text-entry-format-completer # Only relevant to page entries of type `TextEntry`. Converts the value of a text page entry to the specified format. (default: markdown)
  --max-rating: string # The maximum rating (inclusive) of items returned, e.g. 'auoflc-pg'.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/page"
    query: [{name: path, var: path, required: true}, {name: list_page_size, var: list_page_size}, {name: list_page_size_large, var: list_page_size_large}, {name: max_list_prefetch, var: max_list_prefetch}, {name: item_detail_expand, var: item_detail_expand}, {name: item_detail_select_season, var: item_detail_select_season}, {name: text_entry_format, var: text_entry_format}, {name: max_rating, var: max_rating}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200, 301]
    auth: bearer
  } {
    path: $path, list_page_size: $list_page_size, list_page_size_large: $list_page_size_large, max_list_prefetch: $max_list_prefetch, item_detail_expand: $item_detail_expand, item_detail_select_season: $item_detail_select_season, text_entry_format: $text_entry_format, max_rating: $max_rating, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the details of a Plan with the specified id.
#
# GET /plans/{id}
# Returns: record<alias: string, benefits: list<string>, billingPeriodFrequency: int, billingPeriodType: string, currency: string, customFields: record, hasTrialPeriod: bool, id: string, isActive: bool, isFeatured: bool, isPrivate: bool, price: float, revenueType: string, subscriptionCode: string, tagline: string, termsAndConditions: string, title: string, trialPeriodDays: int, type: string>
export def "get-plans-id" [
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
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/plans/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a new user, creating them an account. Registration, when successful, will return an array of access tokens so the user is immediately signed in. It returns Catalog and Commerce scoped tokens for both Account and Profile. The Commerce ones are intended to allow the purchase of a subscription plan in the step after registration, without the user being prompted to enter their username and password again. An email will also be sent with a link they need to click to confirm their email address. This confirmation is done via the /verify-email endpoint.
#
# POST /register
# Returns: table<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string>
# operationId: register
export def "register" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  email: string
  --first-name: string
  --language-code: string # The code of the preferred language for the primary profile. Must be a valid ISO language code e.g. "en-US" and must match the code of one of the languages specified in the app config. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --last-name: string
  --marketing: oneof<nothing, bool> # Whether to receive marketing material or not. Default to true. (default: true)
  password: string
  --pin: string # The primary account pin.
  --segments: list<string> # The segments to apply to the primary profile.
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/register"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: firstName, var: first_name}, {name: languageCode, var: language_code}, {name: lastName, var: last_name}, {name: marketing, var: marketing}, {name: password, var: password}, {name: pin, var: pin}, {name: segments, var: segments}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ff: $ff, lang: $lang, email: $email, first_name: $first_name, language_code: $language_code, last_name: $last_name, marketing: $marketing, password: $password, pin: $pin, segments: $segments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request the password of an account's primary profile be reset. Should be called when a user has forgotten their password. This will send an email with a password reset link to the email address of the primary profile of an account. The link, once clicked, should take the user to the "reset-password" page of the website. Here they will enter their new password and submit to the /reset-password endpoint here, along with the password reset token provided in the original link.
#
# POST /request-password-reset
# operationId: forgotPassword
export def "forgot-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  email: string # The email address of the primary account profile to reset the password for.
]: any -> any {
  $in | http-request {
    method: post
    path: "/request-password-reset"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ff: $ff, lang: $lang, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# When a user requests to reset their password via the /request-password-reset endpoint, an email is sent to the email address of the primary profile of the account. This email contains a link with a reset token as query parameter. The link should take the user to the "reset-password" page of the website. From the reset-password page a user should enter the new password they wish to use. It should then be submitted to this endpoint, along with the reset token from the email link. The token should be provided in the body as resetToken property.
#
# POST /reset-password
# operationId: resetPassword
export def "reset-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  password: string # The new password for the account.
  reset_token: string # The ITV reset token.
]: any -> any {
  $in | http-request {
    method: post
    path: "/reset-password"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: resetToken, var: reset_token}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ff: $ff, lang: $lang, password: $password, reset_token: $reset_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns public preview for Samsung based on the page '/samsung-preview' configured in PresentationManager. There is a hard limit of max 40 items to be returned. It splits evenly items count into the page rows, remaining items are added into the first row.
#
# GET /samsung-preview
# Returns: record<expires: int, expires_only: bool, sections: table<position: int, tiles: list, title: string>>
# operationId: getPublicPreview
export def "get-public-preview" [
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
    path: "/samsung-preview"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns schedules for a defined set of channels over a requested period. Schedules are requested in hour blocks and returned grouped by the channel they belong to. For example, to load 12 hours of schedules for channels `4343` and `5234`, on 21/2/2017 starting from 08:00. ``` channels=4343,5234 date=2017-02-21 hour=8 duration=12 ``` Please remember that `date` and `hour` combined represent a normal datetime, so they should be converted to UTC on the client - this will help to avoid issues with EPG schedules near midnight. If a channel id is passed which doesn't exist then this endpoint will return an empty schedule list for it. If instead we returned 404, this would invalidate all other channel schedules in the same request which would be unfriendly for clients presenting these channel schedules.
#
# GET /schedules
# Returns: table<channelId: string, endDate: string, schedules: list<record>, startDate: string>
# operationId: getSchedules
export def "get-schedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channels: list<string> # The list of channel ids to get schedules for. (required)
  --date: string # The date to target in ISO format, e.g. `2017-05-23` (converted to UTC - see main description). The base hour requested will belong to this date. (required, format: date)
  --hour: int # The base hour in the day, defined by the `date` parameter, you wish to load schedules for (converted to UTC - see main description). From 0 to 23, where 0 is midnight. (required, format: int32)
  --duration: int # The number of hours of schedules to load from the base `hour` parameter. This may be negative or positive depending on whether you want to load past or future schedules. Minimum value is -24, maximum is 24. A value of zero is invalid. (required, format: int32)
  --intersect: oneof<nothing, bool> # Flag indicating whether schedules should intersect or be contained in the provided interval. If set to `true`, the result will contain all schedules where either schedule start time or end time touches the provided interval. If set to `false`, only schedules fully contained in the given period will be returned. (default: false)
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/schedules"
    query: [{name: channels, var: channels, style: csv, required: true}, {name: date, var: date, required: true}, {name: hour, var: hour, required: true}, {name: duration, var: duration, required: true}, {name: intersect, var: intersect}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channels: $channels, date: $date, hour: $hour, duration: $duration, intersect: $intersect, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search the catalog of items and people.
#
# GET /search
# Returns: record<items: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, movies: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, other: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, people: table<name: string, path: string>, term: string, total: int, tv: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>>
# operationId: search
export def "search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --term: string # The search term to query. (required)
  --include: list<string> # By default people, movies and tv (shows + programs) will be included in the search results. If the `cas` feature flag is set, "other" items (`customAsset`s) will also be included by default If you don't want all of these types you can specifiy the specific includes you care about.
  --group: oneof<nothing, bool> # When this option is set, instead of all search result items being returned in a single list, they will instead be returned under two lists. One for movies and another for tv (shows + programs). if the `cas` feature flag is set, a third `other` list will be included containing `customAsset` results Default is undefined meaning items will be returned in a single list. The array of `people` results will always be separate from items.
  --max-results: int # The maximum number of results to return. (format: int32, default: 20)
  --max-rating: string # The maximum rating (inclusive) of items returned, e.g. 'auoflc-pg'.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search"
    query: [{name: term, var: term, required: true}, {name: include, var: include, style: csv}, {name: group, var: group}, {name: max_results, var: max_results}, {name: max_rating, var: max_rating}, {name: device, var: device}, {name: sub, var: sub}, {name: segments, var: segments, style: csv}, {name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    term: $term, include: $include, group: $group, max_results: $max_results, max_rating: $max_rating, device: $device, sub: $sub, segments: $segments, ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# When an account is created an email is sent to the email address of the new account. This contains a link, which once clicked, verifies the email address of the account is correct. The link contains a token as a query parameter which should be passed as the authorization bearer token to this endpoint to complete email verification. The token has en expiry, so if the link is not clicked before it expires, the account holder may need to request a new verification email be sent. This can be done via the endpoint /account/request-email-verification.
#
# POST /verify-email
# operationId: verifyEmail
export def "verify-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> any {
  http-request {
    method: post
    path: "/verify-email"
    query: [{name: ff, var: ff, style: csv}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ff: $ff, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
