# Auto-generated client for POS API v9.3.0
# Source: https://api.apis.guru/v2/specs/apideck.com/pos/9.3.0/openapi.json
# Auth: --token flag or $env.POS_API_TOKEN

const CLIENT = {
  base_url: "https://unify.apideck.com"
  token_env_var: "POS_API_TOKEN"
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

def base-url-completer [] { ["https://unify.apideck.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def price-currency-completer [] { ["AED" "AFN" "ALL" "AMD" "ANG" "AOA" "ARS" "AUD" "AWG" "AZN" "BAM" "BBD" "BDT" "BGN" "BHD" "BIF" "BMD" "BND" "BOB" "BOV" "BRL" "BSD" "BTC" "BTN" "BWP" "BYR" "BZD" "CAD" "CDF" "CHE" "CHF" "CHW" "CLF" "CLP" "CNY" "COP" "COU" "CRC" "CUC" "CUP" "CVE" "CZK" "DJF" "DKK" "DOP" "DZD" "EGP" "ERN" "ETB" "ETH" "EUR" "FJD" "FKP" "GBP" "GEL" "GHS" "GIP" "GMD" "GNF" "GTQ" "GYD" "HKD" "HNL" "HRK" "HTG" "HUF" "IDR" "ILS" "INR" "IQD" "IRR" "ISK" "JMD" "JOD" "JPY" "KES" "KGS" "KHR" "KMF" "KPW" "KRW" "KWD" "KYD" "KZT" "LAK" "LBP" "LKR" "LRD" "LSL" "LTL" "LVL" "LYD" "MAD" "MDL" "MGA" "MKD" "MMK" "MNT" "MOP" "MRO" "MUR" "MVR" "MWK" "MXN" "MXV" "MYR" "MZN" "NAD" "NGN" "NIO" "NOK" "NPR" "NZD" "OMR" "PAB" "PEN" "PGK" "PHP" "PKR" "PLN" "PYG" "QAR" "RON" "RSD" "RUB" "RWF" "SAR" "SBD" "SCR" "SDG" "SEK" "SGD" "SHP" "SLL" "SOS" "SRD" "SSP" "STD" "SVC" "SYP" "SZL" "THB" "TJS" "TMT" "TND" "TOP" "TRC" "TRY" "TTD" "TWD" "TZS" "UAH" "UGX" "UNKNOWN_CURRENCY" "USD" "USN" "USS" "UYI" "UYU" "UZS" "VEF" "VND" "VUV" "WST" "XAF" "XAG" "XAU" "XBA" "XBB" "XBC" "XBD" "XCD" "XDR" "XOF" "XPD" "XPF" "XPT" "XTS" "XXX" "YER" "ZAR" "ZMK" "ZMW"] }
def pricing-type-completer [] { ["fixed" "other" "per_unit" "variable"] }
def product-type-completer [] { ["other" "regular"] }
def currency-completer [] { ["AED" "AFN" "ALL" "AMD" "ANG" "AOA" "ARS" "AUD" "AWG" "AZN" "BAM" "BBD" "BDT" "BGN" "BHD" "BIF" "BMD" "BND" "BOB" "BOV" "BRL" "BSD" "BTC" "BTN" "BWP" "BYR" "BZD" "CAD" "CDF" "CHE" "CHF" "CHW" "CLF" "CLP" "CNY" "COP" "COU" "CRC" "CUC" "CUP" "CVE" "CZK" "DJF" "DKK" "DOP" "DZD" "EGP" "ERN" "ETB" "ETH" "EUR" "FJD" "FKP" "GBP" "GEL" "GHS" "GIP" "GMD" "GNF" "GTQ" "GYD" "HKD" "HNL" "HRK" "HTG" "HUF" "IDR" "ILS" "INR" "IQD" "IRR" "ISK" "JMD" "JOD" "JPY" "KES" "KGS" "KHR" "KMF" "KPW" "KRW" "KWD" "KYD" "KZT" "LAK" "LBP" "LKR" "LRD" "LSL" "LTL" "LVL" "LYD" "MAD" "MDL" "MGA" "MKD" "MMK" "MNT" "MOP" "MRO" "MUR" "MVR" "MWK" "MXN" "MXV" "MYR" "MZN" "NAD" "NGN" "NIO" "NOK" "NPR" "NZD" "OMR" "PAB" "PEN" "PGK" "PHP" "PKR" "PLN" "PYG" "QAR" "RON" "RSD" "RUB" "RWF" "SAR" "SBD" "SCR" "SDG" "SEK" "SGD" "SHP" "SLL" "SOS" "SRD" "SSP" "STD" "SVC" "SYP" "SZL" "THB" "TJS" "TMT" "TND" "TOP" "TRC" "TRY" "TTD" "TWD" "TZS" "UAH" "UGX" "UNKNOWN_CURRENCY" "USD" "USN" "USS" "UYI" "UYU" "UZS" "VEF" "VND" "VUV" "WST" "XAF" "XAG" "XAU" "XBA" "XBB" "XBC" "XBD" "XCD" "XDR" "XOF" "XPD" "XPF" "XPT" "XTS" "XXX" "YER" "ZAR" "ZMK" "ZMW"] }
def status-completer [] { ["active" "inactive" "other"] }
def selection-type-completer [] { ["multiple" "single"] }
def payment-status-completer [] { ["credited" "open" "paid" "partially_paid" "partially_refunded" "refunded" "unknown"] }
def status-completer-1 [] { ["completed" "delayed" "delivered" "draft" "hidden" "open" "voided"] }
def source-completer [] { ["bank_account" "bnpl" "card" "cash" "external" "other" "wallet"] }
def status-completer-2 [] { ["approved" "canceled" "completed" "failed" "other" "pending"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    items-all: "record<data: table<abbreviation: string, absent_at_location_ids: list, available: bool, available_for_pickup: bool, available_online: bool, categories: list, code: string, cost: float, created_at: string, created_by: string, deleted: bool, description: string, hidden: bool, id: string, idempotency_key: string, modifier_groups: list, name: string, options: list, present_at_all_locations: bool, price_amount: float, price_currency: string, pricing_type: string, product_type: string, sku: string, tax_ids: list, updated_at: string, updated_by: string, variations: list, version: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    items-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    items-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    items-one: "record<data: record<abbreviation: string, absent_at_location_ids: list<string>, available: bool, available_for_pickup: bool, available_online: bool, categories: list<record>, code: string, cost: float, created_at: string, created_by: string, deleted: bool, description: string, hidden: bool, id: string, idempotency_key: string, modifier_groups: list<record>, name: string, options: list<record>, present_at_all_locations: bool, price_amount: float, price_currency: string, pricing_type: string, product_type: string, sku: string, tax_ids: list<string>, updated_at: string, updated_by: string, variations: list<record>, version: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    items-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    locations-all: "record<data: table<address: record, business_name: string, created_at: string, created_by: string, currency: string, id: string, merchant_id: string, name: string, status: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    locations-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    locations-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    locations-one: "record<data: record<address: record<city: string, contact_name: string, country: string, county: string, email: string, fax: string, id: string, latitude: string, line1: string, line2: string, line3: string, line4: string, longitude: string, name: string, phone_number: string, postal_code: string, row_version: string, salutation: string, state: string, street_number: string, string: string, type: string, website: string>, business_name: string, created_at: string, created_by: string, currency: string, id: string, merchant_id: string, name: string, status: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    locations-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    merchants-all: "record<data: table<address: record, created_at: string, created_by: string, currency: string, id: string, language: string, main_location_id: string, name: string, owner_id: string, service_charges: list, status: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    merchants-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    merchants-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    merchants-one: "record<data: record<address: record<city: string, contact_name: string, country: string, county: string, email: string, fax: string, id: string, latitude: string, line1: string, line2: string, line3: string, line4: string, longitude: string, name: string, phone_number: string, postal_code: string, row_version: string, salutation: string, state: string, street_number: string, string: string, type: string, website: string>, created_at: string, created_by: string, currency: string, id: string, language: string, main_location_id: string, name: string, owner_id: string, service_charges: list<record>, status: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    merchants-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    modifier-groups-all: "record<data: table<alternate_name: string, created_at: string, created_by: string, deleted: bool, id: string, maximum_allowed: int, minimum_required: int, modifiers: list, name: string, present_at_all_locations: bool, row_version: string, selection_type: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    modifier-groups-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    modifier-groups-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    modifier-groups-one: "record<data: record<alternate_name: string, created_at: string, created_by: string, deleted: bool, id: string, maximum_allowed: int, minimum_required: int, modifiers: list<record>, name: string, present_at_all_locations: bool, row_version: string, selection_type: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    modifier-groups-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    modifiers-all: "record<data: table<alternate_name: string, available: bool, created_at: string, created_by: string, currency: string, id: string, idempotency_key: string, modifier_group_id: string, name: string, price_amount: float, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    modifiers-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    modifiers-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    modifiers-one: "record<data: record<alternate_name: string, available: bool, created_at: string, created_by: string, currency: string, id: string, idempotency_key: string, modifier_group_id: string, name: string, price_amount: float, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    modifiers-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    order-types-all: "record<data: table<created_at: string, created_by: string, default: bool, id: string, name: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    order-types-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    order-types-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    order-types-one: "record<data: record<created_at: string, created_by: string, default: bool, id: string, name: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    order-types-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    orders-all: "record<data: table<closed_date: string, created_at: string, created_by: string, currency: string, customer_id: string, customers: list, discounts: list, employee_id: string, fulfillments: list, id: string, idempotency_key: string, line_items: list, location_id: string, merchant_id: string, note: string, order_date: string, order_number: string, order_type_id: string, payment_status: string, payments: list, reference_id: string, refunded: bool, refunds: list, seat: string, service_charges: list, source: string, status: string, table: string, taxes: list, tenders: list, title: string, total_amount: int, total_discount: int, total_refund: int, total_service_charge: int, total_tax: int, total_tip: int, updated_at: string, updated_by: string, version: string, voided: bool, voided_at: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    orders-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    orders-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    orders-one: "record<data: record<closed_date: string, created_at: string, created_by: string, currency: string, customer_id: string, customers: list<record>, discounts: list<record>, employee_id: string, fulfillments: list<record>, id: string, idempotency_key: string, line_items: list<record>, location_id: string, merchant_id: string, note: string, order_date: string, order_number: string, order_type_id: string, payment_status: string, payments: list<record>, reference_id: string, refunded: bool, refunds: list<record>, seat: string, service_charges: list<record>, source: string, status: string, table: string, taxes: list<record>, tenders: list<record>, title: string, total_amount: int, total_discount: int, total_refund: int, total_service_charge: int, total_tax: int, total_tip: int, updated_at: string, updated_by: string, version: string, voided: bool, voided_at: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    orders-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    orders-pay: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    payments-all: "record<data: table<amount: float, app_fee: float, approved: float, bank_account: record, card_details: record, cash: record, change_back_cash_amount: float, created_at: string, created_by: string, currency: string, customer_id: string, device_id: string, employee_id: string, external_details: record, external_payment_id: string, id: string, idempotency_key: string, location_id: string, merchant_id: string, order_id: string, processing_fees: list, refunded: float, service_charges: list, source: string, source_id: string, status: string, tax: float, tender_id: string, tip: float, total: float, updated_at: string, updated_by: string, wallet: record>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    payments-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    payments-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    payments-one: "record<data: record<amount: float, app_fee: float, approved: float, bank_account: record<account_ownership_type: string, ach_details: record, bank_name: string, country: string, fingerprint: string, statement_description: string, transfer_type: string>, card_details: record<card: record>, cash: record<amount: any, charge_back_amount: any>, change_back_cash_amount: float, created_at: string, created_by: string, currency: string, customer_id: string, device_id: string, employee_id: string, external_details: record<source: string, source_fee_amount: float, source_id: string, type: string>, external_payment_id: string, id: string, idempotency_key: string, location_id: string, merchant_id: string, order_id: string, processing_fees: list<record>, refunded: float, service_charges: list<record>, source: string, source_id: string, status: string, tax: float, tender_id: string, tip: float, total: float, updated_at: string, updated_by: string, wallet: record<status: string>>, operation: string, resource: string, service: string, status: string, status_code: int>"
    payments-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    tenders-all: "record<data: table<active: bool, allows_tipping: bool, created_at: string, created_by: string, editable: bool, hidden: bool, id: string, key: string, label: string, opens_cash_drawer: bool, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    tenders-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    tenders-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    tenders-one: "record<data: record<active: bool, allows_tipping: bool, created_at: string, created_by: string, editable: bool, hidden: bool, id: string, key: string, label: string, opens_cash_drawer: bool, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    tenders-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["items-all" "items-add" "items-delete" "items-one" "items-update" "locations-all" "locations-add" "locations-delete" "locations-one" "locations-update" "merchants-all" "merchants-add" "merchants-delete" "merchants-one" "merchants-update" "modifier-groups-all" "modifier-groups-add" "modifier-groups-delete" "modifier-groups-one" "modifier-groups-update" "modifiers-all" "modifiers-add" "modifiers-delete" "modifiers-one" "modifiers-update" "order-types-all" "order-types-add" "order-types-delete" "order-types-one" "order-types-update" "orders-all" "orders-add" "orders-delete" "orders-one" "orders-update" "orders-pay" "payments-all" "payments-add" "payments-delete" "payments-one" "payments-update" "tenders-all" "tenders-add" "tenders-delete" "tenders-one" "tenders-update" "commands"] | sort) } | get name | first)
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

# List Items
#
# GET /pos/items
# Returns: record<data: table<abbreviation: string, absent_at_location_ids: list, available: bool, available_for_pickup: bool, available_online: bool, categories: list, code: string, cost: float, created_at: string, created_by: string, deleted: bool, description: string, hidden: bool, id: string, idempotency_key: string, modifier_groups: list, name: string, options: list, present_at_all_locations: bool, price_amount: float, price_currency: string, pricing_type: string, product_type: string, sku: string, tax_ids: list, updated_at: string, updated_by: string, variations: list, version: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: itemsAll
export def "items-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pos/items"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Item
#
# POST /pos/items
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: itemsAdd
export def "items-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --abbreviation: string # e.g. Ch
  --absent-at-location-ids: list<string> # A list of locations where the object is not present, even if present_at_all_locations is true. This can include locations that are deactivated. (e.g. [12345, 67890])
  --available: oneof<nothing, bool> # nullable, e.g. true
  --available-for-pickup: oneof<nothing, bool> # e.g. false
  --available-online: oneof<nothing, bool> # e.g. false
  --categories: list # e.g. [{id: 12345, image_ids: [12345, 67890], name: Food}] — item shape: {image_ids?: list<string>, name?: string}
  --code: string # Product code, e.g. UPC or EAN (e.g. 11910345)
  --cost: float # e.g. 2
  --deleted: oneof<nothing, bool> # nullable, e.g. true
  --description: string # e.g. Hot Chocolate
  --hidden: oneof<nothing, bool> # nullable, e.g. true
  --id: string # e.g. #cocoa
  --idempotency-key: string # A value you specify that uniquely identifies this request among requests you have sent. (e.g. random_string)
  --modifier-groups: list # e.g. [{id: 12345}]
  name: string # e.g. Cocoa
  --options: list # List of options pertaining to this item's attribute variation — item shape: {attribute_id?: string, id?: string, name?: string}
  --present-at-all-locations: oneof<nothing, bool> # e.g. false
  --price-amount: float # e.g. 10
  --price-currency: string@price-currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --pricing-type: string@pricing-type-completer # e.g. fixed
  --product-type: string@product-type-completer # e.g. regular
  --sku: string # SKU of the item (e.g. 11910345)
  --tax-ids: list<string> # A list of Tax IDs for the product. (e.g. [12345, 67890])
  --variations: list # e.g. [{id: 12345, image_ids: [12345, 67890], item_id: 12345, name: Food, price_amount: 10, price_currency: USD, pricing_type: fixed, sequence: 0, sku: 11910345}] — item shape: {name?: string, present_at_all_locations?: bool, price_amount?: float, ... (5 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pos/items"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: abbreviation, var: abbreviation}, {name: absent_at_location_ids, var: absent_at_location_ids}, {name: available, var: available}, {name: available_for_pickup, var: available_for_pickup}, {name: available_online, var: available_online}, {name: categories, var: categories}, {name: code, var: code}, {name: cost, var: cost}, {name: deleted, var: deleted}, {name: description, var: description}, {name: hidden, var: hidden}, {name: id, var: id}, {name: idempotency_key, var: idempotency_key}, {name: modifier_groups, var: modifier_groups}, {name: name, var: name}, {name: options, var: options}, {name: present_at_all_locations, var: present_at_all_locations}, {name: price_amount, var: price_amount}, {name: price_currency, var: price_currency}, {name: pricing_type, var: pricing_type}, {name: product_type, var: product_type}, {name: sku, var: sku}, {name: tax_ids, var: tax_ids}, {name: variations, var: variations}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, abbreviation: $abbreviation, absent_at_location_ids: $absent_at_location_ids, available: $available, available_for_pickup: $available_for_pickup, available_online: $available_online, categories: $categories, code: $code, cost: $cost, deleted: $deleted, description: $description, hidden: $hidden, id: $id, idempotency_key: $idempotency_key, modifier_groups: $modifier_groups, name: $name, options: $options, present_at_all_locations: $present_at_all_locations, price_amount: $price_amount, price_currency: $price_currency, pricing_type: $pricing_type, product_type: $product_type, sku: $sku, tax_ids: $tax_ids, variations: $variations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Item
#
# DELETE /pos/items/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: itemsDelete
export def "items-delete" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/pos/items/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Item
#
# GET /pos/items/{id}
# Returns: record<data: record<abbreviation: string, absent_at_location_ids: list<string>, available: bool, available_for_pickup: bool, available_online: bool, categories: list<record>, code: string, cost: float, created_at: string, created_by: string, deleted: bool, description: string, hidden: bool, id: string, idempotency_key: string, modifier_groups: list<record>, name: string, options: list<record>, present_at_all_locations: bool, price_amount: float, price_currency: string, pricing_type: string, product_type: string, sku: string, tax_ids: list<string>, updated_at: string, updated_by: string, variations: list<record>, version: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: itemsOne
export def "items-one" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pos/items/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Item
#
# PATCH /pos/items/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: itemsUpdate
export def "items-update" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --abbreviation: string # e.g. Ch
  --absent-at-location-ids: list<string> # A list of locations where the object is not present, even if present_at_all_locations is true. This can include locations that are deactivated. (e.g. [12345, 67890])
  --available: oneof<nothing, bool> # nullable, e.g. true
  --available-for-pickup: oneof<nothing, bool> # e.g. false
  --available-online: oneof<nothing, bool> # e.g. false
  --categories: list # e.g. [{id: 12345, image_ids: [12345, 67890], name: Food}] — item shape: {image_ids?: list<string>, name?: string}
  --code: string # Product code, e.g. UPC or EAN (e.g. 11910345)
  --cost: float # e.g. 2
  --deleted: oneof<nothing, bool> # nullable, e.g. true
  --description: string # e.g. Hot Chocolate
  --hidden: oneof<nothing, bool> # nullable, e.g. true
  --body-id: string # e.g. #cocoa (spec name: id)
  --idempotency-key: string # A value you specify that uniquely identifies this request among requests you have sent. (e.g. random_string)
  --modifier-groups: list # e.g. [{id: 12345}]
  name: string # e.g. Cocoa
  --options: list # List of options pertaining to this item's attribute variation — item shape: {attribute_id?: string, id?: string, name?: string}
  --present-at-all-locations: oneof<nothing, bool> # e.g. false
  --price-amount: float # e.g. 10
  --price-currency: string@price-currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --pricing-type: string@pricing-type-completer # e.g. fixed
  --product-type: string@product-type-completer # e.g. regular
  --sku: string # SKU of the item (e.g. 11910345)
  --tax-ids: list<string> # A list of Tax IDs for the product. (e.g. [12345, 67890])
  --variations: list # e.g. [{id: 12345, image_ids: [12345, 67890], item_id: 12345, name: Food, price_amount: 10, price_currency: USD, pricing_type: fixed, sequence: 0, sku: 11910345}] — item shape: {name?: string, present_at_all_locations?: bool, price_amount?: float, ... (5 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/pos/items/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: abbreviation, var: abbreviation}, {name: absent_at_location_ids, var: absent_at_location_ids}, {name: available, var: available}, {name: available_for_pickup, var: available_for_pickup}, {name: available_online, var: available_online}, {name: categories, var: categories}, {name: code, var: code}, {name: cost, var: cost}, {name: deleted, var: deleted}, {name: description, var: description}, {name: hidden, var: hidden}, {name: id, var: body_id}, {name: idempotency_key, var: idempotency_key}, {name: modifier_groups, var: modifier_groups}, {name: name, var: name}, {name: options, var: options}, {name: present_at_all_locations, var: present_at_all_locations}, {name: price_amount, var: price_amount}, {name: price_currency, var: price_currency}, {name: pricing_type, var: pricing_type}, {name: product_type, var: product_type}, {name: sku, var: sku}, {name: tax_ids, var: tax_ids}, {name: variations, var: variations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, abbreviation: $abbreviation, absent_at_location_ids: $absent_at_location_ids, available: $available, available_for_pickup: $available_for_pickup, available_online: $available_online, categories: $categories, code: $code, cost: $cost, deleted: $deleted, description: $description, hidden: $hidden, body_id: $body_id, idempotency_key: $idempotency_key, modifier_groups: $modifier_groups, name: $name, options: $options, present_at_all_locations: $present_at_all_locations, price_amount: $price_amount, price_currency: $price_currency, pricing_type: $pricing_type, product_type: $product_type, sku: $sku, tax_ids: $tax_ids, variations: $variations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Locations
#
# GET /pos/locations
# Returns: record<data: table<address: record, business_name: string, created_at: string, created_by: string, currency: string, id: string, merchant_id: string, name: string, status: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: locationsAll
export def "locations-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pos/locations"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Location
#
# POST /pos/locations
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: locationsAdd
export def "locations-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --address: record # shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --business-name: string # The business name of the location (nullable, e.g. Dunkin Donuts LLC)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --merchant-id: string # e.g. 12345
  --name: string # The name of the location (nullable, e.g. Dunkin Donuts)
  --status: string@status-completer # Status of this location. (nullable, e.g. active)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pos/locations"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: business_name, var: business_name}, {name: currency, var: currency}, {name: merchant_id, var: merchant_id}, {name: name, var: name}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, address: $address, business_name: $business_name, currency: $currency, merchant_id: $merchant_id, name: $name, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Location
#
# DELETE /pos/locations/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: locationsDelete
export def "locations-delete" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/pos/locations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Location
#
# GET /pos/locations/{id}
# Returns: record<data: record<address: record<city: string, contact_name: string, country: string, county: string, email: string, fax: string, id: string, latitude: string, line1: string, line2: string, line3: string, line4: string, longitude: string, name: string, phone_number: string, postal_code: string, row_version: string, salutation: string, state: string, street_number: string, string: string, type: string, website: string>, business_name: string, created_at: string, created_by: string, currency: string, id: string, merchant_id: string, name: string, status: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: locationsOne
export def "locations-one" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pos/locations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Location
#
# PATCH /pos/locations/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: locationsUpdate
export def "locations-update" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --address: record # shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --business-name: string # The business name of the location (nullable, e.g. Dunkin Donuts LLC)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --merchant-id: string # e.g. 12345
  --name: string # The name of the location (nullable, e.g. Dunkin Donuts)
  --status: string@status-completer # Status of this location. (nullable, e.g. active)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/pos/locations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: business_name, var: business_name}, {name: currency, var: currency}, {name: merchant_id, var: merchant_id}, {name: name, var: name}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, address: $address, business_name: $business_name, currency: $currency, merchant_id: $merchant_id, name: $name, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Merchants
#
# GET /pos/merchants
# Returns: record<data: table<address: record, created_at: string, created_by: string, currency: string, id: string, language: string, main_location_id: string, name: string, owner_id: string, service_charges: list, status: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: merchantsAll
export def "merchants-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pos/merchants"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Merchant
#
# POST /pos/merchants
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: merchantsAdd
export def "merchants-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --address: record # shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --language: string # language code according to ISO 639-1. For the United States - EN (nullable, e.g. EN)
  --main-location-id: string # The main location ID of the merchant (nullable, e.g. 12345)
  --name: string # The name of the merchant (nullable, e.g. Dunkin Donuts)
  --owner-id: string # e.g. 12345
  --service-charges: list # item shape: {active?: bool, amount?: float, ... (4 more fields)}
  --status: string@status-completer # Status of this merchant. (nullable, e.g. active)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pos/merchants"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: currency, var: currency}, {name: language, var: language}, {name: main_location_id, var: main_location_id}, {name: name, var: name}, {name: owner_id, var: owner_id}, {name: service_charges, var: service_charges}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, address: $address, currency: $currency, language: $language, main_location_id: $main_location_id, name: $name, owner_id: $owner_id, service_charges: $service_charges, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Merchant
#
# DELETE /pos/merchants/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: merchantsDelete
export def "merchants-delete" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/pos/merchants/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Merchant
#
# GET /pos/merchants/{id}
# Returns: record<data: record<address: record<city: string, contact_name: string, country: string, county: string, email: string, fax: string, id: string, latitude: string, line1: string, line2: string, line3: string, line4: string, longitude: string, name: string, phone_number: string, postal_code: string, row_version: string, salutation: string, state: string, street_number: string, string: string, type: string, website: string>, created_at: string, created_by: string, currency: string, id: string, language: string, main_location_id: string, name: string, owner_id: string, service_charges: list<record>, status: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: merchantsOne
export def "merchants-one" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pos/merchants/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Merchant
#
# PATCH /pos/merchants/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: merchantsUpdate
export def "merchants-update" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --address: record # shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --language: string # language code according to ISO 639-1. For the United States - EN (nullable, e.g. EN)
  --main-location-id: string # The main location ID of the merchant (nullable, e.g. 12345)
  --name: string # The name of the merchant (nullable, e.g. Dunkin Donuts)
  --owner-id: string # e.g. 12345
  --service-charges: list # item shape: {active?: bool, amount?: float, ... (4 more fields)}
  --status: string@status-completer # Status of this merchant. (nullable, e.g. active)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/pos/merchants/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: currency, var: currency}, {name: language, var: language}, {name: main_location_id, var: main_location_id}, {name: name, var: name}, {name: owner_id, var: owner_id}, {name: service_charges, var: service_charges}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, address: $address, currency: $currency, language: $language, main_location_id: $main_location_id, name: $name, owner_id: $owner_id, service_charges: $service_charges, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Modifier Groups
#
# GET /pos/modifier-groups
# Returns: record<data: table<alternate_name: string, created_at: string, created_by: string, deleted: bool, id: string, maximum_allowed: int, minimum_required: int, modifiers: list, name: string, present_at_all_locations: bool, row_version: string, selection_type: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: modifierGroupsAll
export def "modifier-groups-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pos/modifier-groups"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Modifier Group
#
# POST /pos/modifier-groups
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: modifierGroupsAdd
export def "modifier-groups-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --alternate-name: string # e.g. Modifier New
  --deleted: oneof<nothing, bool> # nullable, e.g. true
  --maximum-allowed: int # e.g. 5
  --minimum-required: int # e.g. 1
  --modifiers: list # item shape: {alternate_name?: string, available?: bool, ... (4 more fields)}
  --name: string # e.g. Modifier
  --present-at-all-locations: oneof<nothing, bool> # e.g. false
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --selection-type: string@selection-type-completer # e.g. single
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pos/modifier-groups"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternate_name, var: alternate_name}, {name: deleted, var: deleted}, {name: maximum_allowed, var: maximum_allowed}, {name: minimum_required, var: minimum_required}, {name: modifiers, var: modifiers}, {name: name, var: name}, {name: present_at_all_locations, var: present_at_all_locations}, {name: row_version, var: row_version}, {name: selection_type, var: selection_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, alternate_name: $alternate_name, deleted: $deleted, maximum_allowed: $maximum_allowed, minimum_required: $minimum_required, modifiers: $modifiers, name: $name, present_at_all_locations: $present_at_all_locations, row_version: $row_version, selection_type: $selection_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Modifier Group
#
# DELETE /pos/modifier-groups/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: modifierGroupsDelete
export def "modifier-groups-delete" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/pos/modifier-groups/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Modifier Group
#
# GET /pos/modifier-groups/{id}
# Returns: record<data: record<alternate_name: string, created_at: string, created_by: string, deleted: bool, id: string, maximum_allowed: int, minimum_required: int, modifiers: list<record>, name: string, present_at_all_locations: bool, row_version: string, selection_type: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: modifierGroupsOne
export def "modifier-groups-one" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pos/modifier-groups/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Modifier Group
#
# PATCH /pos/modifier-groups/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: modifierGroupsUpdate
export def "modifier-groups-update" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --alternate-name: string # e.g. Modifier New
  --deleted: oneof<nothing, bool> # nullable, e.g. true
  --maximum-allowed: int # e.g. 5
  --minimum-required: int # e.g. 1
  --modifiers: list # item shape: {alternate_name?: string, available?: bool, ... (4 more fields)}
  --name: string # e.g. Modifier
  --present-at-all-locations: oneof<nothing, bool> # e.g. false
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --selection-type: string@selection-type-completer # e.g. single
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/pos/modifier-groups/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternate_name, var: alternate_name}, {name: deleted, var: deleted}, {name: maximum_allowed, var: maximum_allowed}, {name: minimum_required, var: minimum_required}, {name: modifiers, var: modifiers}, {name: name, var: name}, {name: present_at_all_locations, var: present_at_all_locations}, {name: row_version, var: row_version}, {name: selection_type, var: selection_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, alternate_name: $alternate_name, deleted: $deleted, maximum_allowed: $maximum_allowed, minimum_required: $minimum_required, modifiers: $modifiers, name: $name, present_at_all_locations: $present_at_all_locations, row_version: $row_version, selection_type: $selection_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Modifiers
#
# GET /pos/modifiers
# Returns: record<data: table<alternate_name: string, available: bool, created_at: string, created_by: string, currency: string, id: string, idempotency_key: string, modifier_group_id: string, name: string, price_amount: float, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: modifiersAll
export def "modifiers-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pos/modifiers"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Modifier
#
# POST /pos/modifiers
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: modifiersAdd
export def "modifiers-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --alternate-name: string # e.g. Modifier New
  --available: oneof<nothing, bool> # nullable, e.g. true
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --idempotency-key: string # A value you specify that uniquely identifies this request among requests you have sent. (e.g. random_string)
  modifier_group_id: string # e.g. 123
  name: string # e.g. Modifier
  --price-amount: float # e.g. 10
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pos/modifiers"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternate_name, var: alternate_name}, {name: available, var: available}, {name: currency, var: currency}, {name: idempotency_key, var: idempotency_key}, {name: modifier_group_id, var: modifier_group_id}, {name: name, var: name}, {name: price_amount, var: price_amount}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, alternate_name: $alternate_name, available: $available, currency: $currency, idempotency_key: $idempotency_key, modifier_group_id: $modifier_group_id, name: $name, price_amount: $price_amount
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Modifier
#
# DELETE /pos/modifiers/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: modifiersDelete
export def "modifiers-delete" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --filter: record # Apply filters (e.g. {modifier_group_id: 1234})
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/pos/modifiers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: filter, var: filter, style: deepObject}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, filter: $filter, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Modifier
#
# GET /pos/modifiers/{id}
# Returns: record<data: record<alternate_name: string, available: bool, created_at: string, created_by: string, currency: string, id: string, idempotency_key: string, modifier_group_id: string, name: string, price_amount: float, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: modifiersOne
export def "modifiers-one" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --filter: record # Apply filters (e.g. {modifier_group_id: 1234})
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pos/modifiers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: filter, var: filter, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, filter: $filter, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Modifier
#
# PATCH /pos/modifiers/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: modifiersUpdate
export def "modifiers-update" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --alternate-name: string # e.g. Modifier New
  --available: oneof<nothing, bool> # nullable, e.g. true
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --idempotency-key: string # A value you specify that uniquely identifies this request among requests you have sent. (e.g. random_string)
  modifier_group_id: string # e.g. 123
  name: string # e.g. Modifier
  --price-amount: float # e.g. 10
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/pos/modifiers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternate_name, var: alternate_name}, {name: available, var: available}, {name: currency, var: currency}, {name: idempotency_key, var: idempotency_key}, {name: modifier_group_id, var: modifier_group_id}, {name: name, var: name}, {name: price_amount, var: price_amount}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, alternate_name: $alternate_name, available: $available, currency: $currency, idempotency_key: $idempotency_key, modifier_group_id: $modifier_group_id, name: $name, price_amount: $price_amount
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Order Types
#
# GET /pos/order-types
# Returns: record<data: table<created_at: string, created_by: string, default: bool, id: string, name: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: orderTypesAll
export def "order-types-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pos/order-types"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Order Type
#
# POST /pos/order-types
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: orderTypesAdd
export def "order-types-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --default: oneof<nothing, bool> # e.g. true
  --name: string # e.g. Default order type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pos/order-types"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: default, var: default}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, default: $default, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Order Type
