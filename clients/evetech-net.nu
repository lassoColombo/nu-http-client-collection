# Auto-generated client for EVE Swagger Interface v0.8.6
# Source: https://api.apis.guru/v2/specs/evetech.net/0.8.6/swagger.json
# Auth: --token flag or $env.EVE_SWAGGER_INTERFACE_TOKEN

const CLIENT = {
  base_url: "https://esi.evetech.net/latest"
  token_env_var: "EVE_SWAGGER_INTERFACE_TOKEN"
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

def base-url-completer [] { ["https://esi.evetech.net/latest"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def datasource-completer [] { ["singularity" "tranquility"] }
def response-completer [] { ["accepted" "declined" "tentative"] }
def color-completer [] { ["#0000fe" "#006634" "#0099ff" "#00ff33" "#01ffff" "#349800" "#660066" "#666666" "#999999" "#99ffff" "#9a0000" "#ccff9a" "#e6e6e6" "#fe0000" "#ff6600" "#ffff01" "#ffffcd" "#ffffff"] }
def language-completer [] { ["de" "en-us" "fr" "ja" "ru" "zh"] }
def accept-language-completer [] { ["de" "en-us" "fr" "ja" "ru" "zh"] }
def role-completer [] { ["fleet_commander" "squad_commander" "squad_member" "wing_commander"] }
def order-type-completer [] { ["all" "buy" "sell"] }
def flag-completer [] { ["insecure" "secure" "shortest"] }
def filter-completer [] { ["manufacturing_basic" "market"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-alliances: "list<int>"
    get-alliances-alliance-id: "record<creator_corporation_id: int, creator_id: int, date_founded: string, executor_corporation_id: int, faction_id: int, name: string, ticker: string>"
    get-alliances-alliance-id-contacts: "table<contact_id: int, contact_type: string, label_ids: list<int>, standing: float>"
    get-alliances-alliance-id-contacts-labels: "table<label_id: int, label_name: string>"
    get-alliances-alliance-id-corporations: "list<int>"
    get-alliances-alliance-id-icons: "record<px128x128: string, px64x64: string>"
    post-characters-affiliation: "table<alliance_id: int, character_id: int, corporation_id: int, faction_id: int>"
    get-characters-character-id: "record<alliance_id: int, ancestry_id: int, birthday: string, bloodline_id: int, corporation_id: int, description: string, faction_id: int, gender: string, name: string, race_id: int, security_status: float>"
    get-characters-character-id-agents-research: "table<agent_id: int, points_per_day: float, remainder_points: float, skill_type_id: int, started_at: string>"
    get-characters-character-id-assets: "table<is_blueprint_copy: bool, is_singleton: bool, item_id: int, location_flag: string, location_id: int, location_type: string, quantity: int, type_id: int>"
    post-characters-character-id-assets-locations: "table<item_id: int, position: record<x: float, y: float, z: float>>"
    post-characters-character-id-assets-names: "table<item_id: int, name: string>"
    get-characters-character-id-attributes: "record<accrued_remap_cooldown_date: string, bonus_remaps: int, charisma: int, intelligence: int, last_remap_date: string, memory: int, perception: int, willpower: int>"
    get-characters-character-id-blueprints: "table<item_id: int, location_flag: string, location_id: int, material_efficiency: int, quantity: int, runs: int, time_efficiency: int, type_id: int>"
    get-characters-character-id-bookmarks: "table<bookmark_id: int, coordinates: record<x: float, y: float, z: float>, created: string, creator_id: int, folder_id: int, item: record<item_id: int, type_id: int>, label: string, location_id: int, notes: string>"
    get-characters-character-id-bookmarks-folders: "table<folder_id: int, name: string>"
    get-characters-character-id-calendar: "table<event_date: string, event_id: int, event_response: string, importance: int, title: string>"
    get-characters-character-id-calendar-event-id: "record<date: string, duration: int, event_id: int, importance: int, owner_id: int, owner_name: string, owner_type: string, response: string, text: string, title: string>"
    get-characters-character-id-calendar-event-id-attendees: "table<character_id: int, event_response: string>"
    get-characters-character-id-clones: "record<home_location: record<location_id: int, location_type: string>, jump_clones: table<implants: list, jump_clone_id: int, location_id: int, location_type: string, name: string>, last_clone_jump_date: string, last_station_change_date: string>"
    get-characters-character-id-contacts: "table<contact_id: int, contact_type: string, is_blocked: bool, is_watched: bool, label_ids: list<int>, standing: float>"
    post-characters-character-id-contacts: "list<int>"
    get-characters-character-id-contacts-labels: "table<label_id: int, label_name: string>"
    get-characters-character-id-contracts: "table<acceptor_id: int, assignee_id: int, availability: string, buyout: float, collateral: float, contract_id: int, date_accepted: string, date_completed: string, date_expired: string, date_issued: string, days_to_complete: int, end_location_id: int, for_corporation: bool, issuer_corporation_id: int, issuer_id: int, price: float, reward: float, start_location_id: int, status: string, title: string, type: string, volume: float>"
    get-characters-character-id-contracts-contract-id-bids: "table<amount: float, bid_id: int, bidder_id: int, date_bid: string>"
    get-characters-character-id-contracts-contract-id-items: "table<is_included: bool, is_singleton: bool, quantity: int, raw_quantity: int, record_id: int, type_id: int>"
    get-characters-character-id-corporationhistory: "table<corporation_id: int, is_deleted: bool, record_id: int, start_date: string>"
    post-characters-character-id-cspa: "float"
    get-characters-character-id-fatigue: "record<jump_fatigue_expire_date: string, last_jump_date: string, last_update_date: string>"
    get-characters-character-id-fittings: "table<description: string, fitting_id: int, items: list<record>, name: string, ship_type_id: int>"
    post-characters-character-id-fittings: "record<fitting_id: int>"
    get-characters-character-id-fleet: "record<fleet_id: int, role: string, squad_id: int, wing_id: int>"
    get-characters-character-id-fw-stats: "record<current_rank: int, enlisted_on: string, faction_id: int, highest_rank: int, kills: record<last_week: int, total: int, yesterday: int>, victory_points: record<last_week: int, total: int, yesterday: int>>"
    get-characters-character-id-implants: "list<int>"
    get-characters-character-id-industry-jobs: "table<activity_id: int, blueprint_id: int, blueprint_location_id: int, blueprint_type_id: int, completed_character_id: int, completed_date: string, cost: float, duration: int, end_date: string, facility_id: int, installer_id: int, job_id: int, licensed_runs: int, output_location_id: int, pause_date: string, probability: float, product_type_id: int, runs: int, start_date: string, station_id: int, status: string, successful_runs: int>"
    get-characters-character-id-killmails-recent: "table<killmail_hash: string, killmail_id: int>"
    get-characters-character-id-location: "record<solar_system_id: int, station_id: int, structure_id: int>"
    get-characters-character-id-loyalty-points: "table<corporation_id: int, loyalty_points: int>"
    get-characters-character-id-mail: "table<from: int, is_read: bool, labels: list<int>, mail_id: int, recipients: list<record>, subject: string, timestamp: string>"
    post-characters-character-id-mail: "int"
    get-characters-character-id-mail-labels: "record<labels: table<color: string, label_id: int, name: string, unread_count: int>, total_unread_count: int>"
    post-characters-character-id-mail-labels: "int"
    get-characters-character-id-mail-lists: "table<mailing_list_id: int, name: string>"
    get-characters-character-id-mail-mail-id: "record<body: string, from: int, labels: list<int>, read: bool, recipients: table<recipient_id: int, recipient_type: string>, subject: string, timestamp: string>"
    get-characters-character-id-medals: "table<corporation_id: int, date: string, description: string, graphics: list<record>, issuer_id: int, medal_id: int, reason: string, status: string, title: string>"
    get-characters-character-id-mining: "table<date: string, quantity: int, solar_system_id: int, type_id: int>"
    get-characters-character-id-notifications: "table<is_read: bool, notification_id: int, sender_id: int, sender_type: string, text: string, timestamp: string, type: string>"
    get-characters-character-id-notifications-contacts: "table<message: string, notification_id: int, send_date: string, sender_character_id: int, standing_level: float>"
    get-characters-character-id-online: "record<last_login: string, last_logout: string, logins: int, online: bool>"
    get-characters-character-id-opportunities: "table<completed_at: string, task_id: int>"
    get-characters-character-id-orders: "table<duration: int, escrow: float, is_buy_order: bool, is_corporation: bool, issued: string, location_id: int, min_volume: int, order_id: int, price: float, range: string, region_id: int, type_id: int, volume_remain: int, volume_total: int>"
    get-characters-character-id-orders-history: "table<duration: int, escrow: float, is_buy_order: bool, is_corporation: bool, issued: string, location_id: int, min_volume: int, order_id: int, price: float, range: string, region_id: int, state: string, type_id: int, volume_remain: int, volume_total: int>"
    get-characters-character-id-planets: "table<last_update: string, num_pins: int, owner_id: int, planet_id: int, planet_type: string, solar_system_id: int, upgrade_level: int>"
    get-characters-character-id-planets-planet-id: "record<links: table<destination_pin_id: int, link_level: int, source_pin_id: int>, pins: table<contents: list, expiry_time: string, extractor_details: record, factory_details: record, install_time: string, last_cycle_start: string, latitude: float, longitude: float, pin_id: int, schematic_id: int, type_id: int>, routes: table<content_type_id: int, destination_pin_id: int, quantity: float, route_id: int, source_pin_id: int, waypoints: list>>"
    get-characters-character-id-portrait: "record<px128x128: string, px256x256: string, px512x512: string, px64x64: string>"
    get-characters-character-id-roles: "record<roles: list<string>, roles_at_base: list<string>, roles_at_hq: list<string>, roles_at_other: list<string>>"
    get-characters-character-id-search: "record<agent: list<int>, alliance: list<int>, character: list<int>, constellation: list<int>, corporation: list<int>, faction: list<int>, inventory_type: list<int>, region: list<int>, solar_system: list<int>, station: list<int>, structure: list<int>>"
    get-characters-character-id-ship: "record<ship_item_id: int, ship_name: string, ship_type_id: int>"
    get-characters-character-id-skillqueue: "table<finish_date: string, finished_level: int, level_end_sp: int, level_start_sp: int, queue_position: int, skill_id: int, start_date: string, training_start_sp: int>"
    get-characters-character-id-skills: "record<skills: table<active_skill_level: int, skill_id: int, skillpoints_in_skill: int, trained_skill_level: int>, total_sp: int, unallocated_sp: int>"
    get-characters-character-id-standings: "table<from_id: int, from_type: string, standing: float>"
    get-characters-character-id-stats: "table<character: record<days_of_activity: int, minutes: int, sessions_started: int>, combat: record<cap_drainedby_npc: int, cap_drainedby_pc: int, cap_draining_pc: int, criminal_flag_set: int, damage_from_np_cs_amount: int, damage_from_np_cs_num_shots: int, damage_from_players_bomb_amount: int, damage_from_players_bomb_num_shots: int, damage_from_players_combat_drone_amount: int, damage_from_players_combat_drone_num_shots: int, damage_from_players_energy_amount: int, damage_from_players_energy_num_shots: int, damage_from_players_fighter_bomber_amount: int, damage_from_players_fighter_bomber_num_shots: int, damage_from_players_fighter_drone_amount: int, damage_from_players_fighter_drone_num_shots: int, damage_from_players_hybrid_amount: int, damage_from_players_hybrid_num_shots: int, damage_from_players_missile_amount: int, damage_from_players_missile_num_shots: int, damage_from_players_projectile_amount: int, damage_from_players_projectile_num_shots: int, damage_from_players_smart_bomb_amount: int, damage_from_players_smart_bomb_num_shots: int, damage_from_players_super_amount: int, damage_from_players_super_num_shots: int, damage_from_structures_total_amount: int, damage_from_structures_total_num_shots: int, damage_to_players_bomb_amount: int, damage_to_players_bomb_num_shots: int, damage_to_players_combat_drone_amount: int, damage_to_players_combat_drone_num_shots: int, damage_to_players_energy_amount: int, damage_to_players_energy_num_shots: int, damage_to_players_fighter_bomber_amount: int, damage_to_players_fighter_bomber_num_shots: int, damage_to_players_fighter_drone_amount: int, damage_to_players_fighter_drone_num_shots: int, damage_to_players_hybrid_amount: int, damage_to_players_hybrid_num_shots: int, damage_to_players_missile_amount: int, damage_to_players_missile_num_shots: int, damage_to_players_projectile_amount: int, damage_to_players_projectile_num_shots: int, damage_to_players_smart_bomb_amount: int, damage_to_players_smart_bomb_num_shots: int, damage_to_players_super_amount: int, damage_to_players_super_num_shots: int, damage_to_structures_total_amount: int, damage_to_structures_total_num_shots: int, deaths_high_sec: int, deaths_low_sec: int, deaths_null_sec: int, deaths_pod_high_sec: int, deaths_pod_low_sec: int, deaths_pod_null_sec: int, deaths_pod_wormhole: int, deaths_wormhole: int, drone_engage: int, dscans: int, duel_requested: int, engagement_register: int, kills_assists: int, kills_high_sec: int, kills_low_sec: int, kills_null_sec: int, kills_pod_high_sec: int, kills_pod_low_sec: int, kills_pod_null_sec: int, kills_pod_wormhole: int, kills_wormhole: int, npc_flag_set: int, probe_scans: int, pvp_flag_set: int, repair_armor_by_remote_amount: int, repair_armor_remote_amount: int, repair_armor_self_amount: int, repair_capacitor_by_remote_amount: int, repair_capacitor_remote_amount: int, repair_capacitor_self_amount: int, repair_hull_by_remote_amount: int, repair_hull_remote_amount: int, repair_hull_self_amount: int, repair_shield_by_remote_amount: int, repair_shield_remote_amount: int, repair_shield_self_amount: int, self_destructs: int, warp_scramble_pc: int, warp_scrambledby_npc: int, warp_scrambledby_pc: int, weapon_flag_set: int, webifiedby_npc: int, webifiedby_pc: int, webifying_pc: int>, industry: record<hacking_successes: int, jobs_cancelled: int, jobs_completed_copy_blueprint: int, jobs_completed_invention: int, jobs_completed_manufacture: int, jobs_completed_manufacture_asteroid: int, jobs_completed_manufacture_asteroid_quantity: int, jobs_completed_manufacture_charge: int, jobs_completed_manufacture_charge_quantity: int, jobs_completed_manufacture_commodity: int, jobs_completed_manufacture_commodity_quantity: int, jobs_completed_manufacture_deployable: int, jobs_completed_manufacture_deployable_quantity: int, jobs_completed_manufacture_drone: int, jobs_completed_manufacture_drone_quantity: int, jobs_completed_manufacture_implant: int, jobs_completed_manufacture_implant_quantity: int, jobs_completed_manufacture_module: int, jobs_completed_manufacture_module_quantity: int, jobs_completed_manufacture_other: int, jobs_completed_manufacture_other_quantity: int, jobs_completed_manufacture_ship: int, jobs_completed_manufacture_ship_quantity: int, jobs_completed_manufacture_structure: int, jobs_completed_manufacture_structure_quantity: int, jobs_completed_manufacture_subsystem: int, jobs_completed_manufacture_subsystem_quantity: int, jobs_completed_material_productivity: int, jobs_completed_time_productivity: int, jobs_started_copy_blueprint: int, jobs_started_invention: int, jobs_started_manufacture: int, jobs_started_material_productivity: int, jobs_started_time_productivity: int, reprocess_item: int, reprocess_item_quantity: int>, inventory: record<abandon_loot_quantity: int, trash_item_quantity: int>, isk: record<in: int, out: int>, market: record<accept_contracts_courier: int, accept_contracts_item_exchange: int, buy_orders_placed: int, cancel_market_order: int, create_contracts_auction: int, create_contracts_courier: int, create_contracts_item_exchange: int, deliver_courier_contract: int, isk_gained: int, isk_spent: int, modify_market_order: int, search_contracts: int, sell_orders_placed: int>, mining: record<drone_mine: int, ore_arkonor: int, ore_bistot: int, ore_crokite: int, ore_dark_ochre: int, ore_gneiss: int, ore_harvestable_cloud: int, ore_hedbergite: int, ore_hemorphite: int, ore_ice: int, ore_jaspet: int, ore_kernite: int, ore_mercoxit: int, ore_omber: int, ore_plagioclase: int, ore_pyroxeres: int, ore_scordite: int, ore_spodumain: int, ore_veldspar: int>, module: record<activations_armor_hardener: int, activations_armor_repair_unit: int, activations_armor_resistance_shift_hardener: int, activations_automated_targeting_system: int, activations_bastion: int, activations_bomb_launcher: int, activations_capacitor_booster: int, activations_cargo_scanner: int, activations_cloaking_device: int, activations_clone_vat_bay: int, activations_cynosural_field: int, activations_damage_control: int, activations_data_miners: int, activations_drone_control_unit: int, activations_drone_tracking_modules: int, activations_eccm: int, activations_ecm: int, activations_ecm_burst: int, activations_energy_destabilizer: int, activations_energy_vampire: int, activations_energy_weapon: int, activations_festival_launcher: int, activations_frequency_mining_laser: int, activations_fueled_armor_repairer: int, activations_fueled_shield_booster: int, activations_gang_coordinator: int, activations_gas_cloud_harvester: int, activations_hull_repair_unit: int, activations_hybrid_weapon: int, activations_industrial_core: int, activations_interdiction_sphere_launcher: int, activations_micro_jump_drive: int, activations_mining_laser: int, activations_missile_launcher: int, activations_passive_targeting_system: int, activations_probe_launcher: int, activations_projected_eccm: int, activations_projectile_weapon: int, activations_propulsion_module: int, activations_remote_armor_repairer: int, activations_remote_capacitor_transmitter: int, activations_remote_ecm_burst: int, activations_remote_hull_repairer: int, activations_remote_sensor_booster: int, activations_remote_sensor_damper: int, activations_remote_shield_booster: int, activations_remote_tracking_computer: int, activations_salvager: int, activations_sensor_booster: int, activations_shield_booster: int, activations_shield_hardener: int, activations_ship_scanner: int, activations_siege: int, activations_smart_bomb: int, activations_stasis_web: int, activations_strip_miner: int, activations_super_weapon: int, activations_survey_scanner: int, activations_target_breaker: int, activations_target_painter: int, activations_tracking_computer: int, activations_tracking_disruptor: int, activations_tractor_beam: int, activations_triage: int, activations_warp_disrupt_field_generator: int, activations_warp_scrambler: int, link_weapons: int, overload: int, repairs: int>, orbital: record<strike_characters_killed: int, strike_damage_to_players_armor_amount: int, strike_damage_to_players_shield_amount: int>, pve: record<dungeons_completed_agent: int, dungeons_completed_distribution: int, missions_succeeded: int, missions_succeeded_epic_arc: int>, social: record<add_contact_bad: int, add_contact_good: int, add_contact_high: int, add_contact_horrible: int, add_contact_neutral: int, add_note: int, added_as_contact_bad: int, added_as_contact_good: int, added_as_contact_high: int, added_as_contact_horrible: int, added_as_contact_neutral: int, calendar_event_created: int, chat_messages_alliance: int, chat_messages_constellation: int, chat_messages_corporation: int, chat_messages_fleet: int, chat_messages_region: int, chat_messages_solarsystem: int, chat_messages_warfaction: int, chat_total_message_length: int, direct_trades: int, fleet_broadcasts: int, fleet_joins: int, mails_received: int, mails_sent: int>, travel: record<acceleration_gate_activations: int, align_to: int, distance_warped_high_sec: int, distance_warped_low_sec: int, distance_warped_null_sec: int, distance_warped_wormhole: int, docks_high_sec: int, docks_low_sec: int, docks_null_sec: int, jumps_stargate_high_sec: int, jumps_stargate_low_sec: int, jumps_stargate_null_sec: int, jumps_wormhole: int, warps_high_sec: int, warps_low_sec: int, warps_null_sec: int, warps_to_bookmark: int, warps_to_celestial: int, warps_to_fleet_member: int, warps_to_scan_result: int, warps_wormhole: int>, year: int>"
    get-characters-character-id-titles: "table<name: string, title_id: int>"
    get-characters-character-id-wallet: "float"
    get-characters-character-id-wallet-journal: "table<amount: float, balance: float, context_id: int, context_id_type: string, date: string, description: string, first_party_id: int, id: int, reason: string, ref_type: string, second_party_id: int, tax: float, tax_receiver_id: int>"
    get-characters-character-id-wallet-transactions: "table<client_id: int, date: string, is_buy: bool, is_personal: bool, journal_ref_id: int, location_id: int, quantity: int, transaction_id: int, type_id: int, unit_price: float>"
    get-contracts-public-bids-contract-id: "table<amount: float, bid_id: int, date_bid: string>"
    get-contracts-public-items-contract-id: "table<is_blueprint_copy: bool, is_included: bool, item_id: int, material_efficiency: int, quantity: int, record_id: int, runs: int, time_efficiency: int, type_id: int>"
    get-contracts-public-region-id: "table<buyout: float, collateral: float, contract_id: int, date_expired: string, date_issued: string, days_to_complete: int, end_location_id: int, for_corporation: bool, issuer_corporation_id: int, issuer_id: int, price: float, reward: float, start_location_id: int, title: string, type: string, volume: float>"
    get-corporation-corporation-id-mining-extractions: "table<chunk_arrival_time: string, extraction_start_time: string, moon_id: int, natural_decay_time: string, structure_id: int>"
    get-corporation-corporation-id-mining-observers: "table<last_updated: string, observer_id: int, observer_type: string>"
    get-corporation-corporation-id-mining-observers-observer-id: "table<character_id: int, last_updated: string, quantity: int, recorded_corporation_id: int, type_id: int>"
    get-corporations-npccorps: "list<int>"
    get-corporations-corporation-id: "record<alliance_id: int, ceo_id: int, creator_id: int, date_founded: string, description: string, faction_id: int, home_station_id: int, member_count: int, name: string, shares: int, tax_rate: float, ticker: string, url: string, war_eligible: bool>"
    get-corporations-corporation-id-alliancehistory: "table<alliance_id: int, is_deleted: bool, record_id: int, start_date: string>"
    get-corporations-corporation-id-assets: "table<is_blueprint_copy: bool, is_singleton: bool, item_id: int, location_flag: string, location_id: int, location_type: string, quantity: int, type_id: int>"
    post-corporations-corporation-id-assets-locations: "table<item_id: int, position: record<x: float, y: float, z: float>>"
    post-corporations-corporation-id-assets-names: "table<item_id: int, name: string>"
    get-corporations-corporation-id-blueprints: "table<item_id: int, location_flag: string, location_id: int, material_efficiency: int, quantity: int, runs: int, time_efficiency: int, type_id: int>"
    get-corporations-corporation-id-bookmarks: "table<bookmark_id: int, coordinates: record<x: float, y: float, z: float>, created: string, creator_id: int, folder_id: int, item: record<item_id: int, type_id: int>, label: string, location_id: int, notes: string>"
    get-corporations-corporation-id-bookmarks-folders: "table<creator_id: int, folder_id: int, name: string>"
    get-corporations-corporation-id-contacts: "table<contact_id: int, contact_type: string, is_watched: bool, label_ids: list<int>, standing: float>"
    get-corporations-corporation-id-contacts-labels: "table<label_id: int, label_name: string>"
    get-corporations-corporation-id-containers-logs: "table<action: string, character_id: int, container_id: int, container_type_id: int, location_flag: string, location_id: int, logged_at: string, new_config_bitmask: int, old_config_bitmask: int, password_type: string, quantity: int, type_id: int>"
    get-corporations-corporation-id-contracts: "table<acceptor_id: int, assignee_id: int, availability: string, buyout: float, collateral: float, contract_id: int, date_accepted: string, date_completed: string, date_expired: string, date_issued: string, days_to_complete: int, end_location_id: int, for_corporation: bool, issuer_corporation_id: int, issuer_id: int, price: float, reward: float, start_location_id: int, status: string, title: string, type: string, volume: float>"
    get-corporations-corporation-id-contracts-contract-id-bids: "table<amount: float, bid_id: int, bidder_id: int, date_bid: string>"
    get-corporations-corporation-id-contracts-contract-id-items: "table<is_included: bool, is_singleton: bool, quantity: int, raw_quantity: int, record_id: int, type_id: int>"
    get-corporations-corporation-id-customs-offices: "table<alliance_tax_rate: float, allow_access_with_standings: bool, allow_alliance_access: bool, bad_standing_tax_rate: float, corporation_tax_rate: float, excellent_standing_tax_rate: float, good_standing_tax_rate: float, neutral_standing_tax_rate: float, office_id: int, reinforce_exit_end: int, reinforce_exit_start: int, standing_level: string, system_id: int, terrible_standing_tax_rate: float>"
    get-corporations-corporation-id-divisions: "record<hangar: table<division: int, name: string>, wallet: table<division: int, name: string>>"
    get-corporations-corporation-id-facilities: "table<facility_id: int, system_id: int, type_id: int>"
    get-corporations-corporation-id-fw-stats: "record<enlisted_on: string, faction_id: int, kills: record<last_week: int, total: int, yesterday: int>, pilots: int, victory_points: record<last_week: int, total: int, yesterday: int>>"
    get-corporations-corporation-id-icons: "record<px128x128: string, px256x256: string, px64x64: string>"
    get-corporations-corporation-id-industry-jobs: "table<activity_id: int, blueprint_id: int, blueprint_location_id: int, blueprint_type_id: int, completed_character_id: int, completed_date: string, cost: float, duration: int, end_date: string, facility_id: int, installer_id: int, job_id: int, licensed_runs: int, location_id: int, output_location_id: int, pause_date: string, probability: float, product_type_id: int, runs: int, start_date: string, status: string, successful_runs: int>"
    get-corporations-corporation-id-killmails-recent: "table<killmail_hash: string, killmail_id: int>"
    get-corporations-corporation-id-medals: "table<created_at: string, creator_id: int, description: string, medal_id: int, title: string>"
    get-corporations-corporation-id-medals-issued: "table<character_id: int, issued_at: string, issuer_id: int, medal_id: int, reason: string, status: string>"
    get-corporations-corporation-id-members: "list<int>"
    get-corporations-corporation-id-members-limit: "int"
    get-corporations-corporation-id-members-titles: "table<character_id: int, titles: list<int>>"
    get-corporations-corporation-id-membertracking: "table<base_id: int, character_id: int, location_id: int, logoff_date: string, logon_date: string, ship_type_id: int, start_date: string>"
    get-corporations-corporation-id-orders: "table<duration: int, escrow: float, is_buy_order: bool, issued: string, issued_by: int, location_id: int, min_volume: int, order_id: int, price: float, range: string, region_id: int, type_id: int, volume_remain: int, volume_total: int, wallet_division: int>"
    get-corporations-corporation-id-orders-history: "table<duration: int, escrow: float, is_buy_order: bool, issued: string, issued_by: int, location_id: int, min_volume: int, order_id: int, price: float, range: string, region_id: int, state: string, type_id: int, volume_remain: int, volume_total: int, wallet_division: int>"
    get-corporations-corporation-id-roles: "table<character_id: int, grantable_roles: list<string>, grantable_roles_at_base: list<string>, grantable_roles_at_hq: list<string>, grantable_roles_at_other: list<string>, roles: list<string>, roles_at_base: list<string>, roles_at_hq: list<string>, roles_at_other: list<string>>"
    get-corporations-corporation-id-roles-history: "table<changed_at: string, character_id: int, issuer_id: int, new_roles: list<string>, old_roles: list<string>, role_type: string>"
    get-corporations-corporation-id-shareholders: "table<share_count: int, shareholder_id: int, shareholder_type: string>"
    get-corporations-corporation-id-standings: "table<from_id: int, from_type: string, standing: float>"
    get-corporations-corporation-id-starbases: "table<moon_id: int, onlined_since: string, reinforced_until: string, starbase_id: int, state: string, system_id: int, type_id: int, unanchor_at: string>"
    get-corporations-corporation-id-starbases-starbase-id: "record<allow_alliance_members: bool, allow_corporation_members: bool, anchor: string, attack_if_at_war: bool, attack_if_other_security_status_dropping: bool, attack_security_status_threshold: float, attack_standing_threshold: float, fuel_bay_take: string, fuel_bay_view: string, fuels: table<quantity: int, type_id: int>, offline: string, online: string, unanchor: string, use_alliance_standings: bool>"
    get-corporations-corporation-id-structures: "table<corporation_id: int, fuel_expires: string, next_reinforce_apply: string, next_reinforce_hour: int, next_reinforce_weekday: int, profile_id: int, reinforce_hour: int, reinforce_weekday: int, services: list<record>, state: string, state_timer_end: string, state_timer_start: string, structure_id: int, system_id: int, type_id: int, unanchors_at: string>"
    get-corporations-corporation-id-titles: "table<grantable_roles: list<string>, grantable_roles_at_base: list<string>, grantable_roles_at_hq: list<string>, grantable_roles_at_other: list<string>, name: string, roles: list<string>, roles_at_base: list<string>, roles_at_hq: list<string>, roles_at_other: list<string>, title_id: int>"
    get-corporations-corporation-id-wallets: "table<balance: float, division: int>"
    get-corporations-corporation-id-wallets-division-journal: "table<amount: float, balance: float, context_id: int, context_id_type: string, date: string, description: string, first_party_id: int, id: int, reason: string, ref_type: string, second_party_id: int, tax: float, tax_receiver_id: int>"
    get-corporations-corporation-id-wallets-division-transactions: "table<client_id: int, date: string, is_buy: bool, journal_ref_id: int, location_id: int, quantity: int, transaction_id: int, type_id: int, unit_price: float>"
    get-dogma-attributes: "list<int>"
    get-dogma-attributes-attribute-id: "record<attribute_id: int, default_value: float, description: string, display_name: string, high_is_good: bool, icon_id: int, name: string, published: bool, stackable: bool, unit_id: int>"
    get-dogma-dynamic-items-type-id-item-id: "record<created_by: int, dogma_attributes: table<attribute_id: int, value: float>, dogma_effects: table<effect_id: int, is_default: bool>, mutator_type_id: int, source_type_id: int>"
    get-dogma-effects: "list<int>"
    get-dogma-effects-effect-id: "record<description: string, disallow_auto_repeat: bool, discharge_attribute_id: int, display_name: string, duration_attribute_id: int, effect_category: int, effect_id: int, electronic_chance: bool, falloff_attribute_id: int, icon_id: int, is_assistance: bool, is_offensive: bool, is_warp_safe: bool, modifiers: table<domain: string, effect_id: int, func: string, modified_attribute_id: int, modifying_attribute_id: int, operator: int>, name: string, post_expression: int, pre_expression: int, published: bool, range_attribute_id: int, range_chance: bool, tracking_speed_attribute_id: int>"
    get-fleets-fleet-id: "record<is_free_move: bool, is_registered: bool, is_voice_enabled: bool, motd: string>"
    get-fleets-fleet-id-members: "table<character_id: int, join_time: string, role: string, role_name: string, ship_type_id: int, solar_system_id: int, squad_id: int, station_id: int, takes_fleet_warp: bool, wing_id: int>"
    get-fleets-fleet-id-wings: "table<id: int, name: string, squads: list<record>>"
    post-fleets-fleet-id-wings: "record<wing_id: int>"
    post-fleets-fleet-id-wings-wing-id-squads: "record<squad_id: int>"
    get-fw-leaderboards: "record<kills: record<active_total: list<record>, last_week: list<record>, yesterday: list<record>>, victory_points: record<active_total: list<record>, last_week: list<record>, yesterday: list<record>>>"
    get-fw-leaderboards-characters: "record<kills: record<active_total: list<record>, last_week: list<record>, yesterday: list<record>>, victory_points: record<active_total: list<record>, last_week: list<record>, yesterday: list<record>>>"
    get-fw-leaderboards-corporations: "record<kills: record<active_total: list<record>, last_week: list<record>, yesterday: list<record>>, victory_points: record<active_total: list<record>, last_week: list<record>, yesterday: list<record>>>"
    get-fw-stats: "table<faction_id: int, kills: record<last_week: int, total: int, yesterday: int>, pilots: int, systems_controlled: int, victory_points: record<last_week: int, total: int, yesterday: int>>"
    get-fw-systems: "table<contested: string, occupier_faction_id: int, owner_faction_id: int, solar_system_id: int, victory_points: int, victory_points_threshold: int>"
    get-fw-wars: "table<against_id: int, faction_id: int>"
    get-incursions: "table<constellation_id: int, faction_id: int, has_boss: bool, infested_solar_systems: list<int>, influence: float, staging_solar_system_id: int, state: string, type: string>"
    get-industry-facilities: "table<facility_id: int, owner_id: int, region_id: int, solar_system_id: int, tax: float, type_id: int>"
    get-industry-systems: "table<cost_indices: list<record>, solar_system_id: int>"
    get-insurance-prices: "table<levels: list<record>, type_id: int>"
    get-killmails-killmail-id-killmail-hash: "record<attackers: table<alliance_id: int, character_id: int, corporation_id: int, damage_done: int, faction_id: int, final_blow: bool, security_status: float, ship_type_id: int, weapon_type_id: int>, killmail_id: int, killmail_time: string, moon_id: int, solar_system_id: int, victim: record<alliance_id: int, character_id: int, corporation_id: int, damage_taken: int, faction_id: int, items: list<record>, position: record<x: float, y: float, z: float>, ship_type_id: int>, war_id: int>"
    get-loyalty-stores-corporation-id-offers: "table<ak_cost: int, isk_cost: int, lp_cost: int, offer_id: int, quantity: int, required_items: list<record>, type_id: int>"
    get-markets-groups: "list<int>"
    get-markets-groups-market-group-id: "record<description: string, market_group_id: int, name: string, parent_group_id: int, types: list<int>>"
    get-markets-prices: "table<adjusted_price: float, average_price: float, type_id: int>"
    get-markets-structures-structure-id: "table<duration: int, is_buy_order: bool, issued: string, location_id: int, min_volume: int, order_id: int, price: float, range: string, type_id: int, volume_remain: int, volume_total: int>"
    get-markets-region-id-history: "table<average: float, date: string, highest: float, lowest: float, order_count: int, volume: int>"
    get-markets-region-id-orders: "table<duration: int, is_buy_order: bool, issued: string, location_id: int, min_volume: int, order_id: int, price: float, range: string, system_id: int, type_id: int, volume_remain: int, volume_total: int>"
    get-markets-region-id-types: "list<int>"
    get-opportunities-groups: "list<int>"
    get-opportunities-groups-group-id: "record<connected_groups: list<int>, description: string, group_id: int, name: string, notification: string, required_tasks: list<int>>"
    get-opportunities-tasks: "list<int>"
    get-opportunities-tasks-task-id: "record<description: string, name: string, notification: string, task_id: int>"
    get-route-origin-destination: "list<int>"
    get-search: "record<agent: list<int>, alliance: list<int>, character: list<int>, constellation: list<int>, corporation: list<int>, faction: list<int>, inventory_type: list<int>, region: list<int>, solar_system: list<int>, station: list<int>>"
    get-sovereignty-campaigns: "table<attackers_score: float, campaign_id: int, constellation_id: int, defender_id: int, defender_score: float, event_type: string, participants: list<record>, solar_system_id: int, start_time: string, structure_id: int>"
    get-sovereignty-map: "table<alliance_id: int, corporation_id: int, faction_id: int, system_id: int>"
    get-sovereignty-structures: "table<alliance_id: int, solar_system_id: int, structure_id: int, structure_type_id: int, vulnerability_occupancy_level: float, vulnerable_end_time: string, vulnerable_start_time: string>"
    get-status: "record<players: int, server_version: string, start_time: string, vip: bool>"
    get-universe-ancestries: "table<bloodline_id: int, description: string, icon_id: int, id: int, name: string, short_description: string>"
    get-universe-asteroid-belts-asteroid-belt-id: "record<name: string, position: record<x: float, y: float, z: float>, system_id: int>"
    get-universe-bloodlines: "table<bloodline_id: int, charisma: int, corporation_id: int, description: string, intelligence: int, memory: int, name: string, perception: int, race_id: int, ship_type_id: int, willpower: int>"
    get-universe-categories: "list<int>"
    get-universe-categories-category-id: "record<category_id: int, groups: list<int>, name: string, published: bool>"
    get-universe-constellations: "list<int>"
    get-universe-constellations-constellation-id: "record<constellation_id: int, name: string, position: record<x: float, y: float, z: float>, region_id: int, systems: list<int>>"
    get-universe-factions: "table<corporation_id: int, description: string, faction_id: int, is_unique: bool, militia_corporation_id: int, name: string, size_factor: float, solar_system_id: int, station_count: int, station_system_count: int>"
    get-universe-graphics: "list<int>"
    get-universe-graphics-graphic-id: "record<collision_file: string, graphic_file: string, graphic_id: int, icon_folder: string, sof_dna: string, sof_fation_name: string, sof_hull_name: string, sof_race_name: string>"
    get-universe-groups: "list<int>"
    get-universe-groups-group-id: "record<category_id: int, group_id: int, name: string, published: bool, types: list<int>>"
    post-universe-ids: "record<agents: table<id: int, name: string>, alliances: table<id: int, name: string>, characters: table<id: int, name: string>, constellations: table<id: int, name: string>, corporations: table<id: int, name: string>, factions: table<id: int, name: string>, inventory_types: table<id: int, name: string>, regions: table<id: int, name: string>, stations: table<id: int, name: string>, systems: table<id: int, name: string>>"
    get-universe-moons-moon-id: "record<moon_id: int, name: string, position: record<x: float, y: float, z: float>, system_id: int>"
    post-universe-names: "table<category: string, id: int, name: string>"
    get-universe-planets-planet-id: "record<name: string, planet_id: int, position: record<x: float, y: float, z: float>, system_id: int, type_id: int>"
    get-universe-races: "table<alliance_id: int, description: string, name: string, race_id: int>"
    get-universe-regions: "list<int>"
    get-universe-regions-region-id: "record<constellations: list<int>, description: string, name: string, region_id: int>"
    get-universe-schematics-schematic-id: "record<cycle_time: int, schematic_name: string>"
    get-universe-stargates-stargate-id: "record<destination: record<stargate_id: int, system_id: int>, name: string, position: record<x: float, y: float, z: float>, stargate_id: int, system_id: int, type_id: int>"
    get-universe-stars-star-id: "record<age: int, luminosity: float, name: string, radius: int, solar_system_id: int, spectral_class: string, temperature: int, type_id: int>"
    get-universe-stations-station-id: "record<max_dockable_ship_volume: float, name: string, office_rental_cost: float, owner: int, position: record<x: float, y: float, z: float>, race_id: int, reprocessing_efficiency: float, reprocessing_stations_take: float, services: list<string>, station_id: int, system_id: int, type_id: int>"
    get-universe-structures: "list<int>"
    get-universe-structures-structure-id: "record<name: string, owner_id: int, position: record<x: float, y: float, z: float>, solar_system_id: int, type_id: int>"
    get-universe-system-jumps: "table<ship_jumps: int, system_id: int>"
    get-universe-system-kills: "table<npc_kills: int, pod_kills: int, ship_kills: int, system_id: int>"
    get-universe-systems: "list<int>"
    get-universe-systems-system-id: "record<constellation_id: int, name: string, planets: table<asteroid_belts: list, moons: list, planet_id: int>, position: record<x: float, y: float, z: float>, security_class: string, security_status: float, star_id: int, stargates: list<int>, stations: list<int>, system_id: int>"
    get-universe-types: "list<int>"
    get-universe-types-type-id: "record<capacity: float, description: string, dogma_attributes: table<attribute_id: int, value: float>, dogma_effects: table<effect_id: int, is_default: bool>, graphic_id: int, group_id: int, icon_id: int, market_group_id: int, mass: float, name: string, packaged_volume: float, portion_size: int, published: bool, radius: float, type_id: int, volume: float>"
    get-wars: "list<int>"
    get-wars-war-id: "record<aggressor: record<alliance_id: int, corporation_id: int, isk_destroyed: float, ships_killed: int>, allies: table<alliance_id: int, corporation_id: int>, declared: string, defender: record<alliance_id: int, corporation_id: int, isk_destroyed: float, ships_killed: int>, finished: string, id: int, mutual: bool, open_for_allies: bool, retracted: string, started: string>"
    get-wars-war-id-killmails: "table<killmail_hash: string, killmail_id: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-alliances" "get-alliances-alliance-id" "get-alliances-alliance-id-contacts" "get-alliances-alliance-id-contacts-labels" "get-alliances-alliance-id-corporations" "get-alliances-alliance-id-icons" "post-characters-affiliation" "get-characters-character-id" "get-characters-character-id-agents-research" "get-characters-character-id-assets" "post-characters-character-id-assets-locations" "post-characters-character-id-assets-names" "get-characters-character-id-attributes" "get-characters-character-id-blueprints" "get-characters-character-id-bookmarks" "get-characters-character-id-bookmarks-folders" "get-characters-character-id-calendar" "get-characters-character-id-calendar-event-id" "put-characters-character-id-calendar-event-id" "get-characters-character-id-calendar-event-id-attendees" "get-characters-character-id-clones" "delete-characters-character-id-contacts" "get-characters-character-id-contacts" "post-characters-character-id-contacts" "put-characters-character-id-contacts" "get-characters-character-id-contacts-labels" "get-characters-character-id-contracts" "get-characters-character-id-contracts-contract-id-bids" "get-characters-character-id-contracts-contract-id-items" "get-characters-character-id-corporationhistory" "post-characters-character-id-cspa" "get-characters-character-id-fatigue" "get-characters-character-id-fittings" "post-characters-character-id-fittings" "delete-characters-character-id-fittings-fitting-id" "get-characters-character-id-fleet" "get-characters-character-id-fw-stats" "get-characters-character-id-implants" "get-characters-character-id-industry-jobs" "get-characters-character-id-killmails-recent" "get-characters-character-id-location" "get-characters-character-id-loyalty-points" "get-characters-character-id-mail" "post-characters-character-id-mail" "get-characters-character-id-mail-labels" "post-characters-character-id-mail-labels" "delete-characters-character-id-mail-labels-label-id" "get-characters-character-id-mail-lists" "delete-characters-character-id-mail-mail-id" "get-characters-character-id-mail-mail-id" "put-characters-character-id-mail-mail-id" "get-characters-character-id-medals" "get-characters-character-id-mining" "get-characters-character-id-notifications" "get-characters-character-id-notifications-contacts" "get-characters-character-id-online" "get-characters-character-id-opportunities" "get-characters-character-id-orders" "get-characters-character-id-orders-history" "get-characters-character-id-planets" "get-characters-character-id-planets-planet-id" "get-characters-character-id-portrait" "get-characters-character-id-roles" "get-characters-character-id-search" "get-characters-character-id-ship" "get-characters-character-id-skillqueue" "get-characters-character-id-skills" "get-characters-character-id-standings" "get-characters-character-id-stats" "get-characters-character-id-titles" "get-characters-character-id-wallet" "get-characters-character-id-wallet-journal" "get-characters-character-id-wallet-transactions" "get-contracts-public-bids-contract-id" "get-contracts-public-items-contract-id" "get-contracts-public-region-id" "get-corporation-corporation-id-mining-extractions" "get-corporation-corporation-id-mining-observers" "get-corporation-corporation-id-mining-observers-observer-id" "get-corporations-npccorps" "get-corporations-corporation-id" "get-corporations-corporation-id-alliancehistory" "get-corporations-corporation-id-assets" "post-corporations-corporation-id-assets-locations" "post-corporations-corporation-id-assets-names" "get-corporations-corporation-id-blueprints" "get-corporations-corporation-id-bookmarks" "get-corporations-corporation-id-bookmarks-folders" "get-corporations-corporation-id-contacts" "get-corporations-corporation-id-contacts-labels" "get-corporations-corporation-id-containers-logs" "get-corporations-corporation-id-contracts" "get-corporations-corporation-id-contracts-contract-id-bids" "get-corporations-corporation-id-contracts-contract-id-items" "get-corporations-corporation-id-customs-offices" "get-corporations-corporation-id-divisions" "get-corporations-corporation-id-facilities" "get-corporations-corporation-id-fw-stats" "get-corporations-corporation-id-icons" "get-corporations-corporation-id-industry-jobs" "get-corporations-corporation-id-killmails-recent" "get-corporations-corporation-id-medals" "get-corporations-corporation-id-medals-issued" "get-corporations-corporation-id-members" "get-corporations-corporation-id-members-limit" "get-corporations-corporation-id-members-titles" "get-corporations-corporation-id-membertracking" "get-corporations-corporation-id-orders" "get-corporations-corporation-id-orders-history" "get-corporations-corporation-id-roles" "get-corporations-corporation-id-roles-history" "get-corporations-corporation-id-shareholders" "get-corporations-corporation-id-standings" "get-corporations-corporation-id-starbases" "get-corporations-corporation-id-starbases-starbase-id" "get-corporations-corporation-id-structures" "get-corporations-corporation-id-titles" "get-corporations-corporation-id-wallets" "get-corporations-corporation-id-wallets-division-journal" "get-corporations-corporation-id-wallets-division-transactions" "get-dogma-attributes" "get-dogma-attributes-attribute-id" "get-dogma-dynamic-items-type-id-item-id" "get-dogma-effects" "get-dogma-effects-effect-id" "get-fleets-fleet-id" "put-fleets-fleet-id" "get-fleets-fleet-id-members" "post-fleets-fleet-id-members" "delete-fleets-fleet-id-members-member-id" "put-fleets-fleet-id-members-member-id" "delete-fleets-fleet-id-squads-squad-id" "put-fleets-fleet-id-squads-squad-id" "get-fleets-fleet-id-wings" "post-fleets-fleet-id-wings" "delete-fleets-fleet-id-wings-wing-id" "put-fleets-fleet-id-wings-wing-id" "post-fleets-fleet-id-wings-wing-id-squads" "get-fw-leaderboards" "get-fw-leaderboards-characters" "get-fw-leaderboards-corporations" "get-fw-stats" "get-fw-systems" "get-fw-wars" "get-incursions" "get-industry-facilities" "get-industry-systems" "get-insurance-prices" "get-killmails-killmail-id-killmail-hash" "get-loyalty-stores-corporation-id-offers" "get-markets-groups" "get-markets-groups-market-group-id" "get-markets-prices" "get-markets-structures-structure-id" "get-markets-region-id-history" "get-markets-region-id-orders" "get-markets-region-id-types" "get-opportunities-groups" "get-opportunities-groups-group-id" "get-opportunities-tasks" "get-opportunities-tasks-task-id" "get-route-origin-destination" "get-search" "get-sovereignty-campaigns" "get-sovereignty-map" "get-sovereignty-structures" "get-status" "post-ui-autopilot-waypoint" "post-ui-openwindow-contract" "post-ui-openwindow-information" "post-ui-openwindow-marketdetails" "post-ui-openwindow-newmail" "get-universe-ancestries" "get-universe-asteroid-belts-asteroid-belt-id" "get-universe-bloodlines" "get-universe-categories" "get-universe-categories-category-id" "get-universe-constellations" "get-universe-constellations-constellation-id" "get-universe-factions" "get-universe-graphics" "get-universe-graphics-graphic-id" "get-universe-groups" "get-universe-groups-group-id" "post-universe-ids" "get-universe-moons-moon-id" "post-universe-names" "get-universe-planets-planet-id" "get-universe-races" "get-universe-regions" "get-universe-regions-region-id" "get-universe-schematics-schematic-id" "get-universe-stargates-stargate-id" "get-universe-stars-star-id" "get-universe-stations-station-id" "get-universe-structures" "get-universe-structures-structure-id" "get-universe-system-jumps" "get-universe-system-kills" "get-universe-systems" "get-universe-systems-system-id" "get-universe-types" "get-universe-types-type-id" "get-wars" "get-wars-war-id" "get-wars-war-id-killmails" "commands"] | sort) } | get name | first)
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

# List all alliances
#
# GET /alliances/
# Returns: list<int>
# operationId: get_alliances
export def "get-alliances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/alliances/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get alliance information
#
# GET /alliances/{alliance_id}/
# Returns: record<creator_corporation_id: int, creator_id: int, date_founded: string, executor_corporation_id: int, faction_id: int, name: string, ticker: string>
# operationId: get_alliances_alliance_id
export def "get-alliances-alliance-id" [
  alliance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/alliances/{alliance_id}/"
    path_params: [{name: alliance_id, var: alliance_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    alliance_id: $alliance_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get alliance contacts
#
# GET /alliances/{alliance_id}/contacts/
# Returns: table<contact_id: int, contact_type: string, label_ids: list<int>, standing: float>
# operationId: get_alliances_alliance_id_contacts
export def "get-alliances-alliance-id-contacts" [
  alliance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/alliances/{alliance_id}/contacts/"
    path_params: [{name: alliance_id, var: alliance_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    alliance_id: $alliance_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get alliance contact labels
#
# GET /alliances/{alliance_id}/contacts/labels/
# Returns: table<label_id: int, label_name: string>
# operationId: get_alliances_alliance_id_contacts_labels
export def "get-alliances-alliance-id-contacts-labels" [
  alliance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/alliances/{alliance_id}/contacts/labels/"
    path_params: [{name: alliance_id, var: alliance_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    alliance_id: $alliance_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List alliance's corporations
#
# GET /alliances/{alliance_id}/corporations/
# Returns: list<int>
# operationId: get_alliances_alliance_id_corporations
export def "get-alliances-alliance-id-corporations" [
  alliance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/alliances/{alliance_id}/corporations/"
    path_params: [{name: alliance_id, var: alliance_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    alliance_id: $alliance_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get alliance icon
#
# GET /alliances/{alliance_id}/icons/
# Returns: record<px128x128: string, px64x64: string>
# operationId: get_alliances_alliance_id_icons
export def "get-alliances-alliance-id-icons" [
  alliance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/alliances/{alliance_id}/icons/"
    path_params: [{name: alliance_id, var: alliance_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    alliance_id: $alliance_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Character affiliation
#
# POST /characters/affiliation/
# Returns: table<alliance_id: int, character_id: int, corporation_id: int, faction_id: int>
# operationId: post_characters_affiliation
export def "post-characters-affiliation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/characters/affiliation/"
    query: [{name: datasource, var: datasource}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    datasource: $datasource, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get character's public information
#
# GET /characters/{character_id}/
# Returns: record<alliance_id: int, ancestry_id: int, birthday: string, bloodline_id: int, corporation_id: int, description: string, faction_id: int, gender: string, name: string, race_id: int, security_status: float>
# operationId: get_characters_character_id
export def "get-characters-character-id" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get agents research
#
# GET /characters/{character_id}/agents_research/
# Returns: table<agent_id: int, points_per_day: float, remainder_points: float, skill_type_id: int, started_at: string>
# operationId: get_characters_character_id_agents_research
export def "get-characters-character-id-agents-research" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/agents_research/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get character assets
#
# GET /characters/{character_id}/assets/
# Returns: table<is_blueprint_copy: bool, is_singleton: bool, item_id: int, location_flag: string, location_id: int, location_type: string, quantity: int, type_id: int>
# operationId: get_characters_character_id_assets
export def "get-characters-character-id-assets" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/assets/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get character asset locations
#
# POST /characters/{character_id}/assets/locations/
# Returns: table<item_id: int, position: record<x: float, y: float, z: float>>
# operationId: post_characters_character_id_assets_locations
export def "post-characters-character-id-assets-locations" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/characters/{character_id}/assets/locations/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get character asset names
#
# POST /characters/{character_id}/assets/names/
# Returns: table<item_id: int, name: string>
# operationId: post_characters_character_id_assets_names
export def "post-characters-character-id-assets-names" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/characters/{character_id}/assets/names/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get character attributes
#
# GET /characters/{character_id}/attributes/
# Returns: record<accrued_remap_cooldown_date: string, bonus_remaps: int, charisma: int, intelligence: int, last_remap_date: string, memory: int, perception: int, willpower: int>
# operationId: get_characters_character_id_attributes
export def "get-characters-character-id-attributes" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/attributes/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get blueprints
#
# GET /characters/{character_id}/blueprints/
# Returns: table<item_id: int, location_flag: string, location_id: int, material_efficiency: int, quantity: int, runs: int, time_efficiency: int, type_id: int>
# operationId: get_characters_character_id_blueprints
export def "get-characters-character-id-blueprints" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/blueprints/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List bookmarks
#
# GET /characters/{character_id}/bookmarks/
# Returns: table<bookmark_id: int, coordinates: record<x: float, y: float, z: float>, created: string, creator_id: int, folder_id: int, item: record<item_id: int, type_id: int>, label: string, location_id: int, notes: string>
# operationId: get_characters_character_id_bookmarks
export def "get-characters-character-id-bookmarks" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/bookmarks/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List bookmark folders
#
# GET /characters/{character_id}/bookmarks/folders/
# Returns: table<folder_id: int, name: string>
# operationId: get_characters_character_id_bookmarks_folders
export def "get-characters-character-id-bookmarks-folders" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/bookmarks/folders/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List calendar event summaries
#
# GET /characters/{character_id}/calendar/
# Returns: table<event_date: string, event_id: int, event_response: string, importance: int, title: string>
# operationId: get_characters_character_id_calendar
export def "get-characters-character-id-calendar" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --from-event: int # The event ID to retrieve events from (format: int32)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/calendar/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: from_event, var: from_event}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, from_event: $from_event, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an event
#
# GET /characters/{character_id}/calendar/{event_id}/
# Returns: record<date: string, duration: int, event_id: int, importance: int, owner_id: int, owner_name: string, owner_type: string, response: string, text: string, title: string>
# operationId: get_characters_character_id_calendar_event_id
export def "get-characters-character-id-calendar-event-id" [
  character_id: int
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/calendar/{event_id}/"
    path_params: [{name: character_id, var: character_id}, {name: event_id, var: event_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, event_id: $event_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Respond to an event
#
# PUT /characters/{character_id}/calendar/{event_id}/
# operationId: put_characters_character_id_calendar_event_id
export def "put-characters-character-id-calendar-event-id" [
  character_id: int
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  response: string@response-completer # response string
]: any -> any {
  $in | http-request {
    method: put
    path: "/characters/{character_id}/calendar/{event_id}/"
    path_params: [{name: character_id, var: character_id}, {name: event_id, var: event_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: response, var: response}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    character_id: $character_id, event_id: $event_id, datasource: $datasource, qp_token: $qp_token, response: $response
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attendees
#
# GET /characters/{character_id}/calendar/{event_id}/attendees/
# Returns: table<character_id: int, event_response: string>
# operationId: get_characters_character_id_calendar_event_id_attendees
export def "get-characters-character-id-calendar-event-id-attendees" [
  character_id: int
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/calendar/{event_id}/attendees/"
    path_params: [{name: character_id, var: character_id}, {name: event_id, var: event_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, event_id: $event_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get clones
#
# GET /characters/{character_id}/clones/
# Returns: record<home_location: record<location_id: int, location_type: string>, jump_clones: table<implants: list, jump_clone_id: int, location_id: int, location_type: string, name: string>, last_clone_jump_date: string, last_station_change_date: string>
# operationId: get_characters_character_id_clones
export def "get-characters-character-id-clones" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/clones/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete contacts
#
# DELETE /characters/{character_id}/contacts/
# operationId: delete_characters_character_id_contacts
export def "delete-characters-character-id-contacts" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-ids: list<int> # A list of contacts to delete (required)
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/characters/{character_id}/contacts/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: contact_ids, var: contact_ids, style: csv, required: true}, {name: datasource, var: datasource}, {name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    character_id: $character_id, contact_ids: $contact_ids, datasource: $datasource, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get contacts
#
# GET /characters/{character_id}/contacts/
# Returns: table<contact_id: int, contact_type: string, is_blocked: bool, is_watched: bool, label_ids: list<int>, standing: float>
# operationId: get_characters_character_id_contacts
export def "get-characters-character-id-contacts" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/contacts/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add contacts
#
# POST /characters/{character_id}/contacts/
# Returns: list<int>
# operationId: post_characters_character_id_contacts
export def "post-characters-character-id-contacts" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --label-ids: list<int> # Add custom labels to the new contact
  --standing: float # Standing for the contact (required, format: float)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --watched: oneof<nothing, bool> # Whether the contact should be watched, note this is only effective on characters (default: false)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/characters/{character_id}/contacts/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: label_ids, var: label_ids, style: csv}, {name: standing, var: standing, required: true}, {name: token, var: qp_token}, {name: watched, var: watched}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, label_ids: $label_ids, standing: $standing, qp_token: $qp_token, watched: $watched, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit contacts
#
# PUT /characters/{character_id}/contacts/
# operationId: put_characters_character_id_contacts
export def "put-characters-character-id-contacts" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --label-ids: list<int> # Add custom labels to the contact
  --standing: float # Standing for the contact (required, format: float)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --watched: oneof<nothing, bool> # Whether the contact should be watched, note this is only effective on characters (default: false)
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/characters/{character_id}/contacts/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: label_ids, var: label_ids, style: csv}, {name: standing, var: standing, required: true}, {name: token, var: qp_token}, {name: watched, var: watched}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, label_ids: $label_ids, standing: $standing, qp_token: $qp_token, watched: $watched, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get contact labels
#
# GET /characters/{character_id}/contacts/labels/
# Returns: table<label_id: int, label_name: string>
# operationId: get_characters_character_id_contacts_labels
export def "get-characters-character-id-contacts-labels" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/contacts/labels/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get contracts
#
# GET /characters/{character_id}/contracts/
# Returns: table<acceptor_id: int, assignee_id: int, availability: string, buyout: float, collateral: float, contract_id: int, date_accepted: string, date_completed: string, date_expired: string, date_issued: string, days_to_complete: int, end_location_id: int, for_corporation: bool, issuer_corporation_id: int, issuer_id: int, price: float, reward: float, start_location_id: int, status: string, title: string, type: string, volume: float>
# operationId: get_characters_character_id_contracts
export def "get-characters-character-id-contracts" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/contracts/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get contract bids
#
# GET /characters/{character_id}/contracts/{contract_id}/bids/
# Returns: table<amount: float, bid_id: int, bidder_id: int, date_bid: string>
# operationId: get_characters_character_id_contracts_contract_id_bids
export def "get-characters-character-id-contracts-contract-id-bids" [
  character_id: int
  contract_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/contracts/{contract_id}/bids/"
    path_params: [{name: character_id, var: character_id}, {name: contract_id, var: contract_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, contract_id: $contract_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get contract items
#
# GET /characters/{character_id}/contracts/{contract_id}/items/
# Returns: table<is_included: bool, is_singleton: bool, quantity: int, raw_quantity: int, record_id: int, type_id: int>
# operationId: get_characters_character_id_contracts_contract_id_items
export def "get-characters-character-id-contracts-contract-id-items" [
  character_id: int
  contract_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/contracts/{contract_id}/items/"
    path_params: [{name: character_id, var: character_id}, {name: contract_id, var: contract_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, contract_id: $contract_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation history
#
# GET /characters/{character_id}/corporationhistory/
# Returns: table<corporation_id: int, is_deleted: bool, record_id: int, start_date: string>
# operationId: get_characters_character_id_corporationhistory
export def "get-characters-character-id-corporationhistory" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/corporationhistory/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate a CSPA charge cost
#
# POST /characters/{character_id}/cspa/
# Returns: float
# operationId: post_characters_character_id_cspa
export def "post-characters-character-id-cspa" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/characters/{character_id}/cspa/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get jump fatigue
#
# GET /characters/{character_id}/fatigue/
# Returns: record<jump_fatigue_expire_date: string, last_jump_date: string, last_update_date: string>
# operationId: get_characters_character_id_fatigue
export def "get-characters-character-id-fatigue" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/fatigue/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get fittings
#
# GET /characters/{character_id}/fittings/
# Returns: table<description: string, fitting_id: int, items: list<record>, name: string, ship_type_id: int>
# operationId: get_characters_character_id_fittings
export def "get-characters-character-id-fittings" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/fittings/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create fitting
#
# POST /characters/{character_id}/fittings/
# Returns: record<fitting_id: int>
# operationId: post_characters_character_id_fittings
export def "post-characters-character-id-fittings" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  description: string # description string
  items: list # items array — item shape: {flag: int, quantity: int, type_id: int}
  name: string # name string
  ship_type_id: int # ship_type_id integer (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/characters/{character_id}/fittings/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: items, var: items}, {name: name, var: name}, {name: ship_type_id, var: ship_type_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, description: $description, items: $items, name: $name, ship_type_id: $ship_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete fitting
#
# DELETE /characters/{character_id}/fittings/{fitting_id}/
# operationId: delete_characters_character_id_fittings_fitting_id
export def "delete-characters-character-id-fittings-fitting-id" [
  character_id: int
  fitting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/characters/{character_id}/fittings/{fitting_id}/"
    path_params: [{name: character_id, var: character_id}, {name: fitting_id, var: fitting_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    character_id: $character_id, fitting_id: $fitting_id, datasource: $datasource, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get character fleet info
#
# GET /characters/{character_id}/fleet/
# Returns: record<fleet_id: int, role: string, squad_id: int, wing_id: int>
# operationId: get_characters_character_id_fleet
export def "get-characters-character-id-fleet" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/fleet/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Overview of a character involved in faction warfare
#
# GET /characters/{character_id}/fw/stats/
# Returns: record<current_rank: int, enlisted_on: string, faction_id: int, highest_rank: int, kills: record<last_week: int, total: int, yesterday: int>, victory_points: record<last_week: int, total: int, yesterday: int>>
# operationId: get_characters_character_id_fw_stats
export def "get-characters-character-id-fw-stats" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/fw/stats/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get active implants
#
# GET /characters/{character_id}/implants/
# Returns: list<int>
# operationId: get_characters_character_id_implants
export def "get-characters-character-id-implants" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/implants/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List character industry jobs
#
# GET /characters/{character_id}/industry/jobs/
# Returns: table<activity_id: int, blueprint_id: int, blueprint_location_id: int, blueprint_type_id: int, completed_character_id: int, completed_date: string, cost: float, duration: int, end_date: string, facility_id: int, installer_id: int, job_id: int, licensed_runs: int, output_location_id: int, pause_date: string, probability: float, product_type_id: int, runs: int, start_date: string, station_id: int, status: string, successful_runs: int>
# operationId: get_characters_character_id_industry_jobs
export def "get-characters-character-id-industry-jobs" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --include-completed: oneof<nothing, bool> # Whether to retrieve completed character industry jobs. Only includes jobs from the past 90 days
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/industry/jobs/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: include_completed, var: include_completed}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, include_completed: $include_completed, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a character's recent kills and losses
#
# GET /characters/{character_id}/killmails/recent/
# Returns: table<killmail_hash: string, killmail_id: int>
# operationId: get_characters_character_id_killmails_recent
export def "get-characters-character-id-killmails-recent" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/killmails/recent/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get character location
#
# GET /characters/{character_id}/location/
# Returns: record<solar_system_id: int, station_id: int, structure_id: int>
# operationId: get_characters_character_id_location
export def "get-characters-character-id-location" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/location/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get loyalty points
#
# GET /characters/{character_id}/loyalty/points/
# Returns: table<corporation_id: int, loyalty_points: int>
# operationId: get_characters_character_id_loyalty_points
export def "get-characters-character-id-loyalty-points" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/loyalty/points/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return mail headers
#
# GET /characters/{character_id}/mail/
# Returns: table<from: int, is_read: bool, labels: list<int>, mail_id: int, recipients: list<record>, subject: string, timestamp: string>
# operationId: get_characters_character_id_mail
export def "get-characters-character-id-mail" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --labels: list<int> # Fetch only mails that match one or more of the given labels
  --last-mail-id: int # List only mail with an ID lower than the given ID, if present (format: int32)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/mail/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: labels, var: labels, style: csv}, {name: last_mail_id, var: last_mail_id}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, labels: $labels, last_mail_id: $last_mail_id, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a new mail
#
# POST /characters/{character_id}/mail/
# Returns: int
# operationId: post_characters_character_id_mail
export def "post-characters-character-id-mail" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --approved-cost: int # approved_cost integer (format: int64, default: 0)
  body: string # body string
  recipients: list # recipients array — item shape: {recipient_id: int, recipient_type: "alliance"|"character"|"corporation"|"mailing_list"}
  subject: string # subject string
]: any -> any {
  $in | http-request {
    method: post
    path: "/characters/{character_id}/mail/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: approved_cost, var: approved_cost}, {name: body, var: body}, {name: recipients, var: recipients}, {name: subject, var: subject}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, approved_cost: $approved_cost, body: $body, recipients: $recipients, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get mail labels and unread counts
#
# GET /characters/{character_id}/mail/labels/
# Returns: record<labels: table<color: string, label_id: int, name: string, unread_count: int>, total_unread_count: int>
# operationId: get_characters_character_id_mail_labels
export def "get-characters-character-id-mail-labels" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/mail/labels/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a mail label
#
# POST /characters/{character_id}/mail/labels/
# Returns: int
# operationId: post_characters_character_id_mail_labels
export def "post-characters-character-id-mail-labels" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --color: string@color-completer # Hexadecimal string representing label color, in RGB format (default: #ffffff)
  name: string # name string
]: any -> any {
  $in | http-request {
    method: post
    path: "/characters/{character_id}/mail/labels/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: color, var: color}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, color: $color, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a mail label
#
# DELETE /characters/{character_id}/mail/labels/{label_id}/
# operationId: delete_characters_character_id_mail_labels_label_id
export def "delete-characters-character-id-mail-labels-label-id" [
  character_id: int
  label_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/characters/{character_id}/mail/labels/{label_id}/"
    path_params: [{name: character_id, var: character_id}, {name: label_id, var: label_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    character_id: $character_id, label_id: $label_id, datasource: $datasource, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return mailing list subscriptions
#
# GET /characters/{character_id}/mail/lists/
# Returns: table<mailing_list_id: int, name: string>
# operationId: get_characters_character_id_mail_lists
export def "get-characters-character-id-mail-lists" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/mail/lists/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a mail
#
# DELETE /characters/{character_id}/mail/{mail_id}/
# operationId: delete_characters_character_id_mail_mail_id
export def "delete-characters-character-id-mail-mail-id" [
  character_id: int
  mail_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/characters/{character_id}/mail/{mail_id}/"
    path_params: [{name: character_id, var: character_id}, {name: mail_id, var: mail_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    character_id: $character_id, mail_id: $mail_id, datasource: $datasource, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a mail
#
# GET /characters/{character_id}/mail/{mail_id}/
# Returns: record<body: string, from: int, labels: list<int>, read: bool, recipients: table<recipient_id: int, recipient_type: string>, subject: string, timestamp: string>
# operationId: get_characters_character_id_mail_mail_id
export def "get-characters-character-id-mail-mail-id" [
  character_id: int
  mail_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/mail/{mail_id}/"
    path_params: [{name: character_id, var: character_id}, {name: mail_id, var: mail_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, mail_id: $mail_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update metadata about a mail
#
# PUT /characters/{character_id}/mail/{mail_id}/
# operationId: put_characters_character_id_mail_mail_id
export def "put-characters-character-id-mail-mail-id" [
  character_id: int
  mail_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --labels: list<int> # Labels to assign to the mail. Pre-existing labels are unassigned.
  --read: oneof<nothing, bool> # Whether the mail is flagged as read
]: any -> any {
  $in | http-request {
    method: put
    path: "/characters/{character_id}/mail/{mail_id}/"
    path_params: [{name: character_id, var: character_id}, {name: mail_id, var: mail_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}, {name: read, var: read}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    character_id: $character_id, mail_id: $mail_id, datasource: $datasource, qp_token: $qp_token, labels: $labels, read: $read
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get medals
#
# GET /characters/{character_id}/medals/
# Returns: table<corporation_id: int, date: string, description: string, graphics: list<record>, issuer_id: int, medal_id: int, reason: string, status: string, title: string>
# operationId: get_characters_character_id_medals
export def "get-characters-character-id-medals" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/medals/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Character mining ledger
#
# GET /characters/{character_id}/mining/
# Returns: table<date: string, quantity: int, solar_system_id: int, type_id: int>
# operationId: get_characters_character_id_mining
export def "get-characters-character-id-mining" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/mining/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get character notifications
#
# GET /characters/{character_id}/notifications/
# Returns: table<is_read: bool, notification_id: int, sender_id: int, sender_type: string, text: string, timestamp: string, type: string>
# operationId: get_characters_character_id_notifications
export def "get-characters-character-id-notifications" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/notifications/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get new contact notifications
#
# GET /characters/{character_id}/notifications/contacts/
# Returns: table<message: string, notification_id: int, send_date: string, sender_character_id: int, standing_level: float>
# operationId: get_characters_character_id_notifications_contacts
export def "get-characters-character-id-notifications-contacts" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/notifications/contacts/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get character online
#
# GET /characters/{character_id}/online/
# Returns: record<last_login: string, last_logout: string, logins: int, online: bool>
# operationId: get_characters_character_id_online
export def "get-characters-character-id-online" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/online/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a character's completed tasks
#
# GET /characters/{character_id}/opportunities/
# Returns: table<completed_at: string, task_id: int>
# operationId: get_characters_character_id_opportunities
export def "get-characters-character-id-opportunities" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/opportunities/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List open orders from a character
#
# GET /characters/{character_id}/orders/
# Returns: table<duration: int, escrow: float, is_buy_order: bool, is_corporation: bool, issued: string, location_id: int, min_volume: int, order_id: int, price: float, range: string, region_id: int, type_id: int, volume_remain: int, volume_total: int>
# operationId: get_characters_character_id_orders
export def "get-characters-character-id-orders" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/orders/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List historical orders by a character
#
# GET /characters/{character_id}/orders/history/
# Returns: table<duration: int, escrow: float, is_buy_order: bool, is_corporation: bool, issued: string, location_id: int, min_volume: int, order_id: int, price: float, range: string, region_id: int, state: string, type_id: int, volume_remain: int, volume_total: int>
# operationId: get_characters_character_id_orders_history
export def "get-characters-character-id-orders-history" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/orders/history/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get colonies
#
# GET /characters/{character_id}/planets/
# Returns: table<last_update: string, num_pins: int, owner_id: int, planet_id: int, planet_type: string, solar_system_id: int, upgrade_level: int>
# operationId: get_characters_character_id_planets
export def "get-characters-character-id-planets" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/planets/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get colony layout
#
# GET /characters/{character_id}/planets/{planet_id}/
# Returns: record<links: table<destination_pin_id: int, link_level: int, source_pin_id: int>, pins: table<contents: list, expiry_time: string, extractor_details: record, factory_details: record, install_time: string, last_cycle_start: string, latitude: float, longitude: float, pin_id: int, schematic_id: int, type_id: int>, routes: table<content_type_id: int, destination_pin_id: int, quantity: float, route_id: int, source_pin_id: int, waypoints: list>>
# operationId: get_characters_character_id_planets_planet_id
export def "get-characters-character-id-planets-planet-id" [
  character_id: int
  planet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/planets/{planet_id}/"
    path_params: [{name: character_id, var: character_id}, {name: planet_id, var: planet_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, planet_id: $planet_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get character portraits
#
# GET /characters/{character_id}/portrait/
# Returns: record<px128x128: string, px256x256: string, px512x512: string, px64x64: string>
# operationId: get_characters_character_id_portrait
export def "get-characters-character-id-portrait" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/portrait/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get character corporation roles
#
# GET /characters/{character_id}/roles/
# Returns: record<roles: list<string>, roles_at_base: list<string>, roles_at_hq: list<string>, roles_at_other: list<string>>
# operationId: get_characters_character_id_roles
export def "get-characters-character-id-roles" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/roles/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search on a string
#
# GET /characters/{character_id}/search/
# Returns: record<agent: list<int>, alliance: list<int>, character: list<int>, constellation: list<int>, corporation: list<int>, faction: list<int>, inventory_type: list<int>, region: list<int>, solar_system: list<int>, station: list<int>, structure: list<int>>
# operationId: get_characters_character_id_search
export def "get-characters-character-id-search" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list<string> # Type of entities to search for (required)
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --search: string # The string to search on (required)
  --strict: oneof<nothing, bool> # Whether the search should be a strict match (default: false)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/search/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: categories, var: categories, style: csv, required: true}, {name: datasource, var: datasource}, {name: language, var: language}, {name: search, var: search, required: true}, {name: strict, var: strict}, {name: token, var: qp_token}]
    header: [{name: Accept-Language, var: accept_language}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, categories: $categories, datasource: $datasource, language: $language, search: $search, strict: $strict, qp_token: $qp_token, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get current ship
#
# GET /characters/{character_id}/ship/
# Returns: record<ship_item_id: int, ship_name: string, ship_type_id: int>
# operationId: get_characters_character_id_ship
export def "get-characters-character-id-ship" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/ship/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get character's skill queue
#
# GET /characters/{character_id}/skillqueue/
# Returns: table<finish_date: string, finished_level: int, level_end_sp: int, level_start_sp: int, queue_position: int, skill_id: int, start_date: string, training_start_sp: int>
# operationId: get_characters_character_id_skillqueue
export def "get-characters-character-id-skillqueue" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/skillqueue/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get character skills
#
# GET /characters/{character_id}/skills/
# Returns: record<skills: table<active_skill_level: int, skill_id: int, skillpoints_in_skill: int, trained_skill_level: int>, total_sp: int, unallocated_sp: int>
# operationId: get_characters_character_id_skills
export def "get-characters-character-id-skills" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/skills/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get standings
#
# GET /characters/{character_id}/standings/
# Returns: table<from_id: int, from_type: string, standing: float>
# operationId: get_characters_character_id_standings
export def "get-characters-character-id-standings" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/standings/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Yearly aggregate stats
#
# GET /characters/{character_id}/stats/
# Returns: table<character: record<days_of_activity: int, minutes: int, sessions_started: int>, combat: record<cap_drainedby_npc: int, cap_drainedby_pc: int, cap_draining_pc: int, criminal_flag_set: int, damage_from_np_cs_amount: int, damage_from_np_cs_num_shots: int, damage_from_players_bomb_amount: int, damage_from_players_bomb_num_shots: int, damage_from_players_combat_drone_amount: int, damage_from_players_combat_drone_num_shots: int, damage_from_players_energy_amount: int, damage_from_players_energy_num_shots: int, damage_from_players_fighter_bomber_amount: int, damage_from_players_fighter_bomber_num_shots: int, damage_from_players_fighter_drone_amount: int, damage_from_players_fighter_drone_num_shots: int, damage_from_players_hybrid_amount: int, damage_from_players_hybrid_num_shots: int, damage_from_players_missile_amount: int, damage_from_players_missile_num_shots: int, damage_from_players_projectile_amount: int, damage_from_players_projectile_num_shots: int, damage_from_players_smart_bomb_amount: int, damage_from_players_smart_bomb_num_shots: int, damage_from_players_super_amount: int, damage_from_players_super_num_shots: int, damage_from_structures_total_amount: int, damage_from_structures_total_num_shots: int, damage_to_players_bomb_amount: int, damage_to_players_bomb_num_shots: int, damage_to_players_combat_drone_amount: int, damage_to_players_combat_drone_num_shots: int, damage_to_players_energy_amount: int, damage_to_players_energy_num_shots: int, damage_to_players_fighter_bomber_amount: int, damage_to_players_fighter_bomber_num_shots: int, damage_to_players_fighter_drone_amount: int, damage_to_players_fighter_drone_num_shots: int, damage_to_players_hybrid_amount: int, damage_to_players_hybrid_num_shots: int, damage_to_players_missile_amount: int, damage_to_players_missile_num_shots: int, damage_to_players_projectile_amount: int, damage_to_players_projectile_num_shots: int, damage_to_players_smart_bomb_amount: int, damage_to_players_smart_bomb_num_shots: int, damage_to_players_super_amount: int, damage_to_players_super_num_shots: int, damage_to_structures_total_amount: int, damage_to_structures_total_num_shots: int, deaths_high_sec: int, deaths_low_sec: int, deaths_null_sec: int, deaths_pod_high_sec: int, deaths_pod_low_sec: int, deaths_pod_null_sec: int, deaths_pod_wormhole: int, deaths_wormhole: int, drone_engage: int, dscans: int, duel_requested: int, engagement_register: int, kills_assists: int, kills_high_sec: int, kills_low_sec: int, kills_null_sec: int, kills_pod_high_sec: int, kills_pod_low_sec: int, kills_pod_null_sec: int, kills_pod_wormhole: int, kills_wormhole: int, npc_flag_set: int, probe_scans: int, pvp_flag_set: int, repair_armor_by_remote_amount: int, repair_armor_remote_amount: int, repair_armor_self_amount: int, repair_capacitor_by_remote_amount: int, repair_capacitor_remote_amount: int, repair_capacitor_self_amount: int, repair_hull_by_remote_amount: int, repair_hull_remote_amount: int, repair_hull_self_amount: int, repair_shield_by_remote_amount: int, repair_shield_remote_amount: int, repair_shield_self_amount: int, self_destructs: int, warp_scramble_pc: int, warp_scrambledby_npc: int, warp_scrambledby_pc: int, weapon_flag_set: int, webifiedby_npc: int, webifiedby_pc: int, webifying_pc: int>, industry: record<hacking_successes: int, jobs_cancelled: int, jobs_completed_copy_blueprint: int, jobs_completed_invention: int, jobs_completed_manufacture: int, jobs_completed_manufacture_asteroid: int, jobs_completed_manufacture_asteroid_quantity: int, jobs_completed_manufacture_charge: int, jobs_completed_manufacture_charge_quantity: int, jobs_completed_manufacture_commodity: int, jobs_completed_manufacture_commodity_quantity: int, jobs_completed_manufacture_deployable: int, jobs_completed_manufacture_deployable_quantity: int, jobs_completed_manufacture_drone: int, jobs_completed_manufacture_drone_quantity: int, jobs_completed_manufacture_implant: int, jobs_completed_manufacture_implant_quantity: int, jobs_completed_manufacture_module: int, jobs_completed_manufacture_module_quantity: int, jobs_completed_manufacture_other: int, jobs_completed_manufacture_other_quantity: int, jobs_completed_manufacture_ship: int, jobs_completed_manufacture_ship_quantity: int, jobs_completed_manufacture_structure: int, jobs_completed_manufacture_structure_quantity: int, jobs_completed_manufacture_subsystem: int, jobs_completed_manufacture_subsystem_quantity: int, jobs_completed_material_productivity: int, jobs_completed_time_productivity: int, jobs_started_copy_blueprint: int, jobs_started_invention: int, jobs_started_manufacture: int, jobs_started_material_productivity: int, jobs_started_time_productivity: int, reprocess_item: int, reprocess_item_quantity: int>, inventory: record<abandon_loot_quantity: int, trash_item_quantity: int>, isk: record<in: int, out: int>, market: record<accept_contracts_courier: int, accept_contracts_item_exchange: int, buy_orders_placed: int, cancel_market_order: int, create_contracts_auction: int, create_contracts_courier: int, create_contracts_item_exchange: int, deliver_courier_contract: int, isk_gained: int, isk_spent: int, modify_market_order: int, search_contracts: int, sell_orders_placed: int>, mining: record<drone_mine: int, ore_arkonor: int, ore_bistot: int, ore_crokite: int, ore_dark_ochre: int, ore_gneiss: int, ore_harvestable_cloud: int, ore_hedbergite: int, ore_hemorphite: int, ore_ice: int, ore_jaspet: int, ore_kernite: int, ore_mercoxit: int, ore_omber: int, ore_plagioclase: int, ore_pyroxeres: int, ore_scordite: int, ore_spodumain: int, ore_veldspar: int>, module: record<activations_armor_hardener: int, activations_armor_repair_unit: int, activations_armor_resistance_shift_hardener: int, activations_automated_targeting_system: int, activations_bastion: int, activations_bomb_launcher: int, activations_capacitor_booster: int, activations_cargo_scanner: int, activations_cloaking_device: int, activations_clone_vat_bay: int, activations_cynosural_field: int, activations_damage_control: int, activations_data_miners: int, activations_drone_control_unit: int, activations_drone_tracking_modules: int, activations_eccm: int, activations_ecm: int, activations_ecm_burst: int, activations_energy_destabilizer: int, activations_energy_vampire: int, activations_energy_weapon: int, activations_festival_launcher: int, activations_frequency_mining_laser: int, activations_fueled_armor_repairer: int, activations_fueled_shield_booster: int, activations_gang_coordinator: int, activations_gas_cloud_harvester: int, activations_hull_repair_unit: int, activations_hybrid_weapon: int, activations_industrial_core: int, activations_interdiction_sphere_launcher: int, activations_micro_jump_drive: int, activations_mining_laser: int, activations_missile_launcher: int, activations_passive_targeting_system: int, activations_probe_launcher: int, activations_projected_eccm: int, activations_projectile_weapon: int, activations_propulsion_module: int, activations_remote_armor_repairer: int, activations_remote_capacitor_transmitter: int, activations_remote_ecm_burst: int, activations_remote_hull_repairer: int, activations_remote_sensor_booster: int, activations_remote_sensor_damper: int, activations_remote_shield_booster: int, activations_remote_tracking_computer: int, activations_salvager: int, activations_sensor_booster: int, activations_shield_booster: int, activations_shield_hardener: int, activations_ship_scanner: int, activations_siege: int, activations_smart_bomb: int, activations_stasis_web: int, activations_strip_miner: int, activations_super_weapon: int, activations_survey_scanner: int, activations_target_breaker: int, activations_target_painter: int, activations_tracking_computer: int, activations_tracking_disruptor: int, activations_tractor_beam: int, activations_triage: int, activations_warp_disrupt_field_generator: int, activations_warp_scrambler: int, link_weapons: int, overload: int, repairs: int>, orbital: record<strike_characters_killed: int, strike_damage_to_players_armor_amount: int, strike_damage_to_players_shield_amount: int>, pve: record<dungeons_completed_agent: int, dungeons_completed_distribution: int, missions_succeeded: int, missions_succeeded_epic_arc: int>, social: record<add_contact_bad: int, add_contact_good: int, add_contact_high: int, add_contact_horrible: int, add_contact_neutral: int, add_note: int, added_as_contact_bad: int, added_as_contact_good: int, added_as_contact_high: int, added_as_contact_horrible: int, added_as_contact_neutral: int, calendar_event_created: int, chat_messages_alliance: int, chat_messages_constellation: int, chat_messages_corporation: int, chat_messages_fleet: int, chat_messages_region: int, chat_messages_solarsystem: int, chat_messages_warfaction: int, chat_total_message_length: int, direct_trades: int, fleet_broadcasts: int, fleet_joins: int, mails_received: int, mails_sent: int>, travel: record<acceleration_gate_activations: int, align_to: int, distance_warped_high_sec: int, distance_warped_low_sec: int, distance_warped_null_sec: int, distance_warped_wormhole: int, docks_high_sec: int, docks_low_sec: int, docks_null_sec: int, jumps_stargate_high_sec: int, jumps_stargate_low_sec: int, jumps_stargate_null_sec: int, jumps_wormhole: int, warps_high_sec: int, warps_low_sec: int, warps_null_sec: int, warps_to_bookmark: int, warps_to_celestial: int, warps_to_fleet_member: int, warps_to_scan_result: int, warps_wormhole: int>, year: int>
# operationId: get_characters_character_id_stats
export def "get-characters-character-id-stats" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/stats/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get character corporation titles
#
# GET /characters/{character_id}/titles/
# Returns: table<name: string, title_id: int>
# operationId: get_characters_character_id_titles
export def "get-characters-character-id-titles" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/titles/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a character's wallet balance
#
# GET /characters/{character_id}/wallet/
# Returns: float
# operationId: get_characters_character_id_wallet
export def "get-characters-character-id-wallet" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> any {
  http-request {
    method: get
    path: "/characters/{character_id}/wallet/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get character wallet journal
#
# GET /characters/{character_id}/wallet/journal/
# Returns: table<amount: float, balance: float, context_id: int, context_id_type: string, date: string, description: string, first_party_id: int, id: int, reason: string, ref_type: string, second_party_id: int, tax: float, tax_receiver_id: int>
# operationId: get_characters_character_id_wallet_journal
export def "get-characters-character-id-wallet-journal" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/wallet/journal/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get wallet transactions
#
# GET /characters/{character_id}/wallet/transactions/
# Returns: table<client_id: int, date: string, is_buy: bool, is_personal: bool, journal_ref_id: int, location_id: int, quantity: int, transaction_id: int, type_id: int, unit_price: float>
# operationId: get_characters_character_id_wallet_transactions
export def "get-characters-character-id-wallet-transactions" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --from-id: int # Only show transactions happened before the one referenced by this id (format: int64)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/characters/{character_id}/wallet/transactions/"
    path_params: [{name: character_id, var: character_id}]
    query: [{name: datasource, var: datasource}, {name: from_id, var: from_id}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    character_id: $character_id, datasource: $datasource, from_id: $from_id, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get public contract bids
#
# GET /contracts/public/bids/{contract_id}/
# Returns: table<amount: float, bid_id: int, date_bid: string>
# operationId: get_contracts_public_bids_contract_id
export def "get-contracts-public-bids-contract-id" [
  contract_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/contracts/public/bids/{contract_id}/"
    path_params: [{name: contract_id, var: contract_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 204, 304]
    auth: bearer
  } {
    contract_id: $contract_id, datasource: $datasource, page: $page, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get public contract items
#
# GET /contracts/public/items/{contract_id}/
# Returns: table<is_blueprint_copy: bool, is_included: bool, item_id: int, material_efficiency: int, quantity: int, record_id: int, runs: int, time_efficiency: int, type_id: int>
# operationId: get_contracts_public_items_contract_id
export def "get-contracts-public-items-contract-id" [
  contract_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/contracts/public/items/{contract_id}/"
    path_params: [{name: contract_id, var: contract_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 204, 304]
    auth: bearer
  } {
    contract_id: $contract_id, datasource: $datasource, page: $page, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get public contracts
#
# GET /contracts/public/{region_id}/
# Returns: table<buyout: float, collateral: float, contract_id: int, date_expired: string, date_issued: string, days_to_complete: int, end_location_id: int, for_corporation: bool, issuer_corporation_id: int, issuer_id: int, price: float, reward: float, start_location_id: int, title: string, type: string, volume: float>
# operationId: get_contracts_public_region_id
export def "get-contracts-public-region-id" [
  region_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/contracts/public/{region_id}/"
    path_params: [{name: region_id, var: region_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    region_id: $region_id, datasource: $datasource, page: $page, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moon extraction timers
#
# GET /corporation/{corporation_id}/mining/extractions/
# Returns: table<chunk_arrival_time: string, extraction_start_time: string, moon_id: int, natural_decay_time: string, structure_id: int>
# operationId: get_corporation_corporation_id_mining_extractions
export def "get-corporation-corporation-id-mining-extractions" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporation/{corporation_id}/mining/extractions/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Corporation mining observers
#
# GET /corporation/{corporation_id}/mining/observers/
# Returns: table<last_updated: string, observer_id: int, observer_type: string>
# operationId: get_corporation_corporation_id_mining_observers
export def "get-corporation-corporation-id-mining-observers" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporation/{corporation_id}/mining/observers/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Observed corporation mining
#
# GET /corporation/{corporation_id}/mining/observers/{observer_id}/
# Returns: table<character_id: int, last_updated: string, quantity: int, recorded_corporation_id: int, type_id: int>
# operationId: get_corporation_corporation_id_mining_observers_observer_id
export def "get-corporation-corporation-id-mining-observers-observer-id" [
  corporation_id: int
  observer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporation/{corporation_id}/mining/observers/{observer_id}/"
    path_params: [{name: corporation_id, var: corporation_id}, {name: observer_id, var: observer_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, observer_id: $observer_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get npc corporations
#
# GET /corporations/npccorps/
# Returns: list<int>
# operationId: get_corporations_npccorps
export def "get-corporations-npccorps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/npccorps/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation information
#
# GET /corporations/{corporation_id}/
# Returns: record<alliance_id: int, ceo_id: int, creator_id: int, date_founded: string, description: string, faction_id: int, home_station_id: int, member_count: int, name: string, shares: int, tax_rate: float, ticker: string, url: string, war_eligible: bool>
# operationId: get_corporations_corporation_id
export def "get-corporations-corporation-id" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get alliance history
#
# GET /corporations/{corporation_id}/alliancehistory/
# Returns: table<alliance_id: int, is_deleted: bool, record_id: int, start_date: string>
# operationId: get_corporations_corporation_id_alliancehistory
export def "get-corporations-corporation-id-alliancehistory" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/alliancehistory/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation assets
#
# GET /corporations/{corporation_id}/assets/
# Returns: table<is_blueprint_copy: bool, is_singleton: bool, item_id: int, location_flag: string, location_id: int, location_type: string, quantity: int, type_id: int>
# operationId: get_corporations_corporation_id_assets
export def "get-corporations-corporation-id-assets" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/assets/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation asset locations
#
# POST /corporations/{corporation_id}/assets/locations/
# Returns: table<item_id: int, position: record<x: float, y: float, z: float>>
# operationId: post_corporations_corporation_id_assets_locations
export def "post-corporations-corporation-id-assets-locations" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/corporations/{corporation_id}/assets/locations/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, qp_token: $qp_token, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation asset names
#
# POST /corporations/{corporation_id}/assets/names/
# Returns: table<item_id: int, name: string>
# operationId: post_corporations_corporation_id_assets_names
export def "post-corporations-corporation-id-assets-names" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/corporations/{corporation_id}/assets/names/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, qp_token: $qp_token, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation blueprints
#
# GET /corporations/{corporation_id}/blueprints/
# Returns: table<item_id: int, location_flag: string, location_id: int, material_efficiency: int, quantity: int, runs: int, time_efficiency: int, type_id: int>
# operationId: get_corporations_corporation_id_blueprints
export def "get-corporations-corporation-id-blueprints" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/blueprints/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List corporation bookmarks
#
# GET /corporations/{corporation_id}/bookmarks/
# Returns: table<bookmark_id: int, coordinates: record<x: float, y: float, z: float>, created: string, creator_id: int, folder_id: int, item: record<item_id: int, type_id: int>, label: string, location_id: int, notes: string>
# operationId: get_corporations_corporation_id_bookmarks
export def "get-corporations-corporation-id-bookmarks" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/bookmarks/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List corporation bookmark folders
#
# GET /corporations/{corporation_id}/bookmarks/folders/
# Returns: table<creator_id: int, folder_id: int, name: string>
# operationId: get_corporations_corporation_id_bookmarks_folders
export def "get-corporations-corporation-id-bookmarks-folders" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/bookmarks/folders/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation contacts
#
# GET /corporations/{corporation_id}/contacts/
# Returns: table<contact_id: int, contact_type: string, is_watched: bool, label_ids: list<int>, standing: float>
# operationId: get_corporations_corporation_id_contacts
export def "get-corporations-corporation-id-contacts" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/contacts/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation contact labels
#
# GET /corporations/{corporation_id}/contacts/labels/
# Returns: table<label_id: int, label_name: string>
# operationId: get_corporations_corporation_id_contacts_labels
export def "get-corporations-corporation-id-contacts-labels" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/contacts/labels/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all corporation ALSC logs
#
# GET /corporations/{corporation_id}/containers/logs/
# Returns: table<action: string, character_id: int, container_id: int, container_type_id: int, location_flag: string, location_id: int, logged_at: string, new_config_bitmask: int, old_config_bitmask: int, password_type: string, quantity: int, type_id: int>
# operationId: get_corporations_corporation_id_containers_logs
export def "get-corporations-corporation-id-containers-logs" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/containers/logs/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation contracts
#
# GET /corporations/{corporation_id}/contracts/
# Returns: table<acceptor_id: int, assignee_id: int, availability: string, buyout: float, collateral: float, contract_id: int, date_accepted: string, date_completed: string, date_expired: string, date_issued: string, days_to_complete: int, end_location_id: int, for_corporation: bool, issuer_corporation_id: int, issuer_id: int, price: float, reward: float, start_location_id: int, status: string, title: string, type: string, volume: float>
# operationId: get_corporations_corporation_id_contracts
export def "get-corporations-corporation-id-contracts" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/contracts/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation contract bids
#
# GET /corporations/{corporation_id}/contracts/{contract_id}/bids/
# Returns: table<amount: float, bid_id: int, bidder_id: int, date_bid: string>
# operationId: get_corporations_corporation_id_contracts_contract_id_bids
export def "get-corporations-corporation-id-contracts-contract-id-bids" [
  corporation_id: int
  contract_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/contracts/{contract_id}/bids/"
    path_params: [{name: corporation_id, var: corporation_id}, {name: contract_id, var: contract_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, contract_id: $contract_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation contract items
#
# GET /corporations/{corporation_id}/contracts/{contract_id}/items/
# Returns: table<is_included: bool, is_singleton: bool, quantity: int, raw_quantity: int, record_id: int, type_id: int>
# operationId: get_corporations_corporation_id_contracts_contract_id_items
export def "get-corporations-corporation-id-contracts-contract-id-items" [
  corporation_id: int
  contract_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/contracts/{contract_id}/items/"
    path_params: [{name: corporation_id, var: corporation_id}, {name: contract_id, var: contract_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, contract_id: $contract_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List corporation customs offices
#
# GET /corporations/{corporation_id}/customs_offices/
# Returns: table<alliance_tax_rate: float, allow_access_with_standings: bool, allow_alliance_access: bool, bad_standing_tax_rate: float, corporation_tax_rate: float, excellent_standing_tax_rate: float, good_standing_tax_rate: float, neutral_standing_tax_rate: float, office_id: int, reinforce_exit_end: int, reinforce_exit_start: int, standing_level: string, system_id: int, terrible_standing_tax_rate: float>
# operationId: get_corporations_corporation_id_customs_offices
export def "get-corporations-corporation-id-customs-offices" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/customs_offices/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation divisions
#
# GET /corporations/{corporation_id}/divisions/
# Returns: record<hangar: table<division: int, name: string>, wallet: table<division: int, name: string>>
# operationId: get_corporations_corporation_id_divisions
export def "get-corporations-corporation-id-divisions" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/divisions/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation facilities
#
# GET /corporations/{corporation_id}/facilities/
# Returns: table<facility_id: int, system_id: int, type_id: int>
# operationId: get_corporations_corporation_id_facilities
export def "get-corporations-corporation-id-facilities" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/facilities/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Overview of a corporation involved in faction warfare
#
# GET /corporations/{corporation_id}/fw/stats/
# Returns: record<enlisted_on: string, faction_id: int, kills: record<last_week: int, total: int, yesterday: int>, pilots: int, victory_points: record<last_week: int, total: int, yesterday: int>>
# operationId: get_corporations_corporation_id_fw_stats
export def "get-corporations-corporation-id-fw-stats" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/fw/stats/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation icon
#
# GET /corporations/{corporation_id}/icons/
# Returns: record<px128x128: string, px256x256: string, px64x64: string>
# operationId: get_corporations_corporation_id_icons
export def "get-corporations-corporation-id-icons" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/icons/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List corporation industry jobs
#
# GET /corporations/{corporation_id}/industry/jobs/
# Returns: table<activity_id: int, blueprint_id: int, blueprint_location_id: int, blueprint_type_id: int, completed_character_id: int, completed_date: string, cost: float, duration: int, end_date: string, facility_id: int, installer_id: int, job_id: int, licensed_runs: int, location_id: int, output_location_id: int, pause_date: string, probability: float, product_type_id: int, runs: int, start_date: string, status: string, successful_runs: int>
# operationId: get_corporations_corporation_id_industry_jobs
export def "get-corporations-corporation-id-industry-jobs" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --include-completed: oneof<nothing, bool> # Whether to retrieve completed corporation industry jobs. Only includes jobs from the past 90 days (default: false)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/industry/jobs/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: include_completed, var: include_completed}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, include_completed: $include_completed, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a corporation's recent kills and losses
#
# GET /corporations/{corporation_id}/killmails/recent/
# Returns: table<killmail_hash: string, killmail_id: int>
# operationId: get_corporations_corporation_id_killmails_recent
export def "get-corporations-corporation-id-killmails-recent" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/killmails/recent/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation medals
#
# GET /corporations/{corporation_id}/medals/
# Returns: table<created_at: string, creator_id: int, description: string, medal_id: int, title: string>
# operationId: get_corporations_corporation_id_medals
export def "get-corporations-corporation-id-medals" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/medals/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation issued medals
#
# GET /corporations/{corporation_id}/medals/issued/
# Returns: table<character_id: int, issued_at: string, issuer_id: int, medal_id: int, reason: string, status: string>
# operationId: get_corporations_corporation_id_medals_issued
export def "get-corporations-corporation-id-medals-issued" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/medals/issued/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation members
#
# GET /corporations/{corporation_id}/members/
# Returns: list<int>
# operationId: get_corporations_corporation_id_members
export def "get-corporations-corporation-id-members" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/members/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation member limit
#
# GET /corporations/{corporation_id}/members/limit/
# Returns: int
# operationId: get_corporations_corporation_id_members_limit
export def "get-corporations-corporation-id-members-limit" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> any {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/members/limit/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation's members' titles
#
# GET /corporations/{corporation_id}/members/titles/
# Returns: table<character_id: int, titles: list<int>>
# operationId: get_corporations_corporation_id_members_titles
export def "get-corporations-corporation-id-members-titles" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/members/titles/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Track corporation members
#
# GET /corporations/{corporation_id}/membertracking/
# Returns: table<base_id: int, character_id: int, location_id: int, logoff_date: string, logon_date: string, ship_type_id: int, start_date: string>
# operationId: get_corporations_corporation_id_membertracking
export def "get-corporations-corporation-id-membertracking" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/membertracking/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List open orders from a corporation
#
# GET /corporations/{corporation_id}/orders/
# Returns: table<duration: int, escrow: float, is_buy_order: bool, issued: string, issued_by: int, location_id: int, min_volume: int, order_id: int, price: float, range: string, region_id: int, type_id: int, volume_remain: int, volume_total: int, wallet_division: int>
# operationId: get_corporations_corporation_id_orders
export def "get-corporations-corporation-id-orders" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/orders/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List historical orders from a corporation
#
# GET /corporations/{corporation_id}/orders/history/
# Returns: table<duration: int, escrow: float, is_buy_order: bool, issued: string, issued_by: int, location_id: int, min_volume: int, order_id: int, price: float, range: string, region_id: int, state: string, type_id: int, volume_remain: int, volume_total: int, wallet_division: int>
# operationId: get_corporations_corporation_id_orders_history
export def "get-corporations-corporation-id-orders-history" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/orders/history/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation member roles
#
# GET /corporations/{corporation_id}/roles/
# Returns: table<character_id: int, grantable_roles: list<string>, grantable_roles_at_base: list<string>, grantable_roles_at_hq: list<string>, grantable_roles_at_other: list<string>, roles: list<string>, roles_at_base: list<string>, roles_at_hq: list<string>, roles_at_other: list<string>>
# operationId: get_corporations_corporation_id_roles
export def "get-corporations-corporation-id-roles" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/roles/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation member roles history
#
# GET /corporations/{corporation_id}/roles/history/
# Returns: table<changed_at: string, character_id: int, issuer_id: int, new_roles: list<string>, old_roles: list<string>, role_type: string>
# operationId: get_corporations_corporation_id_roles_history
export def "get-corporations-corporation-id-roles-history" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/roles/history/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation shareholders
#
# GET /corporations/{corporation_id}/shareholders/
# Returns: table<share_count: int, shareholder_id: int, shareholder_type: string>
# operationId: get_corporations_corporation_id_shareholders
export def "get-corporations-corporation-id-shareholders" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/shareholders/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation standings
#
# GET /corporations/{corporation_id}/standings/
# Returns: table<from_id: int, from_type: string, standing: float>
# operationId: get_corporations_corporation_id_standings
export def "get-corporations-corporation-id-standings" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/standings/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation starbases (POSes)
#
# GET /corporations/{corporation_id}/starbases/
# Returns: table<moon_id: int, onlined_since: string, reinforced_until: string, starbase_id: int, state: string, system_id: int, type_id: int, unanchor_at: string>
# operationId: get_corporations_corporation_id_starbases
export def "get-corporations-corporation-id-starbases" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/starbases/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get starbase (POS) detail
#
# GET /corporations/{corporation_id}/starbases/{starbase_id}/
# Returns: record<allow_alliance_members: bool, allow_corporation_members: bool, anchor: string, attack_if_at_war: bool, attack_if_other_security_status_dropping: bool, attack_security_status_threshold: float, attack_standing_threshold: float, fuel_bay_take: string, fuel_bay_view: string, fuels: table<quantity: int, type_id: int>, offline: string, online: string, unanchor: string, use_alliance_standings: bool>
# operationId: get_corporations_corporation_id_starbases_starbase_id
export def "get-corporations-corporation-id-starbases-starbase-id" [
  corporation_id: int
  starbase_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --system-id: int # The solar system this starbase (POS) is located in, (required, format: int32)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/starbases/{starbase_id}/"
    path_params: [{name: corporation_id, var: corporation_id}, {name: starbase_id, var: starbase_id}]
    query: [{name: datasource, var: datasource}, {name: system_id, var: system_id, required: true}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, starbase_id: $starbase_id, datasource: $datasource, system_id: $system_id, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation structures
#
# GET /corporations/{corporation_id}/structures/
# Returns: table<corporation_id: int, fuel_expires: string, next_reinforce_apply: string, next_reinforce_hour: int, next_reinforce_weekday: int, profile_id: int, reinforce_hour: int, reinforce_weekday: int, services: list<record>, state: string, state_timer_end: string, state_timer_start: string, structure_id: int, system_id: int, type_id: int, unanchors_at: string>
# operationId: get_corporations_corporation_id_structures
export def "get-corporations-corporation-id-structures" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/structures/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: language, var: language}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: Accept-Language, var: accept_language}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, language: $language, page: $page, qp_token: $qp_token, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation titles
#
# GET /corporations/{corporation_id}/titles/
# Returns: table<grantable_roles: list<string>, grantable_roles_at_base: list<string>, grantable_roles_at_hq: list<string>, grantable_roles_at_other: list<string>, name: string, roles: list<string>, roles_at_base: list<string>, roles_at_hq: list<string>, roles_at_other: list<string>, title_id: int>
# operationId: get_corporations_corporation_id_titles
export def "get-corporations-corporation-id-titles" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/titles/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a corporation's wallet balance
#
# GET /corporations/{corporation_id}/wallets/
# Returns: table<balance: float, division: int>
# operationId: get_corporations_corporation_id_wallets
export def "get-corporations-corporation-id-wallets" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/wallets/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation wallet journal
#
# GET /corporations/{corporation_id}/wallets/{division}/journal/
# Returns: table<amount: float, balance: float, context_id: int, context_id_type: string, date: string, description: string, first_party_id: int, id: int, reason: string, ref_type: string, second_party_id: int, tax: float, tax_receiver_id: int>
# operationId: get_corporations_corporation_id_wallets_division_journal
export def "get-corporations-corporation-id-wallets-division-journal" [
  corporation_id: int
  division: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/wallets/{division}/journal/"
    path_params: [{name: corporation_id, var: corporation_id}, {name: division, var: division}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, division: $division, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get corporation wallet transactions
#
# GET /corporations/{corporation_id}/wallets/{division}/transactions/
# Returns: table<client_id: int, date: string, is_buy: bool, journal_ref_id: int, location_id: int, quantity: int, transaction_id: int, type_id: int, unit_price: float>
# operationId: get_corporations_corporation_id_wallets_division_transactions
export def "get-corporations-corporation-id-wallets-division-transactions" [
  corporation_id: int
  division: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --from-id: int # Only show journal entries happened before the transaction referenced by this id (format: int64)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/corporations/{corporation_id}/wallets/{division}/transactions/"
    path_params: [{name: corporation_id, var: corporation_id}, {name: division, var: division}]
    query: [{name: datasource, var: datasource}, {name: from_id, var: from_id}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, division: $division, datasource: $datasource, from_id: $from_id, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attributes
#
# GET /dogma/attributes/
# Returns: list<int>
# operationId: get_dogma_attributes
export def "get-dogma-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/dogma/attributes/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attribute information
#
# GET /dogma/attributes/{attribute_id}/
# Returns: record<attribute_id: int, default_value: float, description: string, display_name: string, high_is_good: bool, icon_id: int, name: string, published: bool, stackable: bool, unit_id: int>
# operationId: get_dogma_attributes_attribute_id
export def "get-dogma-attributes-attribute-id" [
  attribute_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dogma/attributes/{attribute_id}/"
    path_params: [{name: attribute_id, var: attribute_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    attribute_id: $attribute_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get dynamic item information
#
# GET /dogma/dynamic/items/{type_id}/{item_id}/
# Returns: record<created_by: int, dogma_attributes: table<attribute_id: int, value: float>, dogma_effects: table<effect_id: int, is_default: bool>, mutator_type_id: int, source_type_id: int>
# operationId: get_dogma_dynamic_items_type_id_item_id
export def "get-dogma-dynamic-items-type-id-item-id" [
  type_id: int
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dogma/dynamic/items/{type_id}/{item_id}/"
    path_params: [{name: type_id, var: type_id}, {name: item_id, var: item_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    type_id: $type_id, item_id: $item_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get effects
#
# GET /dogma/effects/
# Returns: list<int>
# operationId: get_dogma_effects
export def "get-dogma-effects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/dogma/effects/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get effect information
#
# GET /dogma/effects/{effect_id}/
# Returns: record<description: string, disallow_auto_repeat: bool, discharge_attribute_id: int, display_name: string, duration_attribute_id: int, effect_category: int, effect_id: int, electronic_chance: bool, falloff_attribute_id: int, icon_id: int, is_assistance: bool, is_offensive: bool, is_warp_safe: bool, modifiers: table<domain: string, effect_id: int, func: string, modified_attribute_id: int, modifying_attribute_id: int, operator: int>, name: string, post_expression: int, pre_expression: int, published: bool, range_attribute_id: int, range_chance: bool, tracking_speed_attribute_id: int>
# operationId: get_dogma_effects_effect_id
export def "get-dogma-effects-effect-id" [
  effect_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dogma/effects/{effect_id}/"
    path_params: [{name: effect_id, var: effect_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    effect_id: $effect_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get fleet information
#
# GET /fleets/{fleet_id}/
# Returns: record<is_free_move: bool, is_registered: bool, is_voice_enabled: bool, motd: string>
# operationId: get_fleets_fleet_id
export def "get-fleets-fleet-id" [
  fleet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/fleets/{fleet_id}/"
    path_params: [{name: fleet_id, var: fleet_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    fleet_id: $fleet_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update fleet
#
# PUT /fleets/{fleet_id}/
# operationId: put_fleets_fleet_id
export def "put-fleets-fleet-id" [
  fleet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --is-free-move: oneof<nothing, bool> # Should free-move be enabled in the fleet
  --motd: string # New fleet MOTD in CCP flavoured HTML
]: any -> any {
  $in | http-request {
    method: put
    path: "/fleets/{fleet_id}/"
    path_params: [{name: fleet_id, var: fleet_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: is_free_move, var: is_free_move}, {name: motd, var: motd}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    fleet_id: $fleet_id, datasource: $datasource, qp_token: $qp_token, is_free_move: $is_free_move, motd: $motd
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get fleet members
#
# GET /fleets/{fleet_id}/members/
# Returns: table<character_id: int, join_time: string, role: string, role_name: string, ship_type_id: int, solar_system_id: int, squad_id: int, station_id: int, takes_fleet_warp: bool, wing_id: int>
# operationId: get_fleets_fleet_id_members
export def "get-fleets-fleet-id-members" [
  fleet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/fleets/{fleet_id}/members/"
    path_params: [{name: fleet_id, var: fleet_id}]
    query: [{name: datasource, var: datasource}, {name: language, var: language}, {name: token, var: qp_token}]
    header: [{name: Accept-Language, var: accept_language}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    fleet_id: $fleet_id, datasource: $datasource, language: $language, qp_token: $qp_token, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create fleet invitation
#
# POST /fleets/{fleet_id}/members/
# operationId: post_fleets_fleet_id_members
export def "post-fleets-fleet-id-members" [
  fleet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  character_id: int # The character you want to invite (format: int32)
  role: string@role-completer # If a character is invited with the `fleet_commander` role, neither `wing_id` or `squad_id` should be specified. If a character is invited with the `wing_commander` role, only `wing_id` should be specified. If a character is invited with the `squad_commander` role, both `wing_id` and `squad_id` should be specified. If a character is invited with the `squad_member` role, `wing_id` and `squad_id` should either both be specified or not specified at all. If they aren’t specified, the invited character will join any squad with available positions.
  --squad-id: int # squad_id integer (format: int64)
  --wing-id: int # wing_id integer (format: int64)
]: any -> any {
  $in | http-request {
    method: post
    path: "/fleets/{fleet_id}/members/"
    path_params: [{name: fleet_id, var: fleet_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: character_id, var: character_id}, {name: role, var: role}, {name: squad_id, var: squad_id}, {name: wing_id, var: wing_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    fleet_id: $fleet_id, datasource: $datasource, qp_token: $qp_token, character_id: $character_id, role: $role, squad_id: $squad_id, wing_id: $wing_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kick fleet member
#
# DELETE /fleets/{fleet_id}/members/{member_id}/
# operationId: delete_fleets_fleet_id_members_member_id
export def "delete-fleets-fleet-id-members-member-id" [
  fleet_id: int
  member_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/fleets/{fleet_id}/members/{member_id}/"
    path_params: [{name: fleet_id, var: fleet_id}, {name: member_id, var: member_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    fleet_id: $fleet_id, member_id: $member_id, datasource: $datasource, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Move fleet member
#
# PUT /fleets/{fleet_id}/members/{member_id}/
# operationId: put_fleets_fleet_id_members_member_id
export def "put-fleets-fleet-id-members-member-id" [
  fleet_id: int
  member_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  role: string@role-completer # If a character is moved to the `fleet_commander` role, neither `wing_id` or `squad_id` should be specified. If a character is moved to the `wing_commander` role, only `wing_id` should be specified. If a character is moved to the `squad_commander` role, both `wing_id` and `squad_id` should be specified. If a character is moved to the `squad_member` role, both `wing_id` and `squad_id` should be specified.
  --squad-id: int # squad_id integer (format: int64)
  --wing-id: int # wing_id integer (format: int64)
]: any -> any {
  $in | http-request {
    method: put
    path: "/fleets/{fleet_id}/members/{member_id}/"
    path_params: [{name: fleet_id, var: fleet_id}, {name: member_id, var: member_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: role, var: role}, {name: squad_id, var: squad_id}, {name: wing_id, var: wing_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    fleet_id: $fleet_id, member_id: $member_id, datasource: $datasource, qp_token: $qp_token, role: $role, squad_id: $squad_id, wing_id: $wing_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete fleet squad
#
# DELETE /fleets/{fleet_id}/squads/{squad_id}/
# operationId: delete_fleets_fleet_id_squads_squad_id
export def "delete-fleets-fleet-id-squads-squad-id" [
  fleet_id: int
  squad_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/fleets/{fleet_id}/squads/{squad_id}/"
    path_params: [{name: fleet_id, var: fleet_id}, {name: squad_id, var: squad_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    fleet_id: $fleet_id, squad_id: $squad_id, datasource: $datasource, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rename fleet squad
#
# PUT /fleets/{fleet_id}/squads/{squad_id}/
# operationId: put_fleets_fleet_id_squads_squad_id
export def "put-fleets-fleet-id-squads-squad-id" [
  fleet_id: int
  squad_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  name: string # name string
]: any -> any {
  $in | http-request {
    method: put
    path: "/fleets/{fleet_id}/squads/{squad_id}/"
    path_params: [{name: fleet_id, var: fleet_id}, {name: squad_id, var: squad_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    fleet_id: $fleet_id, squad_id: $squad_id, datasource: $datasource, qp_token: $qp_token, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get fleet wings
#
# GET /fleets/{fleet_id}/wings/
# Returns: table<id: int, name: string, squads: list<record>>
# operationId: get_fleets_fleet_id_wings
export def "get-fleets-fleet-id-wings" [
  fleet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/fleets/{fleet_id}/wings/"
    path_params: [{name: fleet_id, var: fleet_id}]
    query: [{name: datasource, var: datasource}, {name: language, var: language}, {name: token, var: qp_token}]
    header: [{name: Accept-Language, var: accept_language}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    fleet_id: $fleet_id, datasource: $datasource, language: $language, qp_token: $qp_token, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create fleet wing
#
# POST /fleets/{fleet_id}/wings/
# Returns: record<wing_id: int>
# operationId: post_fleets_fleet_id_wings
export def "post-fleets-fleet-id-wings" [
  fleet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/fleets/{fleet_id}/wings/"
    path_params: [{name: fleet_id, var: fleet_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    fleet_id: $fleet_id, datasource: $datasource, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete fleet wing
#
# DELETE /fleets/{fleet_id}/wings/{wing_id}/
# operationId: delete_fleets_fleet_id_wings_wing_id
export def "delete-fleets-fleet-id-wings-wing-id" [
  fleet_id: int
  wing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/fleets/{fleet_id}/wings/{wing_id}/"
    path_params: [{name: fleet_id, var: fleet_id}, {name: wing_id, var: wing_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    fleet_id: $fleet_id, wing_id: $wing_id, datasource: $datasource, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rename fleet wing
#
# PUT /fleets/{fleet_id}/wings/{wing_id}/
# operationId: put_fleets_fleet_id_wings_wing_id
export def "put-fleets-fleet-id-wings-wing-id" [
  fleet_id: int
  wing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  name: string # name string
]: any -> any {
  $in | http-request {
    method: put
    path: "/fleets/{fleet_id}/wings/{wing_id}/"
    path_params: [{name: fleet_id, var: fleet_id}, {name: wing_id, var: wing_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    fleet_id: $fleet_id, wing_id: $wing_id, datasource: $datasource, qp_token: $qp_token, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create fleet squad
#
# POST /fleets/{fleet_id}/wings/{wing_id}/squads/
# Returns: record<squad_id: int>
# operationId: post_fleets_fleet_id_wings_wing_id_squads
export def "post-fleets-fleet-id-wings-wing-id-squads" [
  fleet_id: int
  wing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/fleets/{fleet_id}/wings/{wing_id}/squads/"
    path_params: [{name: fleet_id, var: fleet_id}, {name: wing_id, var: wing_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    fleet_id: $fleet_id, wing_id: $wing_id, datasource: $datasource, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of the top factions in faction warfare
#
# GET /fw/leaderboards/
# Returns: record<kills: record<active_total: list<record>, last_week: list<record>, yesterday: list<record>>, victory_points: record<active_total: list<record>, last_week: list<record>, yesterday: list<record>>>
# operationId: get_fw_leaderboards
export def "get-fw-leaderboards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/fw/leaderboards/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of the top pilots in faction warfare
#
# GET /fw/leaderboards/characters/
# Returns: record<kills: record<active_total: list<record>, last_week: list<record>, yesterday: list<record>>, victory_points: record<active_total: list<record>, last_week: list<record>, yesterday: list<record>>>
# operationId: get_fw_leaderboards_characters
export def "get-fw-leaderboards-characters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/fw/leaderboards/characters/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of the top corporations in faction warfare
#
# GET /fw/leaderboards/corporations/
# Returns: record<kills: record<active_total: list<record>, last_week: list<record>, yesterday: list<record>>, victory_points: record<active_total: list<record>, last_week: list<record>, yesterday: list<record>>>
# operationId: get_fw_leaderboards_corporations
export def "get-fw-leaderboards-corporations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/fw/leaderboards/corporations/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# An overview of statistics about factions involved in faction warfare
#
# GET /fw/stats/
# Returns: table<faction_id: int, kills: record<last_week: int, total: int, yesterday: int>, pilots: int, systems_controlled: int, victory_points: record<last_week: int, total: int, yesterday: int>>
# operationId: get_fw_stats
export def "get-fw-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/fw/stats/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ownership of faction warfare systems
#
# GET /fw/systems/
# Returns: table<contested: string, occupier_faction_id: int, owner_faction_id: int, solar_system_id: int, victory_points: int, victory_points_threshold: int>
# operationId: get_fw_systems
export def "get-fw-systems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/fw/systems/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Data about which NPC factions are at war
#
# GET /fw/wars/
# Returns: table<against_id: int, faction_id: int>
# operationId: get_fw_wars
export def "get-fw-wars" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/fw/wars/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List incursions
#
# GET /incursions/
# Returns: table<constellation_id: int, faction_id: int, has_boss: bool, infested_solar_systems: list<int>, influence: float, staging_solar_system_id: int, state: string, type: string>
# operationId: get_incursions
export def "get-incursions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/incursions/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List industry facilities
#
# GET /industry/facilities/
# Returns: table<facility_id: int, owner_id: int, region_id: int, solar_system_id: int, tax: float, type_id: int>
# operationId: get_industry_facilities
export def "get-industry-facilities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/industry/facilities/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List solar system cost indices
#
# GET /industry/systems/
# Returns: table<cost_indices: list<record>, solar_system_id: int>
# operationId: get_industry_systems
export def "get-industry-systems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/industry/systems/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List insurance levels
#
# GET /insurance/prices/
# Returns: table<levels: list<record>, type_id: int>
# operationId: get_insurance_prices
export def "get-insurance-prices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/insurance/prices/"
    query: [{name: datasource, var: datasource}, {name: language, var: language}]
    header: [{name: Accept-Language, var: accept_language}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, language: $language, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single killmail
#
# GET /killmails/{killmail_id}/{killmail_hash}/
# Returns: record<attackers: table<alliance_id: int, character_id: int, corporation_id: int, damage_done: int, faction_id: int, final_blow: bool, security_status: float, ship_type_id: int, weapon_type_id: int>, killmail_id: int, killmail_time: string, moon_id: int, solar_system_id: int, victim: record<alliance_id: int, character_id: int, corporation_id: int, damage_taken: int, faction_id: int, items: list<record>, position: record<x: float, y: float, z: float>, ship_type_id: int>, war_id: int>
# operationId: get_killmails_killmail_id_killmail_hash
export def "get-killmails-killmail-id-killmail-hash" [
  killmail_id: int
  killmail_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/killmails/{killmail_id}/{killmail_hash}/"
    path_params: [{name: killmail_id, var: killmail_id}, {name: killmail_hash, var: killmail_hash}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    killmail_id: $killmail_id, killmail_hash: $killmail_hash, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List loyalty store offers
#
# GET /loyalty/stores/{corporation_id}/offers/
# Returns: table<ak_cost: int, isk_cost: int, lp_cost: int, offer_id: int, quantity: int, required_items: list<record>, type_id: int>
# operationId: get_loyalty_stores_corporation_id_offers
export def "get-loyalty-stores-corporation-id-offers" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/loyalty/stores/{corporation_id}/offers/"
    path_params: [{name: corporation_id, var: corporation_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    corporation_id: $corporation_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get item groups
#
# GET /markets/groups/
# Returns: list<int>
# operationId: get_markets_groups
export def "get-markets-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/markets/groups/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get item group information
#
# GET /markets/groups/{market_group_id}/
# Returns: record<description: string, market_group_id: int, name: string, parent_group_id: int, types: list<int>>
# operationId: get_markets_groups_market_group_id
export def "get-markets-groups-market-group-id" [
  market_group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/markets/groups/{market_group_id}/"
    path_params: [{name: market_group_id, var: market_group_id}]
    query: [{name: datasource, var: datasource}, {name: language, var: language}]
    header: [{name: Accept-Language, var: accept_language}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    market_group_id: $market_group_id, datasource: $datasource, language: $language, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List market prices
#
# GET /markets/prices/
# Returns: table<adjusted_price: float, average_price: float, type_id: int>
# operationId: get_markets_prices
export def "get-markets-prices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/markets/prices/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List orders in a structure
#
# GET /markets/structures/{structure_id}/
# Returns: table<duration: int, is_buy_order: bool, issued: string, location_id: int, min_volume: int, order_id: int, price: float, range: string, type_id: int, volume_remain: int, volume_total: int>
# operationId: get_markets_structures_structure_id
export def "get-markets-structures-structure-id" [
  structure_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/markets/structures/{structure_id}/"
    path_params: [{name: structure_id, var: structure_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    structure_id: $structure_id, datasource: $datasource, page: $page, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List historical market statistics in a region
#
# GET /markets/{region_id}/history/
# Returns: table<average: float, date: string, highest: float, lowest: float, order_count: int, volume: int>
# operationId: get_markets_region_id_history
export def "get-markets-region-id-history" [
  region_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --type-id: int # Return statistics for this type (required, format: int32)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/markets/{region_id}/history/"
    path_params: [{name: region_id, var: region_id}]
    query: [{name: datasource, var: datasource}, {name: type_id, var: type_id, required: true}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    region_id: $region_id, datasource: $datasource, type_id: $type_id, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List orders in a region
#
# GET /markets/{region_id}/orders/
# Returns: table<duration: int, is_buy_order: bool, issued: string, location_id: int, min_volume: int, order_id: int, price: float, range: string, system_id: int, type_id: int, volume_remain: int, volume_total: int>
# operationId: get_markets_region_id_orders
export def "get-markets-region-id-orders" [
  region_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --order-type: string@order-type-completer # Filter buy/sell orders, return all orders by default. If you query without type_id, we always return both buy and sell orders (required, default: all)
  --page: int # Which page of results to return (format: int32, default: 1)
  --type-id: int # Return orders only for this type (format: int32)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/markets/{region_id}/orders/"
    path_params: [{name: region_id, var: region_id}]
    query: [{name: datasource, var: datasource}, {name: order_type, var: order_type, required: true, default: all}, {name: page, var: page}, {name: type_id, var: type_id}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    region_id: $region_id, datasource: $datasource, order_type: $order_type, page: $page, type_id: $type_id, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List type IDs relevant to a market
#
# GET /markets/{region_id}/types/
# Returns: list<int>
# operationId: get_markets_region_id_types
export def "get-markets-region-id-types" [
  region_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/markets/{region_id}/types/"
    path_params: [{name: region_id, var: region_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    region_id: $region_id, datasource: $datasource, page: $page, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get opportunities groups
#
# GET /opportunities/groups/
# Returns: list<int>
# operationId: get_opportunities_groups
export def "get-opportunities-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/opportunities/groups/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get opportunities group
#
# GET /opportunities/groups/{group_id}/
# Returns: record<connected_groups: list<int>, description: string, group_id: int, name: string, notification: string, required_tasks: list<int>>
# operationId: get_opportunities_groups_group_id
export def "get-opportunities-groups-group-id" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/opportunities/groups/{group_id}/"
    path_params: [{name: group_id, var: group_id}]
    query: [{name: datasource, var: datasource}, {name: language, var: language}]
    header: [{name: Accept-Language, var: accept_language}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    group_id: $group_id, datasource: $datasource, language: $language, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get opportunities tasks
#
# GET /opportunities/tasks/
# Returns: list<int>
# operationId: get_opportunities_tasks
export def "get-opportunities-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/opportunities/tasks/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get opportunities task
#
# GET /opportunities/tasks/{task_id}/
# Returns: record<description: string, name: string, notification: string, task_id: int>
# operationId: get_opportunities_tasks_task_id
export def "get-opportunities-tasks-task-id" [
  task_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/opportunities/tasks/{task_id}/"
    path_params: [{name: task_id, var: task_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    task_id: $task_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get route
#
# GET /route/{origin}/{destination}/
# Returns: list<int>
# operationId: get_route_origin_destination
export def "get-route-origin-destination" [
  origin: int
  destination: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --avoid: list<int> # avoid solar system ID(s)
  --connections: list # connected solar system pairs
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --flag: string@flag-completer # route security preference (default: shortest)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/route/{origin}/{destination}/"
    path_params: [{name: origin, var: origin}, {name: destination, var: destination}]
    query: [{name: avoid, var: avoid, style: csv}, {name: connections, var: connections, style: csv}, {name: datasource, var: datasource}, {name: flag, var: flag}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    origin: $origin, destination: $destination, avoid: $avoid, connections: $connections, datasource: $datasource, flag: $flag, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search on a string
#
# GET /search/
# Returns: record<agent: list<int>, alliance: list<int>, character: list<int>, constellation: list<int>, corporation: list<int>, faction: list<int>, inventory_type: list<int>, region: list<int>, solar_system: list<int>, station: list<int>>
# operationId: get_search
export def "get-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list<string> # Type of entities to search for (required)
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --search: string # The string to search on (required)
  --strict: oneof<nothing, bool> # Whether the search should be a strict match (default: false)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/"
    query: [{name: categories, var: categories, style: csv, required: true}, {name: datasource, var: datasource}, {name: language, var: language}, {name: search, var: search, required: true}, {name: strict, var: strict}]
    header: [{name: Accept-Language, var: accept_language}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    categories: $categories, datasource: $datasource, language: $language, search: $search, strict: $strict, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List sovereignty campaigns
#
# GET /sovereignty/campaigns/
# Returns: table<attackers_score: float, campaign_id: int, constellation_id: int, defender_id: int, defender_score: float, event_type: string, participants: list<record>, solar_system_id: int, start_time: string, structure_id: int>
# operationId: get_sovereignty_campaigns
export def "get-sovereignty-campaigns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/sovereignty/campaigns/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List sovereignty of systems
#
# GET /sovereignty/map/
# Returns: table<alliance_id: int, corporation_id: int, faction_id: int, system_id: int>
# operationId: get_sovereignty_map
export def "get-sovereignty-map" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/sovereignty/map/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List sovereignty structures
#
# GET /sovereignty/structures/
# Returns: table<alliance_id: int, solar_system_id: int, structure_id: int, structure_type_id: int, vulnerability_occupancy_level: float, vulnerable_end_time: string, vulnerable_start_time: string>
# operationId: get_sovereignty_structures
export def "get-sovereignty-structures" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/sovereignty/structures/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the uptime and player counts
#
# GET /status/
# Returns: record<players: int, server_version: string, start_time: string, vip: bool>
# operationId: get_status
export def "get-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/status/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set Autopilot Waypoint
#
# POST /ui/autopilot/waypoint/
# operationId: post_ui_autopilot_waypoint
export def "post-ui-autopilot-waypoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-to-beginning: oneof<nothing, bool> # Whether this solar system should be added to the beginning of all waypoints (required, default: false)
  --clear-other-waypoints: oneof<nothing, bool> # Whether clean other waypoints beforing adding this one (required, default: false)
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --destination-id: int # The destination to travel to, can be solar system, station or structure's id (required, format: int64)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
]: nothing -> any {
  http-request {
    method: post
    path: "/ui/autopilot/waypoint/"
    query: [{name: add_to_beginning, var: add_to_beginning, required: true, default: false}, {name: clear_other_waypoints, var: clear_other_waypoints, required: true, default: false}, {name: datasource, var: datasource}, {name: destination_id, var: destination_id, required: true}, {name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    add_to_beginning: $add_to_beginning, clear_other_waypoints: $clear_other_waypoints, datasource: $datasource, destination_id: $destination_id, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Open Contract Window
#
# POST /ui/openwindow/contract/
# operationId: post_ui_openwindow_contract
export def "post-ui-openwindow-contract" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contract-id: int # The contract to open (required, format: int32)
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
]: nothing -> any {
  http-request {
    method: post
    path: "/ui/openwindow/contract/"
    query: [{name: contract_id, var: contract_id, required: true}, {name: datasource, var: datasource}, {name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    contract_id: $contract_id, datasource: $datasource, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Open Information Window
#
# POST /ui/openwindow/information/
# operationId: post_ui_openwindow_information
export def "post-ui-openwindow-information" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --target-id: int # The target to open (required, format: int32)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
]: nothing -> any {
  http-request {
    method: post
    path: "/ui/openwindow/information/"
    query: [{name: datasource, var: datasource}, {name: target_id, var: target_id, required: true}, {name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    datasource: $datasource, target_id: $target_id, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Open Market Details
#
# POST /ui/openwindow/marketdetails/
# operationId: post_ui_openwindow_marketdetails
export def "post-ui-openwindow-marketdetails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --type-id: int # The item type to open in market window (required, format: int32)
]: nothing -> any {
  http-request {
    method: post
    path: "/ui/openwindow/marketdetails/"
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}, {name: type_id, var: type_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    datasource: $datasource, qp_token: $qp_token, type_id: $type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Open New Mail Window
#
# POST /ui/openwindow/newmail/
# operationId: post_ui_openwindow_newmail
export def "post-ui-openwindow-newmail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  body: string # body string
  recipients: list<int> # recipients array
  subject: string # subject string
  --to-corp-or-alliance-id: int # to_corp_or_alliance_id integer (format: int32)
  --to-mailing-list-id: int # Corporations, alliances and mailing lists are all types of mailing groups. You may only send to one mailing group, at a time, so you may fill out either this field or the to_corp_or_alliance_ids field (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/ui/openwindow/newmail/"
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: recipients, var: recipients}, {name: subject, var: subject}, {name: to_corp_or_alliance_id, var: to_corp_or_alliance_id}, {name: to_mailing_list_id, var: to_mailing_list_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    datasource: $datasource, qp_token: $qp_token, body: $body, recipients: $recipients, subject: $subject, to_corp_or_alliance_id: $to_corp_or_alliance_id, to_mailing_list_id: $to_mailing_list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get ancestries
#
# GET /universe/ancestries/
# Returns: table<bloodline_id: int, description: string, icon_id: int, id: int, name: string, short_description: string>
# operationId: get_universe_ancestries
export def "get-universe-ancestries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/universe/ancestries/"
    query: [{name: datasource, var: datasource}, {name: language, var: language}]
    header: [{name: Accept-Language, var: accept_language}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, language: $language, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get asteroid belt information
#
# GET /universe/asteroid_belts/{asteroid_belt_id}/
# Returns: record<name: string, position: record<x: float, y: float, z: float>, system_id: int>
# operationId: get_universe_asteroid_belts_asteroid_belt_id
export def "get-universe-asteroid-belts-asteroid-belt-id" [
  asteroid_belt_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/universe/asteroid_belts/{asteroid_belt_id}/"
    path_params: [{name: asteroid_belt_id, var: asteroid_belt_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    asteroid_belt_id: $asteroid_belt_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get bloodlines
#
# GET /universe/bloodlines/
# Returns: table<bloodline_id: int, charisma: int, corporation_id: int, description: string, intelligence: int, memory: int, name: string, perception: int, race_id: int, ship_type_id: int, willpower: int>
# operationId: get_universe_bloodlines
export def "get-universe-bloodlines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/universe/bloodlines/"
    query: [{name: datasource, var: datasource}, {name: language, var: language}]
    header: [{name: Accept-Language, var: accept_language}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, language: $language, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get item categories
#
# GET /universe/categories/
# Returns: list<int>
# operationId: get_universe_categories
export def "get-universe-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/universe/categories/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get item category information
#
# GET /universe/categories/{category_id}/
# Returns: record<category_id: int, groups: list<int>, name: string, published: bool>
# operationId: get_universe_categories_category_id
export def "get-universe-categories-category-id" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/universe/categories/{category_id}/"
    path_params: [{name: category_id, var: category_id}]
    query: [{name: datasource, var: datasource}, {name: language, var: language}]
    header: [{name: Accept-Language, var: accept_language}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    category_id: $category_id, datasource: $datasource, language: $language, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get constellations
#
# GET /universe/constellations/
# Returns: list<int>
# operationId: get_universe_constellations
export def "get-universe-constellations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/universe/constellations/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get constellation information
#
# GET /universe/constellations/{constellation_id}/
# Returns: record<constellation_id: int, name: string, position: record<x: float, y: float, z: float>, region_id: int, systems: list<int>>
# operationId: get_universe_constellations_constellation_id
export def "get-universe-constellations-constellation-id" [
  constellation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/universe/constellations/{constellation_id}/"
    path_params: [{name: constellation_id, var: constellation_id}]
    query: [{name: datasource, var: datasource}, {name: language, var: language}]
    header: [{name: Accept-Language, var: accept_language}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    constellation_id: $constellation_id, datasource: $datasource, language: $language, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get factions
#
# GET /universe/factions/
# Returns: table<corporation_id: int, description: string, faction_id: int, is_unique: bool, militia_corporation_id: int, name: string, size_factor: float, solar_system_id: int, station_count: int, station_system_count: int>
# operationId: get_universe_factions
export def "get-universe-factions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/universe/factions/"
    query: [{name: datasource, var: datasource}, {name: language, var: language}]
    header: [{name: Accept-Language, var: accept_language}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, language: $language, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get graphics
#
# GET /universe/graphics/
# Returns: list<int>
# operationId: get_universe_graphics
export def "get-universe-graphics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/universe/graphics/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get graphic information
#
# GET /universe/graphics/{graphic_id}/
# Returns: record<collision_file: string, graphic_file: string, graphic_id: int, icon_folder: string, sof_dna: string, sof_fation_name: string, sof_hull_name: string, sof_race_name: string>
# operationId: get_universe_graphics_graphic_id
export def "get-universe-graphics-graphic-id" [
  graphic_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/universe/graphics/{graphic_id}/"
    path_params: [{name: graphic_id, var: graphic_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    graphic_id: $graphic_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get item groups
#
# GET /universe/groups/
# Returns: list<int>
# operationId: get_universe_groups
export def "get-universe-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/universe/groups/"
    query: [{name: datasource, var: datasource}, {name: page, var: page}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, page: $page, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get item group information
#
# GET /universe/groups/{group_id}/
# Returns: record<category_id: int, group_id: int, name: string, published: bool, types: list<int>>
# operationId: get_universe_groups_group_id
export def "get-universe-groups-group-id" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/universe/groups/{group_id}/"
    path_params: [{name: group_id, var: group_id}]
    query: [{name: datasource, var: datasource}, {name: language, var: language}]
    header: [{name: Accept-Language, var: accept_language}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    group_id: $group_id, datasource: $datasource, language: $language, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk names to IDs
#
# POST /universe/ids/
# Returns: record<agents: table<id: int, name: string>, alliances: table<id: int, name: string>, characters: table<id: int, name: string>, constellations: table<id: int, name: string>, corporations: table<id: int, name: string>, factions: table<id: int, name: string>, inventory_types: table<id: int, name: string>, regions: table<id: int, name: string>, stations: table<id: int, name: string>, systems: table<id: int, name: string>>
# operationId: post_universe_ids
export def "post-universe-ids" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/universe/ids/"
    query: [{name: datasource, var: datasource}, {name: language, var: language}]
    header: [{name: Accept-Language, var: accept_language}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    datasource: $datasource, language: $language, accept_language: $accept_language, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get moon information
#
# GET /universe/moons/{moon_id}/
# Returns: record<moon_id: int, name: string, position: record<x: float, y: float, z: float>, system_id: int>
# operationId: get_universe_moons_moon_id
export def "get-universe-moons-moon-id" [
  moon_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/universe/moons/{moon_id}/"
    path_params: [{name: moon_id, var: moon_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    moon_id: $moon_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get names and categories for a set of ID's
#
# POST /universe/names/
# Returns: table<category: string, id: int, name: string>
# operationId: post_universe_names
export def "post-universe-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/universe/names/"
    query: [{name: datasource, var: datasource}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    datasource: $datasource, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get planet information
#
# GET /universe/planets/{planet_id}/
# Returns: record<name: string, planet_id: int, position: record<x: float, y: float, z: float>, system_id: int, type_id: int>
# operationId: get_universe_planets_planet_id
export def "get-universe-planets-planet-id" [
  planet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/universe/planets/{planet_id}/"
    path_params: [{name: planet_id, var: planet_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    planet_id: $planet_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get character races
#
# GET /universe/races/
# Returns: table<alliance_id: int, description: string, name: string, race_id: int>
# operationId: get_universe_races
export def "get-universe-races" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/universe/races/"
    query: [{name: datasource, var: datasource}, {name: language, var: language}]
    header: [{name: Accept-Language, var: accept_language}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, language: $language, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get regions
#
# GET /universe/regions/
# Returns: list<int>
# operationId: get_universe_regions
export def "get-universe-regions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/universe/regions/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get region information
#
# GET /universe/regions/{region_id}/
# Returns: record<constellations: list<int>, description: string, name: string, region_id: int>
# operationId: get_universe_regions_region_id
export def "get-universe-regions-region-id" [
  region_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/universe/regions/{region_id}/"
    path_params: [{name: region_id, var: region_id}]
    query: [{name: datasource, var: datasource}, {name: language, var: language}]
    header: [{name: Accept-Language, var: accept_language}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    region_id: $region_id, datasource: $datasource, language: $language, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get schematic information
#
# GET /universe/schematics/{schematic_id}/
# Returns: record<cycle_time: int, schematic_name: string>
# operationId: get_universe_schematics_schematic_id
export def "get-universe-schematics-schematic-id" [
  schematic_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/universe/schematics/{schematic_id}/"
    path_params: [{name: schematic_id, var: schematic_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    schematic_id: $schematic_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get stargate information
#
# GET /universe/stargates/{stargate_id}/
# Returns: record<destination: record<stargate_id: int, system_id: int>, name: string, position: record<x: float, y: float, z: float>, stargate_id: int, system_id: int, type_id: int>
# operationId: get_universe_stargates_stargate_id
export def "get-universe-stargates-stargate-id" [
  stargate_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/universe/stargates/{stargate_id}/"
    path_params: [{name: stargate_id, var: stargate_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    stargate_id: $stargate_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get star information
#
# GET /universe/stars/{star_id}/
# Returns: record<age: int, luminosity: float, name: string, radius: int, solar_system_id: int, spectral_class: string, temperature: int, type_id: int>
# operationId: get_universe_stars_star_id
export def "get-universe-stars-star-id" [
  star_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/universe/stars/{star_id}/"
    path_params: [{name: star_id, var: star_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    star_id: $star_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get station information
#
# GET /universe/stations/{station_id}/
# Returns: record<max_dockable_ship_volume: float, name: string, office_rental_cost: float, owner: int, position: record<x: float, y: float, z: float>, race_id: int, reprocessing_efficiency: float, reprocessing_stations_take: float, services: list<string>, station_id: int, system_id: int, type_id: int>
# operationId: get_universe_stations_station_id
export def "get-universe-stations-station-id" [
  station_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/universe/stations/{station_id}/"
    path_params: [{name: station_id, var: station_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    station_id: $station_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all public structures
#
# GET /universe/structures/
# Returns: list<int>
# operationId: get_universe_structures
export def "get-universe-structures" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --filter: string@filter-completer # Only list public structures that have this service online
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/universe/structures/"
    query: [{name: datasource, var: datasource}, {name: filter, var: filter}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, filter: $filter, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get structure information
#
# GET /universe/structures/{structure_id}/
# Returns: record<name: string, owner_id: int, position: record<x: float, y: float, z: float>, solar_system_id: int, type_id: int>
# operationId: get_universe_structures_structure_id
export def "get-universe-structures-structure-id" [
  structure_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header (spec name: token)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/universe/structures/{structure_id}/"
    path_params: [{name: structure_id, var: structure_id}]
    query: [{name: datasource, var: datasource}, {name: token, var: qp_token}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    structure_id: $structure_id, datasource: $datasource, qp_token: $qp_token, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get system jumps
#
# GET /universe/system_jumps/
# Returns: table<ship_jumps: int, system_id: int>
# operationId: get_universe_system_jumps
export def "get-universe-system-jumps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/universe/system_jumps/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get system kills
#
# GET /universe/system_kills/
# Returns: table<npc_kills: int, pod_kills: int, ship_kills: int, system_id: int>
# operationId: get_universe_system_kills
export def "get-universe-system-kills" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/universe/system_kills/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get solar systems
#
# GET /universe/systems/
# Returns: list<int>
# operationId: get_universe_systems
export def "get-universe-systems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/universe/systems/"
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get solar system information
#
# GET /universe/systems/{system_id}/
# Returns: record<constellation_id: int, name: string, planets: table<asteroid_belts: list, moons: list, planet_id: int>, position: record<x: float, y: float, z: float>, security_class: string, security_status: float, star_id: int, stargates: list<int>, stations: list<int>, system_id: int>
# operationId: get_universe_systems_system_id
export def "get-universe-systems-system-id" [
  system_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/universe/systems/{system_id}/"
    path_params: [{name: system_id, var: system_id}]
    query: [{name: datasource, var: datasource}, {name: language, var: language}]
    header: [{name: Accept-Language, var: accept_language}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    system_id: $system_id, datasource: $datasource, language: $language, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get types
#
# GET /universe/types/
# Returns: list<int>
# operationId: get_universe_types
export def "get-universe-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/universe/types/"
    query: [{name: datasource, var: datasource}, {name: page, var: page}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, page: $page, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get type information
#
# GET /universe/types/{type_id}/
# Returns: record<capacity: float, description: string, dogma_attributes: table<attribute_id: int, value: float>, dogma_effects: table<effect_id: int, is_default: bool>, graphic_id: int, group_id: int, icon_id: int, market_group_id: int, mass: float, name: string, packaged_volume: float, portion_size: int, published: bool, radius: float, type_id: int, volume: float>
# operationId: get_universe_types_type_id
export def "get-universe-types-type-id" [
  type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response (default: en-us)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/universe/types/{type_id}/"
    path_params: [{name: type_id, var: type_id}]
    query: [{name: datasource, var: datasource}, {name: language, var: language}]
    header: [{name: Accept-Language, var: accept_language}, {name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    type_id: $type_id, datasource: $datasource, language: $language, accept_language: $accept_language, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List wars
#
# GET /wars/
# Returns: list<int>
# operationId: get_wars
export def "get-wars" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --max-war-id: int # Only return wars with ID smaller than this (format: int32)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/wars/"
    query: [{name: datasource, var: datasource}, {name: max_war_id, var: max_war_id}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    datasource: $datasource, max_war_id: $max_war_id, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get war information
#
# GET /wars/{war_id}/
# Returns: record<aggressor: record<alliance_id: int, corporation_id: int, isk_destroyed: float, ships_killed: int>, allies: table<alliance_id: int, corporation_id: int>, declared: string, defender: record<alliance_id: int, corporation_id: int, isk_destroyed: float, ships_killed: int>, finished: string, id: int, mutual: bool, open_for_allies: bool, retracted: string, started: string>
# operationId: get_wars_war_id
export def "get-wars-war-id" [
  war_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/wars/{war_id}/"
    path_params: [{name: war_id, var: war_id}]
    query: [{name: datasource, var: datasource}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    war_id: $war_id, datasource: $datasource, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List kills for a war
#
# GET /wars/{war_id}/killmails/
# Returns: table<killmail_hash: string, killmail_id: int>
# operationId: get_wars_war_id_killmails
export def "get-wars-war-id-killmails" [
  war_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/wars/{war_id}/killmails/"
    path_params: [{name: war_id, var: war_id}]
    query: [{name: datasource, var: datasource}, {name: page, var: page}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    war_id: $war_id, datasource: $datasource, page: $page, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