#
# DELETE /pos/order-types/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: orderTypesDelete
export def "order-types-delete" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/pos/order-types/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Order Type
#
# GET /pos/order-types/{id}
# Returns: record<data: record<created_at: string, created_by: string, default: bool, id: string, name: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: orderTypesOne
export def "order-types-one" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pos/order-types/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Order Type
#
# PATCH /pos/order-types/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: orderTypesUpdate
export def "order-types-update" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --default: oneof<nothing, bool> # e.g. true
  --name: string # e.g. Default order type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/pos/order-types/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: default, var: default}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, default: $default, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Orders
#
# GET /pos/orders
# Returns: record<data: table<closed_date: string, created_at: string, created_by: string, currency: string, customer_id: string, customers: list, discounts: list, employee_id: string, fulfillments: list, id: string, idempotency_key: string, line_items: list, location_id: string, merchant_id: string, note: string, order_date: string, order_number: string, order_type_id: string, payment_status: string, payments: list, reference_id: string, refunded: bool, refunds: list, seat: string, service_charges: list, source: string, status: string, table: string, taxes: list, tenders: list, title: string, total_amount: int, total_discount: int, total_refund: int, total_service_charge: int, total_tax: int, total_tip: int, updated_at: string, updated_by: string, version: string, voided: bool, voided_at: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: ordersAll
export def "orders-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --location-id: string # ID of the location.
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pos/orders"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: location_id, var: location_id}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, location_id: $location_id, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Order
#
# POST /pos/orders
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: ordersAdd
export def "orders-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --closed-date: string # nullable, format: date, e.g. 2022-08-13
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --customer-id: string # e.g. 12345
  --customers: list # item shape: {emails?: list, first_name?: string, id?: string, last_name?: string, middle_name?: string, phone_numbers?: list}
  --discounts: list # item shape: {amount?: int, ... (4 more fields)}
  --employee-id: string # e.g. 12345
  --fulfillments: list # item shape: {id?: string, pickup_details?: record, shipment_details?: record, status?: "proposed"|"reserved"|"prepared"|"completed"|"cancelled"|"failed"|"other", type?: "pickup"|"shipment"}
  --idempotency-key: string # A value you specify that uniquely identifies this request among requests you have sent. (e.g. random_string)
  --line-items: list # item shape: {applied_discounts?: list, applied_taxes?: list, item?: any, modifiers?: list, name?: string, quantity?: float, total_amount?: int, total_discount?: int, total_tax?: int, unit_price?: float}
  location_id: string # e.g. 12345
  merchant_id: string # e.g. 12345
  --note: string # A note with information about this order, may be printed on the order receipt and displayed in apps
  --order-date: string # nullable, format: date, e.g. 2022-08-12
  --order-number: string # e.g. 1F
  --order-type-id: string # e.g. 12345
  --payment-status: string@payment-status-completer # Is this order paid or not? (e.g. open)
  --payments: list # item shape: {amount?: int, ... (1 more fields)}
  --reference-id: string # An optional user-defined reference ID that associates this record with another entity in an external system. For example, a customer ID from an external customer management system. (nullable, e.g. my-order-001)
  --refunded: oneof<nothing, bool> # e.g. false
  --refunds: list # item shape: {amount?: int, ... (3 more fields)}
  --seat: string # e.g. 23F
  --service-charges: list # Optional service charges or gratuity tip applied to the order. — item shape: {active?: bool, amount?: float, ... (4 more fields)}
  --status: string@status-completer-1 # Order status. Clover specific: If no value is set, the status defaults to hidden, which indicates a hidden order. A hidden order is not displayed in user interfaces and can only be retrieved by its id. When creating an order via the REST API the value must be manually set to 'open'. More info [https://docs.clover.com/reference/orderupdateorder]() (e.g. open)
  --table: string # e.g. 1F
  --taxes: list # item shape: {amount?: int, auto_applied?: bool, ... (6 more fields)}
  --tenders: list # item shape: {amount?: float, buyer_tendered_cash_amount?: int, card?: record, card_entry_method?: "evm"|"swiped"|"keyed"|"on-file"|"contactless", card_status?: "authorized"|"captured"|"failed"|"voided", change_back_cash_amount?: int, ... (12 more fields)}
  --title: string
  --total-amount: int # nullable, e.g. 275
  --total-discount: int # nullable, e.g. 300
  --total-refund: int # nullable, e.g. 0
  --total-service-charge: int # nullable, e.g. 0
  --total-tax: int # nullable, e.g. 275
  --total-tip: int # nullable, e.g. 700
  --version: string # nullable, e.g. 230320320320
  --voided: oneof<nothing, bool> # e.g. false
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pos/orders"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: closed_date, var: closed_date}, {name: currency, var: currency}, {name: customer_id, var: customer_id}, {name: customers, var: customers}, {name: discounts, var: discounts}, {name: employee_id, var: employee_id}, {name: fulfillments, var: fulfillments}, {name: idempotency_key, var: idempotency_key}, {name: line_items, var: line_items}, {name: location_id, var: location_id}, {name: merchant_id, var: merchant_id}, {name: note, var: note}, {name: order_date, var: order_date}, {name: order_number, var: order_number}, {name: order_type_id, var: order_type_id}, {name: payment_status, var: payment_status}, {name: payments, var: payments}, {name: reference_id, var: reference_id}, {name: refunded, var: refunded}, {name: refunds, var: refunds}, {name: seat, var: seat}, {name: service_charges, var: service_charges}, {name: status, var: status}, {name: table, var: table}, {name: taxes, var: taxes}, {name: tenders, var: tenders}, {name: title, var: title}, {name: total_amount, var: total_amount}, {name: total_discount, var: total_discount}, {name: total_refund, var: total_refund}, {name: total_service_charge, var: total_service_charge}, {name: total_tax, var: total_tax}, {name: total_tip, var: total_tip}, {name: version, var: version}, {name: voided, var: voided}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, closed_date: $closed_date, currency: $currency, customer_id: $customer_id, customers: $customers, discounts: $discounts, employee_id: $employee_id, fulfillments: $fulfillments, idempotency_key: $idempotency_key, line_items: $line_items, location_id: $location_id, merchant_id: $merchant_id, note: $note, order_date: $order_date, order_number: $order_number, order_type_id: $order_type_id, payment_status: $payment_status, payments: $payments, reference_id: $reference_id, refunded: $refunded, refunds: $refunds, seat: $seat, service_charges: $service_charges, status: $status, table: $table, taxes: $taxes, tenders: $tenders, title: $title, total_amount: $total_amount, total_discount: $total_discount, total_refund: $total_refund, total_service_charge: $total_service_charge, total_tax: $total_tax, total_tip: $total_tip, version: $version, voided: $voided
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Order
#
# DELETE /pos/orders/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: ordersDelete
export def "orders-delete" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/pos/orders/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Order
#
# GET /pos/orders/{id}
# Returns: record<data: record<closed_date: string, created_at: string, created_by: string, currency: string, customer_id: string, customers: list<record>, discounts: list<record>, employee_id: string, fulfillments: list<record>, id: string, idempotency_key: string, line_items: list<record>, location_id: string, merchant_id: string, note: string, order_date: string, order_number: string, order_type_id: string, payment_status: string, payments: list<record>, reference_id: string, refunded: bool, refunds: list<record>, seat: string, service_charges: list<record>, source: string, status: string, table: string, taxes: list<record>, tenders: list<record>, title: string, total_amount: int, total_discount: int, total_refund: int, total_service_charge: int, total_tax: int, total_tip: int, updated_at: string, updated_by: string, version: string, voided: bool, voided_at: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: ordersOne
export def "orders-one" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pos/orders/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Order
#
# PATCH /pos/orders/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: ordersUpdate
export def "orders-update" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --closed-date: string # nullable, format: date, e.g. 2022-08-13
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --customer-id: string # e.g. 12345
  --customers: list # item shape: {emails?: list, first_name?: string, id?: string, last_name?: string, middle_name?: string, phone_numbers?: list}
  --discounts: list # item shape: {amount?: int, ... (4 more fields)}
  --employee-id: string # e.g. 12345
  --fulfillments: list # item shape: {id?: string, pickup_details?: record, shipment_details?: record, status?: "proposed"|"reserved"|"prepared"|"completed"|"cancelled"|"failed"|"other", type?: "pickup"|"shipment"}
  --idempotency-key: string # A value you specify that uniquely identifies this request among requests you have sent. (e.g. random_string)
  --line-items: list # item shape: {applied_discounts?: list, applied_taxes?: list, item?: any, modifiers?: list, name?: string, quantity?: float, total_amount?: int, total_discount?: int, total_tax?: int, unit_price?: float}
  location_id: string # e.g. 12345
  merchant_id: string # e.g. 12345
  --note: string # A note with information about this order, may be printed on the order receipt and displayed in apps
  --order-date: string # nullable, format: date, e.g. 2022-08-12
  --order-number: string # e.g. 1F
  --order-type-id: string # e.g. 12345
  --payment-status: string@payment-status-completer # Is this order paid or not? (e.g. open)
  --payments: list # item shape: {amount?: int, ... (1 more fields)}
  --reference-id: string # An optional user-defined reference ID that associates this record with another entity in an external system. For example, a customer ID from an external customer management system. (nullable, e.g. my-order-001)
  --refunded: oneof<nothing, bool> # e.g. false
  --refunds: list # item shape: {amount?: int, ... (3 more fields)}
  --seat: string # e.g. 23F
  --service-charges: list # Optional service charges or gratuity tip applied to the order. — item shape: {active?: bool, amount?: float, ... (4 more fields)}
  --status: string@status-completer-1 # Order status. Clover specific: If no value is set, the status defaults to hidden, which indicates a hidden order. A hidden order is not displayed in user interfaces and can only be retrieved by its id. When creating an order via the REST API the value must be manually set to 'open'. More info [https://docs.clover.com/reference/orderupdateorder]() (e.g. open)
  --table: string # e.g. 1F
  --taxes: list # item shape: {amount?: int, auto_applied?: bool, ... (6 more fields)}
  --tenders: list # item shape: {amount?: float, buyer_tendered_cash_amount?: int, card?: record, card_entry_method?: "evm"|"swiped"|"keyed"|"on-file"|"contactless", card_status?: "authorized"|"captured"|"failed"|"voided", change_back_cash_amount?: int, ... (12 more fields)}
  --title: string
  --total-amount: int # nullable, e.g. 275
  --total-discount: int # nullable, e.g. 300
  --total-refund: int # nullable, e.g. 0
  --total-service-charge: int # nullable, e.g. 0
  --total-tax: int # nullable, e.g. 275
  --total-tip: int # nullable, e.g. 700
  --version: string # nullable, e.g. 230320320320
  --voided: oneof<nothing, bool> # e.g. false
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/pos/orders/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: closed_date, var: closed_date}, {name: currency, var: currency}, {name: customer_id, var: customer_id}, {name: customers, var: customers}, {name: discounts, var: discounts}, {name: employee_id, var: employee_id}, {name: fulfillments, var: fulfillments}, {name: idempotency_key, var: idempotency_key}, {name: line_items, var: line_items}, {name: location_id, var: location_id}, {name: merchant_id, var: merchant_id}, {name: note, var: note}, {name: order_date, var: order_date}, {name: order_number, var: order_number}, {name: order_type_id, var: order_type_id}, {name: payment_status, var: payment_status}, {name: payments, var: payments}, {name: reference_id, var: reference_id}, {name: refunded, var: refunded}, {name: refunds, var: refunds}, {name: seat, var: seat}, {name: service_charges, var: service_charges}, {name: status, var: status}, {name: table, var: table}, {name: taxes, var: taxes}, {name: tenders, var: tenders}, {name: title, var: title}, {name: total_amount, var: total_amount}, {name: total_discount, var: total_discount}, {name: total_refund, var: total_refund}, {name: total_service_charge, var: total_service_charge}, {name: total_tax, var: total_tax}, {name: total_tip, var: total_tip}, {name: version, var: version}, {name: voided, var: voided}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, closed_date: $closed_date, currency: $currency, customer_id: $customer_id, customers: $customers, discounts: $discounts, employee_id: $employee_id, fulfillments: $fulfillments, idempotency_key: $idempotency_key, line_items: $line_items, location_id: $location_id, merchant_id: $merchant_id, note: $note, order_date: $order_date, order_number: $order_number, order_type_id: $order_type_id, payment_status: $payment_status, payments: $payments, reference_id: $reference_id, refunded: $refunded, refunds: $refunds, seat: $seat, service_charges: $service_charges, status: $status, table: $table, taxes: $taxes, tenders: $tenders, title: $title, total_amount: $total_amount, total_discount: $total_discount, total_refund: $total_refund, total_service_charge: $total_service_charge, total_tax: $total_tax, total_tip: $total_tip, version: $version, voided: $voided
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pay Order
#
# POST /pos/orders/{id}/pay
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: ordersPay
export def "orders-pay" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --closed-date: string # nullable, format: date, e.g. 2022-08-13
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --customer-id: string # e.g. 12345
  --customers: list # item shape: {emails?: list, first_name?: string, id?: string, last_name?: string, middle_name?: string, phone_numbers?: list}
  --discounts: list # item shape: {amount?: int, ... (4 more fields)}
  --employee-id: string # e.g. 12345
  --fulfillments: list # item shape: {id?: string, pickup_details?: record, shipment_details?: record, status?: "proposed"|"reserved"|"prepared"|"completed"|"cancelled"|"failed"|"other", type?: "pickup"|"shipment"}
  --idempotency-key: string # A value you specify that uniquely identifies this request among requests you have sent. (e.g. random_string)
  --line-items: list # item shape: {applied_discounts?: list, applied_taxes?: list, item?: any, modifiers?: list, name?: string, quantity?: float, total_amount?: int, total_discount?: int, total_tax?: int, unit_price?: float}
  location_id: string # e.g. 12345
  merchant_id: string # e.g. 12345
  --note: string # A note with information about this order, may be printed on the order receipt and displayed in apps
  --order-date: string # nullable, format: date, e.g. 2022-08-12
  --order-number: string # e.g. 1F
  --order-type-id: string # e.g. 12345
  --payment-status: string@payment-status-completer # Is this order paid or not? (e.g. open)
  --payments: list # item shape: {amount?: int, ... (1 more fields)}
  --reference-id: string # An optional user-defined reference ID that associates this record with another entity in an external system. For example, a customer ID from an external customer management system. (nullable, e.g. my-order-001)
  --refunded: oneof<nothing, bool> # e.g. false
  --refunds: list # item shape: {amount?: int, ... (3 more fields)}
  --seat: string # e.g. 23F
  --service-charges: list # Optional service charges or gratuity tip applied to the order. — item shape: {active?: bool, amount?: float, ... (4 more fields)}
  --status: string@status-completer-1 # Order status. Clover specific: If no value is set, the status defaults to hidden, which indicates a hidden order. A hidden order is not displayed in user interfaces and can only be retrieved by its id. When creating an order via the REST API the value must be manually set to 'open'. More info [https://docs.clover.com/reference/orderupdateorder]() (e.g. open)
  --table: string # e.g. 1F
  --taxes: list # item shape: {amount?: int, auto_applied?: bool, ... (6 more fields)}
  --tenders: list # item shape: {amount?: float, buyer_tendered_cash_amount?: int, card?: record, card_entry_method?: "evm"|"swiped"|"keyed"|"on-file"|"contactless", card_status?: "authorized"|"captured"|"failed"|"voided", change_back_cash_amount?: int, ... (12 more fields)}
  --title: string
  --total-amount: int # nullable, e.g. 275
  --total-discount: int # nullable, e.g. 300
  --total-refund: int # nullable, e.g. 0
  --total-service-charge: int # nullable, e.g. 0
  --total-tax: int # nullable, e.g. 275
  --total-tip: int # nullable, e.g. 700
  --version: string # nullable, e.g. 230320320320
  --voided: oneof<nothing, bool> # e.g. false
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pos/orders/{id}/pay"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: closed_date, var: closed_date}, {name: currency, var: currency}, {name: customer_id, var: customer_id}, {name: customers, var: customers}, {name: discounts, var: discounts}, {name: employee_id, var: employee_id}, {name: fulfillments, var: fulfillments}, {name: idempotency_key, var: idempotency_key}, {name: line_items, var: line_items}, {name: location_id, var: location_id}, {name: merchant_id, var: merchant_id}, {name: note, var: note}, {name: order_date, var: order_date}, {name: order_number, var: order_number}, {name: order_type_id, var: order_type_id}, {name: payment_status, var: payment_status}, {name: payments, var: payments}, {name: reference_id, var: reference_id}, {name: refunded, var: refunded}, {name: refunds, var: refunds}, {name: seat, var: seat}, {name: service_charges, var: service_charges}, {name: status, var: status}, {name: table, var: table}, {name: taxes, var: taxes}, {name: tenders, var: tenders}, {name: title, var: title}, {name: total_amount, var: total_amount}, {name: total_discount, var: total_discount}, {name: total_refund, var: total_refund}, {name: total_service_charge, var: total_service_charge}, {name: total_tax, var: total_tax}, {name: total_tip, var: total_tip}, {name: version, var: version}, {name: voided, var: voided}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, closed_date: $closed_date, currency: $currency, customer_id: $customer_id, customers: $customers, discounts: $discounts, employee_id: $employee_id, fulfillments: $fulfillments, idempotency_key: $idempotency_key, line_items: $line_items, location_id: $location_id, merchant_id: $merchant_id, note: $note, order_date: $order_date, order_number: $order_number, order_type_id: $order_type_id, payment_status: $payment_status, payments: $payments, reference_id: $reference_id, refunded: $refunded, refunds: $refunds, seat: $seat, service_charges: $service_charges, status: $status, table: $table, taxes: $taxes, tenders: $tenders, title: $title, total_amount: $total_amount, total_discount: $total_discount, total_refund: $total_refund, total_service_charge: $total_service_charge, total_tax: $total_tax, total_tip: $total_tip, version: $version, voided: $voided
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Payments
#
# GET /pos/payments
# Returns: record<data: table<amount: float, app_fee: float, approved: float, bank_account: record, card_details: record, cash: record, change_back_cash_amount: float, created_at: string, created_by: string, currency: string, customer_id: string, device_id: string, employee_id: string, external_details: record, external_payment_id: string, id: string, idempotency_key: string, location_id: string, merchant_id: string, order_id: string, processing_fees: list, refunded: float, service_charges: list, source: string, source_id: string, status: string, tax: float, tender_id: string, tip: float, total: float, updated_at: string, updated_by: string, wallet: record>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: paymentsAll
export def "payments-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pos/payments"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Payment
#
# POST /pos/payments
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: paymentsAdd
export def "payments-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  amount: float # e.g. 27.5
  --app-fee: float # The amount the developer is taking as a fee for facilitating the payment on behalf of the seller. (e.g. 3)
  --approved: float # The initial amount of money approved for this payment. (e.g. 37.5)
  --bank-account: record # Card details for this payment. This field is currently not available. Reach out to our team for more info. — shape: {account_ownership_type?: string, ach_details?: record, bank_name?: string, country?: string, fingerprint?: string, statement_description?: string, transfer_type?: string}
  --card-details: record # shape: {card?: record}
  --cash: record # Cash details for this payment — shape: {amount?: any, charge_back_amount?: any}
  --change-back-cash-amount: float # e.g. 20
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  customer_id: string # e.g. 12345
  --device-id: string # e.g. 12345
  --employee-id: string # e.g. 12345
  --external-details: record # Details about an external payment. — shape: {source: string, source_fee_amount?: float, source_id?: string, type: "check"|"bank_transfer"|"other_gift_card"|"crypto"|"square_cash"|"social"|"external"|"emoney"|"card"|"stored_balance"|"food_voucher"|"other"}
  --external-payment-id: string # e.g. 12345
  --idempotency-key: string # A value you specify that uniquely identifies this request among requests you have sent. (e.g. random_string)
  --location-id: string # e.g. 12345
  --merchant-id: string # e.g. 12345
  order_id: string # e.g. 12345
  --processing-fees: list # e.g. [{amount: 1.05, effective_at: 2020-09-30T07:43:32.000Z, processing_type: initial}] — item shape: {amount?: float, effective_at?: string, processing_type?: "initial"|"adjustment"}
  --refunded: float # The initial amount of money approved for this payment. (e.g. 37.5)
  --service-charges: list # Optional service charges or gratuity tip applied to the order. — item shape: {active?: bool, amount?: float, ... (4 more fields)}
  --source: string@source-completer # Source of this payment. (e.g. external)
  source_id: string # The ID for the source of funds for this payment. Square-only: This can be a payment token (card nonce) generated by the payment form or a card on file made linked to the customer. if recording a payment that the seller received outside of Square, specify either `CASH` or `EXTERNAL`. (e.g. 12345)
  --status: string@status-completer-2 # Status of this payment. (e.g. approved)
  --tax: float # e.g. 20
  tender_id: string # e.g. 12345
  --tip: float # e.g. 7
  --total: float # e.g. 37.5
  --wallet: record # Wallet details for this payment. This field is currently not available. Reach out to our team for more info. — shape: {status?: "authorized"|"captured"|"voided"|"failed"|"other"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pos/payments"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: app_fee, var: app_fee}, {name: approved, var: approved}, {name: bank_account, var: bank_account}, {name: card_details, var: card_details}, {name: cash, var: cash}, {name: change_back_cash_amount, var: change_back_cash_amount}, {name: currency, var: currency}, {name: customer_id, var: customer_id}, {name: device_id, var: device_id}, {name: employee_id, var: employee_id}, {name: external_details, var: external_details}, {name: external_payment_id, var: external_payment_id}, {name: idempotency_key, var: idempotency_key}, {name: location_id, var: location_id}, {name: merchant_id, var: merchant_id}, {name: order_id, var: order_id}, {name: processing_fees, var: processing_fees}, {name: refunded, var: refunded}, {name: service_charges, var: service_charges}, {name: source, var: source}, {name: source_id, var: source_id}, {name: status, var: status}, {name: tax, var: tax}, {name: tender_id, var: tender_id}, {name: tip, var: tip}, {name: total, var: total}, {name: wallet, var: wallet}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, amount: $amount, app_fee: $app_fee, approved: $approved, bank_account: $bank_account, card_details: $card_details, cash: $cash, change_back_cash_amount: $change_back_cash_amount, currency: $currency, customer_id: $customer_id, device_id: $device_id, employee_id: $employee_id, external_details: $external_details, external_payment_id: $external_payment_id, idempotency_key: $idempotency_key, location_id: $location_id, merchant_id: $merchant_id, order_id: $order_id, processing_fees: $processing_fees, refunded: $refunded, service_charges: $service_charges, source: $source, source_id: $source_id, status: $status, tax: $tax, tender_id: $tender_id, tip: $tip, total: $total, wallet: $wallet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Payment
#
# DELETE /pos/payments/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: paymentsDelete
export def "payments-delete" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/pos/payments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Payment
#
# GET /pos/payments/{id}
# Returns: record<data: record<amount: float, app_fee: float, approved: float, bank_account: record<account_ownership_type: string, ach_details: record, bank_name: string, country: string, fingerprint: string, statement_description: string, transfer_type: string>, card_details: record<card: record>, cash: record<amount: any, charge_back_amount: any>, change_back_cash_amount: float, created_at: string, created_by: string, currency: string, customer_id: string, device_id: string, employee_id: string, external_details: record<source: string, source_fee_amount: float, source_id: string, type: string>, external_payment_id: string, id: string, idempotency_key: string, location_id: string, merchant_id: string, order_id: string, processing_fees: list<record>, refunded: float, service_charges: list<record>, source: string, source_id: string, status: string, tax: float, tender_id: string, tip: float, total: float, updated_at: string, updated_by: string, wallet: record<status: string>>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: paymentsOne
export def "payments-one" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pos/payments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Payment
#
# PATCH /pos/payments/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: paymentsUpdate
export def "payments-update" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  amount: float # e.g. 27.5
  --app-fee: float # The amount the developer is taking as a fee for facilitating the payment on behalf of the seller. (e.g. 3)
  --approved: float # The initial amount of money approved for this payment. (e.g. 37.5)
  --bank-account: record # Card details for this payment. This field is currently not available. Reach out to our team for more info. — shape: {account_ownership_type?: string, ach_details?: record, bank_name?: string, country?: string, fingerprint?: string, statement_description?: string, transfer_type?: string}
  --card-details: record # shape: {card?: record}
  --cash: record # Cash details for this payment — shape: {amount?: any, charge_back_amount?: any}
  --change-back-cash-amount: float # e.g. 20
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  customer_id: string # e.g. 12345
  --device-id: string # e.g. 12345
  --employee-id: string # e.g. 12345
  --external-details: record # Details about an external payment. — shape: {source: string, source_fee_amount?: float, source_id?: string, type: "check"|"bank_transfer"|"other_gift_card"|"crypto"|"square_cash"|"social"|"external"|"emoney"|"card"|"stored_balance"|"food_voucher"|"other"}
  --external-payment-id: string # e.g. 12345
  --idempotency-key: string # A value you specify that uniquely identifies this request among requests you have sent. (e.g. random_string)
  --location-id: string # e.g. 12345
  --merchant-id: string # e.g. 12345
  order_id: string # e.g. 12345
  --processing-fees: list # e.g. [{amount: 1.05, effective_at: 2020-09-30T07:43:32.000Z, processing_type: initial}] — item shape: {amount?: float, effective_at?: string, processing_type?: "initial"|"adjustment"}
  --refunded: float # The initial amount of money approved for this payment. (e.g. 37.5)
  --service-charges: list # Optional service charges or gratuity tip applied to the order. — item shape: {active?: bool, amount?: float, ... (4 more fields)}
  --source: string@source-completer # Source of this payment. (e.g. external)
  source_id: string # The ID for the source of funds for this payment. Square-only: This can be a payment token (card nonce) generated by the payment form or a card on file made linked to the customer. if recording a payment that the seller received outside of Square, specify either `CASH` or `EXTERNAL`. (e.g. 12345)
  --status: string@status-completer-2 # Status of this payment. (e.g. approved)
  --tax: float # e.g. 20
  tender_id: string # e.g. 12345
  --tip: float # e.g. 7
  --total: float # e.g. 37.5
  --wallet: record # Wallet details for this payment. This field is currently not available. Reach out to our team for more info. — shape: {status?: "authorized"|"captured"|"voided"|"failed"|"other"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/pos/payments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: app_fee, var: app_fee}, {name: approved, var: approved}, {name: bank_account, var: bank_account}, {name: card_details, var: card_details}, {name: cash, var: cash}, {name: change_back_cash_amount, var: change_back_cash_amount}, {name: currency, var: currency}, {name: customer_id, var: customer_id}, {name: device_id, var: device_id}, {name: employee_id, var: employee_id}, {name: external_details, var: external_details}, {name: external_payment_id, var: external_payment_id}, {name: idempotency_key, var: idempotency_key}, {name: location_id, var: location_id}, {name: merchant_id, var: merchant_id}, {name: order_id, var: order_id}, {name: processing_fees, var: processing_fees}, {name: refunded, var: refunded}, {name: service_charges, var: service_charges}, {name: source, var: source}, {name: source_id, var: source_id}, {name: status, var: status}, {name: tax, var: tax}, {name: tender_id, var: tender_id}, {name: tip, var: tip}, {name: total, var: total}, {name: wallet, var: wallet}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, amount: $amount, app_fee: $app_fee, approved: $approved, bank_account: $bank_account, card_details: $card_details, cash: $cash, change_back_cash_amount: $change_back_cash_amount, currency: $currency, customer_id: $customer_id, device_id: $device_id, employee_id: $employee_id, external_details: $external_details, external_payment_id: $external_payment_id, idempotency_key: $idempotency_key, location_id: $location_id, merchant_id: $merchant_id, order_id: $order_id, processing_fees: $processing_fees, refunded: $refunded, service_charges: $service_charges, source: $source, source_id: $source_id, status: $status, tax: $tax, tender_id: $tender_id, tip: $tip, total: $total, wallet: $wallet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Tenders
#
# GET /pos/tenders
# Returns: record<data: table<active: bool, allows_tipping: bool, created_at: string, created_by: string, editable: bool, hidden: bool, id: string, key: string, label: string, opens_cash_drawer: bool, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: tendersAll
export def "tenders-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pos/tenders"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Tender
#
# POST /pos/tenders
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: tendersAdd
export def "tenders-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --active: oneof<nothing, bool> # nullable, e.g. true
  --allows-tipping: oneof<nothing, bool> # Allow tipping on payment from tender (default: true)
  --editable: oneof<nothing, bool> # nullable, e.g. true
  --hidden: oneof<nothing, bool> # nullable, e.g. true
  --key: string # nullable, e.g. com.clover.tender.cash
  --label: string # nullable, e.g. Cash
  --opens-cash-drawer: oneof<nothing, bool> # If this tender opens the cash drawer (default: true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pos/tenders"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: allows_tipping, var: allows_tipping}, {name: editable, var: editable}, {name: hidden, var: hidden}, {name: key, var: key}, {name: label, var: label}, {name: opens_cash_drawer, var: opens_cash_drawer}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, active: $active, allows_tipping: $allows_tipping, editable: $editable, hidden: $hidden, key: $key, label: $label, opens_cash_drawer: $opens_cash_drawer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Tender
#
# DELETE /pos/tenders/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: tendersDelete
export def "tenders-delete" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/pos/tenders/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Tender
#
# GET /pos/tenders/{id}
# Returns: record<data: record<active: bool, allows_tipping: bool, created_at: string, created_by: string, editable: bool, hidden: bool, id: string, key: string, label: string, opens_cash_drawer: bool, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: tendersOne
export def "tenders-one" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pos/tenders/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Tender
#
# PATCH /pos/tenders/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: tendersUpdate
export def "tenders-update" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --active: oneof<nothing, bool> # nullable, e.g. true
  --allows-tipping: oneof<nothing, bool> # Allow tipping on payment from tender (default: true)
  --editable: oneof<nothing, bool> # nullable, e.g. true
  --hidden: oneof<nothing, bool> # nullable, e.g. true
  --key: string # nullable, e.g. com.clover.tender.cash
  --label: string # nullable, e.g. Cash
  --opens-cash-drawer: oneof<nothing, bool> # If this tender opens the cash drawer (default: true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/pos/tenders/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: allows_tipping, var: allows_tipping}, {name: editable, var: editable}, {name: hidden, var: hidden}, {name: key, var: key}, {name: label, var: label}, {name: opens_cash_drawer, var: opens_cash_drawer}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, active: $active, allows_tipping: $allows_tipping, editable: $editable, hidden: $hidden, key: $key, label: $label, opens_cash_drawer: $opens_cash_drawer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
