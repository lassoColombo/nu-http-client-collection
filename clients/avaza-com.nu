# Auto-generated client for Avaza API Documentation v1
# Source: https://api.apis.guru/v2/specs/avaza.com/v1/swagger.json
# Auth: --token flag or $env.AVAZA_API_DOCUMENTATION_TOKEN

const CLIENT = {
  base_url: "https://api.avaza.com"
  token_env_var: "AVAZA_API_DOCUMENTATION_TOKEN"
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

def base-url-completer [] { ["https://api.avaza.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    schedule-series-add-booking: "record<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int>"
    schedule-series-add-leave: "record<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int>"
    schedule-series-edit-booking: "record<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int>"
    schedule-series-edit-leave: "record<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int>"
    account-get: "record<AccountEmail: string, AccountID: int, AllowHidingCompletedTasksOnTimesheet: bool, BrandPrimaryColor: string, BrandPrimaryColorLuminance: string, CompanyName: string, CurrentServerTimeISO: string, DefaultCurrencyCode: string, ExpenseApprovalRequired: bool, LockApprovedExpenses: bool, LockApprovedTimesheets: bool, SC: string, Subdomain: string, TimesheetDayOfWeek: int, TimesheetDisplayFormatCode: string, WeeklyTimesheetReminder: bool, has24HourTimesheetFormat: bool, hasStartEndTimesheets: bool>"
    bill-get: "record<Bills: table<AccountIDFK: int, Balance: float, BillNumber: string, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, DateVerified: string, DueDate: string, ExchangeRate: float, Issuer: record, LineItems: list, Links: record, Notes: string, Recipient: record, Subject: string, SupplierPONumber: string, TaxAmount: float, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string, TransactionTaxConfigCode: string>, PageNumber: int, PageSize: int, TotalCount: int>"
    bill-post: "record<AccountIDFK: int, Balance: float, BillNumber: string, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, DateVerified: string, DueDate: string, ExchangeRate: float, Issuer: record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, CompanyIDFK: int, CompanyName: string>, LineItems: table<Amount: float, Description: string, Discount: float, InventoryItemIDFK: int, InventoryItemName: string, InventoryItemSKU: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaxAmount: float, TaxCode: string, TaxIDFK: int, TaxName: string, TransactionLineItemID: int, UnitPrice: float>, Links: record<Edit: string, View: string, WebView: string>, Notes: string, Recipient: record<RecipientBillingAddressCity: string, RecipientBillingAddressCountryCode: string, RecipientBillingAddressLine: string, RecipientBillingAddressPostCode: string, RecipientBillingAddressState: string, RecipientFormattedBillingAddress: string>, Subject: string, SupplierPONumber: string, TaxAmount: float, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string, TransactionTaxConfigCode: string>"
    bill-payment-get: "record<PageNumber: int, PageSize: int, Payments: table<AccountIDFK: int, Balance: float, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: list, PaymentNumber: string, PaymentProviderCode: string, SupplierIDFK: int, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string>, TotalCount: int>"
    bill-payment-post: "record<AccountIDFK: int, Balance: float, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: table<AllocationAmount: float, AllocationDate: string, BillTransactionIDFK: int, PaymentTransactionIDFK: int, TransactionAllocationID: int>, PaymentNumber: string, PaymentProviderCode: string, SupplierIDFK: int, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string>"
    bill-payment-get-by-id: "record<AccountIDFK: int, Balance: float, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: table<AllocationAmount: float, AllocationDate: string, BillTransactionIDFK: int, PaymentTransactionIDFK: int, TransactionAllocationID: int>, PaymentNumber: string, PaymentProviderCode: string, SupplierIDFK: int, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string>"
    company-get: "record<Companies: table<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, Comments: string, CompanyID: int, CompanyName: string, Contacts: list, CurrencyCode: string, DateCreated: string, DateUpdated: string, DefaultTradingTermIDFK: int, Fax: string, Phone: string, TaxNumber: string, website: string>, PageNumber: int, PageSize: int, TotalCount: int>"
    company-post: "record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, Comments: string, CompanyID: int, CompanyName: string, Contacts: table<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>, CurrencyCode: string, DateCreated: string, DateUpdated: string, DefaultTradingTermIDFK: int, Fax: string, Phone: string, TaxNumber: string, website: string>"
    company-put: "record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, Comments: string, CompanyID: int, CompanyName: string, Contacts: table<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>, CurrencyCode: string, DateCreated: string, DateUpdated: string, DefaultTradingTermIDFK: int, Fax: string, Phone: string, TaxNumber: string, website: string>"
    company-lookup: "record<Companies: table<CompanyID: int, CompanyName: string>, PageNumber: int, PageSize: int, TotalCount: int>"
    company-get-by-id: "record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, Comments: string, CompanyID: int, CompanyName: string, Contacts: table<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>, CurrencyCode: string, DateCreated: string, DateUpdated: string, DefaultTradingTermIDFK: int, Fax: string, Phone: string, TaxNumber: string, website: string>"
    contact-get: "record<Contacts: table<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>, PageNumber: int, PageSize: int, TotalCount: int>"
    contact-post: "record<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>"
    contact-get-by-id: "record<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>"
    credit-note-get: "record<CreditNotes: table<Balance: float, CreditNoteAllocations: list, CreditNoteLineItems: list, CreditNoteNumber: string, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, Notes: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string>, PageNumber: int, PageSize: int, TotalCount: int>"
    credit-note-get-by-id: "record<Balance: float, CreditNoteAllocations: table<AllocationAmount: float, AllocationDate: string, CreditNoteTransactionIDFK: int, InvoiceTransactionIDFK: int, TransactionAllocationID: int>, CreditNoteLineItems: table<Amount: float, Description: string, Discount: float, Quantity: float, TaxAmount: float, TaxIDFK: int, TransactionLineItemID: int, UnitPrice: float>, CreditNoteNumber: string, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, Notes: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string>"
    currency-get: "record<Currencies: table<CurrencyCode: string, DecimalPlaces: int, Name: string, Symbol: string, Symbol2: string>>"
    estimate-get: "record<Estimates: table<AccountIDFK: int, Balance: float, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, DateCreated: string, DateIssued: string, DateSent: string, DateUpdated: string, DueDate: string, EstimateID: int, EstimateItemNumber: string, EstimatePrefix: string, EstimateStatusCode: string, EstimateTaxConfigCode: string, ExchangeRate: float, Issuer: record, LineItems: list, Links: record, Notes: string, Recipient: record, Subject: string, TaxAmount: float, TotalAmount: float>, PageNumber: int, PageSize: int, TotalCount: int>"
    estimate-post: "record<AccountIDFK: int, Balance: float, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, DateCreated: string, DateIssued: string, DateSent: string, DateUpdated: string, DueDate: string, EstimateID: int, EstimateItemNumber: string, EstimatePrefix: string, EstimateStatusCode: string, EstimateTaxConfigCode: string, ExchangeRate: float, Issuer: record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, TaxNumber: string>, LineItems: table<Amount: float, Description: string, Discount: float, EstimateLineItemID: int, InventoryItemIDFK: int, InventoryItemName: string, InventoryItemSKU: string, Quantity: float, TaxAmount: float, TaxCode: string, TaxIDFK: int, TaxName: string, UnitPrice: float>, Links: record<ClientView: string, Edit: string, View: string>, Notes: string, Recipient: record<CompanyIDFK: int, CompanyName: string, RecipientBillingAddressCity: string, RecipientBillingAddressCountryCode: string, RecipientBillingAddressLine: string, RecipientBillingAddressPostCode: string, RecipientBillingAddressState: string, RecipientFormattedBillingAddress: string>, Subject: string, TaxAmount: float, TotalAmount: float>"
    expense-delete: "record<Results: table<ErrorMessage: string, ExpenseID: int, Success: bool>>"
    expense-get: "record<Expenses: table<Amount: float, AttachmentPreviewURL: string, AttachmentURL: string, ChargeableStatusCode: string, CurrencyCode: string, CustomerIDFK: int, CustomerName: string, DateCreated: string, DateUpdated: string, Email: string, ExchangeRate: float, ExpenseApprovalStatusCode: string, ExpenseCategoryHasUnitPrice: bool, ExpenseCategoryIDFK: int, ExpenseCategoryName: string, ExpenseCategoryUnitName: string, ExpenseCategoryUnitPrice: float, ExpenseDate: string, ExpenseID: int, ExpensePaymentMethodIDFK: int, ExpensePaymentMethodName: string, ExpenseReimbursementIDFK: int, ExpenseReimbursementStatusCode: string, ExpenseReportIDFK: int, ExpenseReportName: string, FileAttachmentIDFK: int, Firstname: string, Lastname: string, Merchant: string, MerchantTaxNumber: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaskIDFK: int, TaskTitle: string, TaxAmount: float, TaxIDFK: int, TaxName: string, TransactionTaxConfigCode: string, TransactionTaxConfigName: string, UserIDFK: int, isChargeable: bool, isOfficialExchangeRate: bool, isReimbursable: bool>, PageNumber: int, PageSize: int, TotalCount: int>"
    expense-post: "record<Amount: float, AttachmentPreviewURL: string, AttachmentURL: string, ChargeableStatusCode: string, CurrencyCode: string, CustomerIDFK: int, CustomerName: string, DateCreated: string, DateUpdated: string, Email: string, ExchangeRate: float, ExpenseApprovalStatusCode: string, ExpenseCategoryHasUnitPrice: bool, ExpenseCategoryIDFK: int, ExpenseCategoryName: string, ExpenseCategoryUnitName: string, ExpenseCategoryUnitPrice: float, ExpenseDate: string, ExpenseID: int, ExpensePaymentMethodIDFK: int, ExpensePaymentMethodName: string, ExpenseReimbursementIDFK: int, ExpenseReimbursementStatusCode: string, ExpenseReportIDFK: int, ExpenseReportName: string, FileAttachmentIDFK: int, Firstname: string, Lastname: string, Merchant: string, MerchantTaxNumber: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaskIDFK: int, TaskTitle: string, TaxAmount: float, TaxIDFK: int, TaxName: string, TransactionTaxConfigCode: string, TransactionTaxConfigName: string, UserIDFK: int, isChargeable: bool, isOfficialExchangeRate: bool, isReimbursable: bool>"
    expense-put: "record<Amount: float, AttachmentPreviewURL: string, AttachmentURL: string, ChargeableStatusCode: string, CurrencyCode: string, CustomerIDFK: int, CustomerName: string, DateCreated: string, DateUpdated: string, Email: string, ExchangeRate: float, ExpenseApprovalStatusCode: string, ExpenseCategoryHasUnitPrice: bool, ExpenseCategoryIDFK: int, ExpenseCategoryName: string, ExpenseCategoryUnitName: string, ExpenseCategoryUnitPrice: float, ExpenseDate: string, ExpenseID: int, ExpensePaymentMethodIDFK: int, ExpensePaymentMethodName: string, ExpenseReimbursementIDFK: int, ExpenseReimbursementStatusCode: string, ExpenseReportIDFK: int, ExpenseReportName: string, FileAttachmentIDFK: int, Firstname: string, Lastname: string, Merchant: string, MerchantTaxNumber: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaskIDFK: int, TaskTitle: string, TaxAmount: float, TaxIDFK: int, TaxName: string, TransactionTaxConfigCode: string, TransactionTaxConfigName: string, UserIDFK: int, isChargeable: bool, isOfficialExchangeRate: bool, isReimbursable: bool>"
    expense-attachment: "record<FileAttachments: table<FileAttachmentID: int, OriginalFilename: string, PreviewBaseURL: string, PublicFileURL: string, SizeBytes: int>>"
    expense-get-by-id: "record<Amount: float, AttachmentPreviewURL: string, AttachmentURL: string, ChargeableStatusCode: string, CurrencyCode: string, CustomerIDFK: int, CustomerName: string, DateCreated: string, DateUpdated: string, Email: string, ExchangeRate: float, ExpenseApprovalStatusCode: string, ExpenseCategoryHasUnitPrice: bool, ExpenseCategoryIDFK: int, ExpenseCategoryName: string, ExpenseCategoryUnitName: string, ExpenseCategoryUnitPrice: float, ExpenseDate: string, ExpenseID: int, ExpensePaymentMethodIDFK: int, ExpensePaymentMethodName: string, ExpenseReimbursementIDFK: int, ExpenseReimbursementStatusCode: string, ExpenseReportIDFK: int, ExpenseReportName: string, FileAttachmentIDFK: int, Firstname: string, Lastname: string, Merchant: string, MerchantTaxNumber: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaskIDFK: int, TaskTitle: string, TaxAmount: float, TaxIDFK: int, TaxName: string, TransactionTaxConfigCode: string, TransactionTaxConfigName: string, UserIDFK: int, isChargeable: bool, isOfficialExchangeRate: bool, isReimbursable: bool>"
    expense-approval: "record"
    expense-category-get: "record<Categories: table<Enabled: bool, ExpenseCategoryID: int, Name: string, UnitName: string, UnitPrice: float, hasUnitPrice: bool>>"
    expense-group-lookup: "record<ExpenseGroups: table<ExpenseGroupID: int, Name: string>, PageNumber: int, PageSize: int, TotalCount: int>"
    expense-merchange-lookup: "record<ExpenseMerchants: table<MerchantName: string>, PageNumber: int, PageSize: int, TotalCount: int>"
    expense-payment-method-lookup: "record<ExpensePaymentMethods: table<ExpensePaymentMethodID: int, Name: string>>"
    expense-summary-get: "record<ExpenseDateFrom: string, ExpenseDateTo: string, GroupData: table<GroupData: list, GroupID: string, GroupName: string, TotalAmount: float>, GroupingLevels: list<string>, TotalAmount: float, UserID: list<int>>"
    fixed-amount-get: "record<FixedAmounts: table<Amount: float, DateCreated: string, DateUpdated: string, FixedAmountID: int, InventoryItemIDFK: int, InventoryItemName: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, TaskIDFK: int, TaskTitle: string, UpdatedByUserIDFK: int, isInvoiced: bool>, PageNumber: int, PageSize: int, TotalCount: int>"
    inventory-get: "record<Inventory: table<CostPrice: float, DateCreated: string, DateUpdated: string, Description: string, InventoryItemID: int, Name: string, SKU: string, SalePrice: float, SaleTaxIDFK: int, isHidden: bool>, PageNumber: int, PageSize: int, TotalCount: int>"
    invoice-get: "record<Invoices: table<AccountIDFK: int, Balance: float, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, CustomerPONumber: string, DateCreated: string, DateIssued: string, DateSent: string, DateUpdated: string, DueDate: string, ExchangeRate: float, InvoiceNumber: string, Issuer: record, LineItems: list, Links: record, Notes: string, Recipient: record, Subject: string, TaxAmount: float, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string, TransactionTaxConfigCode: string>, PageNumber: int, PageSize: int, TotalCount: int>"
    invoice-post: "record<AccountIDFK: int, Balance: float, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, CustomerPONumber: string, DateCreated: string, DateIssued: string, DateSent: string, DateUpdated: string, DueDate: string, ExchangeRate: float, InvoiceNumber: string, Issuer: record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, TaxNumber: string>, LineItems: table<Amount: float, Description: string, Discount: float, InventoryItemIDFK: int, InventoryItemName: string, InventoryItemSKU: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaxAmount: float, TaxCode: string, TaxIDFK: int, TaxName: string, TransactionLineItemID: int, UnitPrice: float>, Links: record<ClientView: string, Edit: string, View: string>, Notes: string, Recipient: record<CompanyIDFK: int, CompanyName: string, RecipientBillingAddressCity: string, RecipientBillingAddressCountryCode: string, RecipientBillingAddressLine: string, RecipientBillingAddressPostCode: string, RecipientBillingAddressState: string, RecipientFormattedBillingAddress: string>, Subject: string, TaxAmount: float, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string, TransactionTaxConfigCode: string>"
    payment-get: "record<PageNumber: int, PageSize: int, Payments: table<AccountIDFK: int, Balance: float, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: list, PaymentNumber: string, PaymentProviderCode: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string>, TotalCount: int>"
    payment-post: "record<AccountIDFK: int, Balance: float, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: table<AllocationAmount: float, AllocationDate: string, InvoiceTransactionIDFK: int, PaymentTransactionIDFK: int, TransactionAllocationID: int>, PaymentNumber: string, PaymentProviderCode: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string>"
    payment-get-by-id: "record<AccountIDFK: int, Balance: float, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: table<AllocationAmount: float, AllocationDate: string, InvoiceTransactionIDFK: int, PaymentTransactionIDFK: int, TransactionAllocationID: int>, PaymentNumber: string, PaymentProviderCode: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string>"
    project-get: "record<PageNumber: int, PageSize: int, Projects: table<CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, DefaultAccountTaskTypeIDFK: int, DefaultAccountTaskTypeName: string, Notes: string, ProjectCategoryIDFK: int, ProjectCategoryName: string, ProjectCode: string, ProjectID: int, ProjectOwnerUserIDFK: int, Title: string, isArchived: bool, isTaskRequiredOnTimesheet: bool>, TotalCount: int>"
    project-post: "record<BudgetAmount: float, BudgetHours: float, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, DefaultAccountTaskTypeIDFK: int, DefaultAccountTaskTypeName: string, EndDate: string, Members: table<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>, Notes: string, ProjectBillableTypeCode: string, ProjectBudgetTypeCode: string, ProjectCategoryColor: string, ProjectCategoryIDFK: int, ProjectCategoryName: string, ProjectCode: string, ProjectHourlyRate: float, ProjectID: int, ProjectOwnerUserIDFK: int, ProjectStatusCode: string, ProjectTags: table<Name: string, ProjectTagID: int>, Sections: table<DisplayOrder: int, EndDate: string, SectionID: int, StartDate: string, Title: string>, StartDate: string, Title: string, isArchived: bool, isTaskRequiredOnTimesheet: bool>"
    project-put: "record<BudgetAmount: float, BudgetHours: float, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, DefaultAccountTaskTypeIDFK: int, DefaultAccountTaskTypeName: string, EndDate: string, Members: table<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>, Notes: string, ProjectBillableTypeCode: string, ProjectBudgetTypeCode: string, ProjectCategoryColor: string, ProjectCategoryIDFK: int, ProjectCategoryName: string, ProjectCode: string, ProjectHourlyRate: float, ProjectID: int, ProjectOwnerUserIDFK: int, ProjectStatusCode: string, ProjectTags: table<Name: string, ProjectTagID: int>, Sections: table<DisplayOrder: int, EndDate: string, SectionID: int, StartDate: string, Title: string>, StartDate: string, Title: string, isArchived: bool, isTaskRequiredOnTimesheet: bool>"
    project-lookup: "record<PageSize: int, companies: table<CompanyID: int, CompanyName: string, projects: list>, hasMore: bool, pageNumber: int>"
    project-get-by-id: "record<BudgetAmount: float, BudgetHours: float, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, DefaultAccountTaskTypeIDFK: int, DefaultAccountTaskTypeName: string, EndDate: string, Members: table<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>, Notes: string, ProjectBillableTypeCode: string, ProjectBudgetTypeCode: string, ProjectCategoryColor: string, ProjectCategoryIDFK: int, ProjectCategoryName: string, ProjectCode: string, ProjectHourlyRate: float, ProjectID: int, ProjectOwnerUserIDFK: int, ProjectStatusCode: string, ProjectTags: table<Name: string, ProjectTagID: int>, Sections: table<DisplayOrder: int, EndDate: string, SectionID: int, StartDate: string, Title: string>, StartDate: string, Title: string, isArchived: bool, isTaskRequiredOnTimesheet: bool>"
    project-member-get: "record<ProjectMembers: table<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>>"
    project-member-post: "record<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>"
    project-member-put: "record<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>"
    project-timesheet-category-get: "record<Categories: table<AccountIDFK: int, BudgetHours: float, CostAmount: float, Name: string, ProjectIDFK: int, RateAmount: float, TimeSheetCategoryIDFK: int, isBillable: bool, isDisabled: bool, isPayable: bool>>"
    project-timesheet-category-post: "record<AccountIDFK: int, BudgetHours: float, CostAmount: float, Name: string, ProjectIDFK: int, RateAmount: float, TimeSheetCategoryIDFK: int, isBillable: bool, isDisabled: bool, isPayable: bool>"
    schedule-assignment-get: "record<PageNumber: int, PageSize: int, ScheduleAssignments: table<AccountIDFK: int, DateCreated: string, DateUpdated: string, Duration: float, ScheduleAssignmentID: int, ScheduleDate: string, ScheduleSeriesIDFK: int, UserIDFK: int>, TotalCount: int>"
    schedule-series-get: "record<PageNumber: int, PageSize: int, ScheduleSeries: table<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int>, TotalCount: int>"
    section-delete: "record"
    section-get: "record<Sections: table<DisplayOrder: int, EndDate: string, EndDateUTC: string, ProjectIDFK: int, SectionID: int, StartDate: string, StartDateUTC: string, Title: string>, TotalCount: int>"
    section-post: "record<DisplayOrder: int, EndDate: string, EndDateUTC: string, ProjectIDFK: int, SectionID: int, StartDate: string, StartDateUTC: string, Title: string>"
    task-delete: "record"
    task-get: "record<PageNumber: int, PageSize: int, Tasks: table<AccountTaskTypeIDFK: int, ActualTime: float, AssignedToUsers: list, DateCompleted: string, DateCreated: string, DateDue: string, DateStart: string, DateUpdated: string, Description: string, DescriptionNoHTML: string, EstimatedEffort: float, PercentComplete: float, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, SectionIDFK: int, SectionTitle: string, Tags: list, TaskID: int, TaskPriorityCode: string, TaskPriorityName: string, TaskStatusCode: string, TaskStatusName: string, Title: string, isCompleteStatus: bool>, TotalCount: int>"
    task-post: "record<AccountTaskTypeIDFK: int, ActualTime: float, AssignedToUsers: table<AssignedToEmail: string, AssignedToFirstname: string, AssignedToLastname: string, AssignedToUserIDFK: int>, DateCompleted: string, DateCreated: string, DateDue: string, DateStart: string, DateUpdated: string, Description: string, DescriptionNoHTML: string, EstimatedEffort: float, PercentComplete: float, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, SectionIDFK: int, SectionTitle: string, Tags: table<Color: string, Name: string, TagID: int>, TaskID: int, TaskPriorityCode: string, TaskPriorityName: string, TaskStatusCode: string, TaskStatusName: string, Title: string, isCompleteStatus: bool>"
    task-put: "record<AccountTaskTypeIDFK: int, ActualTime: float, AssignedToUsers: table<AssignedToEmail: string, AssignedToFirstname: string, AssignedToLastname: string, AssignedToUserIDFK: int>, DateCompleted: string, DateCreated: string, DateDue: string, DateStart: string, DateUpdated: string, Description: string, DescriptionNoHTML: string, EstimatedEffort: float, PercentComplete: float, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, SectionIDFK: int, SectionTitle: string, Tags: table<Color: string, Name: string, TagID: int>, TaskID: int, TaskPriorityCode: string, TaskPriorityName: string, TaskStatusCode: string, TaskStatusName: string, Title: string, isCompleteStatus: bool>"
    task-lookup: "record<PageSize: int, hasMore: bool, pageNumber: int, sections: table<SectionTitle: string, tasks: list>>"
    task-get-by-id: "record<AccountTaskTypeIDFK: int, ActualTime: float, AssignedToUsers: table<AssignedToEmail: string, AssignedToFirstname: string, AssignedToLastname: string, AssignedToUserIDFK: int>, DateCompleted: string, DateCreated: string, DateDue: string, DateStart: string, DateUpdated: string, Description: string, DescriptionNoHTML: string, EstimatedEffort: float, PercentComplete: float, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, SectionIDFK: int, SectionTitle: string, Tags: table<Color: string, Name: string, TagID: int>, TaskID: int, TaskPriorityCode: string, TaskPriorityName: string, TaskStatusCode: string, TaskStatusName: string, Title: string, isCompleteStatus: bool>"
    task-status-get: "record<statuses: table<AccountTaskTypeIDFK: int, Color: string, DisplayOrder: int, Name: string, TaskStatusCode: string, TaskTypeName: string, isComplete: bool>>"
    task-type-get: "record<tasktypes: table<AccountTaskTypeID: int, Icon: string, IconType: string, Name: string, isDefault: bool>>"
    tax-get: "record<Taxes: table<CalculatedPercent: float, Name: string, TaxCode: string, TaxComponents: list, TaxID: int>>"
    timesheet-get: "record<PageNumber: int, PageSize: int, Timesheets: table<ApprovedBy: string, CategoryName: string, CustomMetadata: string, CustomerIDFK: int, CustomerName: string, DateApproved: string, DateCreated: string, DateUpdated: string, Duration: float, Email: string, EndTimeLocal: string, EndTimeUTC: string, EntryDate: string, Firstname: string, HasTimer: bool, InvoiceIDFK: int, InvoiceLineItemIDFK: int, Lastname: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, StartTimeLocal: string, StartTimeUTC: string, TaskIDFK: int, TaskTitle: string, TimerStartedAtUTC: string, TimesheetCategoryIDFK: int, TimesheetEntryApprovalStatusCode: string, TimesheetEntryID: int, TimesheetUserTimeZone: string, UserIDFK: int, isBillable: bool, isInvoiced: bool>, TotalCount: int>"
    timesheet-post: "record<ApprovedBy: string, CategoryName: string, CustomMetadata: string, CustomerIDFK: int, CustomerName: string, DateApproved: string, DateCreated: string, DateUpdated: string, Duration: float, Email: string, EndTimeLocal: string, EndTimeUTC: string, EntryDate: string, Firstname: string, HasTimer: bool, InvoiceIDFK: int, InvoiceLineItemIDFK: int, Lastname: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, StartTimeLocal: string, StartTimeUTC: string, TaskIDFK: int, TaskTitle: string, TimerStartedAtUTC: string, TimesheetCategoryIDFK: int, TimesheetEntryApprovalStatusCode: string, TimesheetEntryID: int, TimesheetUserTimeZone: string, UserIDFK: int, isBillable: bool, isInvoiced: bool>"
    timesheet-put: "record<ApprovedBy: string, CategoryName: string, CustomMetadata: string, CustomerIDFK: int, CustomerName: string, DateApproved: string, DateCreated: string, DateUpdated: string, Duration: float, Email: string, EndTimeLocal: string, EndTimeUTC: string, EntryDate: string, Firstname: string, HasTimer: bool, InvoiceIDFK: int, InvoiceLineItemIDFK: int, Lastname: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, StartTimeLocal: string, StartTimeUTC: string, TaskIDFK: int, TaskTitle: string, TimerStartedAtUTC: string, TimesheetCategoryIDFK: int, TimesheetEntryApprovalStatusCode: string, TimesheetEntryID: int, TimesheetUserTimeZone: string, UserIDFK: int, isBillable: bool, isInvoiced: bool>"
    timesheet-delete: "record"
    timesheet-get-by-id: "record<ApprovedBy: string, CategoryName: string, CustomMetadata: string, CustomerIDFK: int, CustomerName: string, DateApproved: string, DateCreated: string, DateUpdated: string, Duration: float, Email: string, EndTimeLocal: string, EndTimeUTC: string, EntryDate: string, Firstname: string, HasTimer: bool, InvoiceIDFK: int, InvoiceLineItemIDFK: int, Lastname: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, StartTimeLocal: string, StartTimeUTC: string, TaskIDFK: int, TaskTitle: string, TimerStartedAtUTC: string, TimesheetCategoryIDFK: int, TimesheetEntryApprovalStatusCode: string, TimesheetEntryID: int, TimesheetUserTimeZone: string, UserIDFK: int, isBillable: bool, isInvoiced: bool>"
    timesheet-submission-post: "record"
    timesheet-summary-get: "record<BillableHours: float, EntryDateFrom: string, EntryDateTo: string, GroupData: table<BillableHours: float, GroupData: list, GroupID: string, GroupName: string, TotalHours: float>, GroupingLevels: list<string>, TotalHours: float, UserID: list<int>>"
    timesheet-timer-get-running-timer: "record"
    timesheet-timer-stop-timer: "record"
    timesheet-timer-start-timer: "record"
    user-profile-get: "record<Users: table<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DefaultBillableRate: float, DefaultCostRate: float, Email: string, Firstname: string, FridayAvailableHours: float, IANATimezone: string, Lastname: string, Mobile: string, MondayAvailableHours: float, Phone: string, PositionTitle: string, Roles: list, SaturdayAvailableHours: float, SundayAvailableHours: float, Tags: list, ThursdayAvailableHours: float, TimeZone: string, TuesdayAvailableHours: float, UserID: int, WednesdayAvailableHours: float, isTeamMember: bool>>"
    webhook-delete-by-url: "record"
    webhook-get: "record<Webhooks: table<EventCode: string, NotificationURL: string, SubscriptionID: int, UserIDFK: int>>"
    webhook-post: "record<ID: int>"
    webhook-delete: "record"
    webhook-get-by-id: "record<Webhooks: table<EventCode: string, NotificationURL: string, SubscriptionID: int, UserIDFK: int>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["schedule-series-add-booking" "schedule-series-add-leave" "schedule-series-edit-booking" "schedule-series-edit-leave" "account-get" "bill-get" "bill-post" "bill-get-by-id" "bill-payment-get" "bill-payment-post" "bill-payment-get-by-id" "company-get" "company-post" "company-put" "company-lookup" "company-get-by-id" "contact-get" "contact-post" "contact-get-by-id" "credit-note-get" "credit-note-get-by-id" "currency-get" "estimate-get" "estimate-post" "estimate-get-by-id" "expense-delete" "expense-get" "expense-post" "expense-put" "expense-attachment" "expense-get-by-id" "expense-approval" "expense-category-get" "expense-group-lookup" "expense-merchange-lookup" "expense-payment-method-lookup" "expense-summary-get" "fixed-amount-get" "inventory-get" "inventory-get-by-id" "invoice-get" "invoice-post" "invoice-get-by-id" "payment-get" "payment-post" "payment-get-by-id" "project-get" "project-post" "project-put" "project-lookup" "project-get-by-id" "project-member-get" "project-member-post" "project-member-put" "project-timesheet-category-get" "project-timesheet-category-post" "schedule-assignment-get" "schedule-series-get" "section-delete" "section-get" "section-post" "task-delete" "task-get" "task-post" "task-put" "task-lookup" "task-get-by-id" "task-status-get" "task-type-get" "tax-get" "timesheet-get" "timesheet-post" "timesheet-put" "timesheet-delete" "timesheet-get-by-id" "timesheet-submission-post" "timesheet-summary-get" "timesheet-timer-get-running-timer" "timesheet-timer-stop-timer" "timesheet-timer-start-timer" "user-profile-get" "webhook-delete-by-url" "webhook-get" "webhook-post" "webhook-delete" "webhook-get-by-id" "commands"] | sort) } | get name | first)
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

# Create new Schedule Booking
#
# POST /ScheduleSeries/AddBooking
# Returns: record<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int>
# operationId: ScheduleSeries_AddBooking
export def "schedule-series-add-booking" [
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
  --category-idfk: int # format: int32
  --duration-type: string
  --end-date: string # format: date-time
  --hours-per-day: float # format: double
  --notes: string
  --project-idfk: int # format: int32
  --schedule-on-days-off: oneof<nothing, bool>
  --start-date: string # format: date-time
  --task-idfk: int # format: int32
  --total-duration: float # format: double
  --user-idfk: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ScheduleSeries/AddBooking"
    body: {content_type: "application/json", kind: json, fields: [{name: CategoryIDFK, var: category_idfk}, {name: DurationType, var: duration_type}, {name: EndDate, var: end_date}, {name: HoursPerDay, var: hours_per_day}, {name: Notes, var: notes}, {name: ProjectIDFK, var: project_idfk}, {name: ScheduleOnDaysOff, var: schedule_on_days_off}, {name: StartDate, var: start_date}, {name: TaskIDFK, var: task_idfk}, {name: TotalDuration, var: total_duration}, {name: UserIDFK, var: user_idfk}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    category_idfk: $category_idfk, duration_type: $duration_type, end_date: $end_date, hours_per_day: $hours_per_day, notes: $notes, project_idfk: $project_idfk, schedule_on_days_off: $schedule_on_days_off, start_date: $start_date, task_idfk: $task_idfk, total_duration: $total_duration, user_idfk: $user_idfk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create new Leave Booking
#
# POST /ScheduleSeries/AddLeave
# Returns: record<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int>
# operationId: ScheduleSeries_AddLeave
export def "schedule-series-add-leave" [
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
  --leave-end-date: string # format: date-time
  --leave-hours-per-day: float # format: double
  --leave-notes: string
  --leave-notify: oneof<nothing, bool>
  --leave-start-date: string # format: date-time
  --leave-type-idfk: int # format: int32
  --leave-user-idfk: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ScheduleSeries/AddLeave"
    body: {content_type: "application/json", kind: json, fields: [{name: LeaveEndDate, var: leave_end_date}, {name: LeaveHoursPerDay, var: leave_hours_per_day}, {name: LeaveNotes, var: leave_notes}, {name: LeaveNotify, var: leave_notify}, {name: LeaveStartDate, var: leave_start_date}, {name: LeaveTypeIDFK, var: leave_type_idfk}, {name: LeaveUserIDFK, var: leave_user_idfk}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    leave_end_date: $leave_end_date, leave_hours_per_day: $leave_hours_per_day, leave_notes: $leave_notes, leave_notify: $leave_notify, leave_start_date: $leave_start_date, leave_type_idfk: $leave_type_idfk, leave_user_idfk: $leave_user_idfk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Edit Booking
#
# PUT /ScheduleSeries/EditBooking
# Returns: record<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int>
# operationId: ScheduleSeries_EditBooking
export def "schedule-series-edit-booking" [
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
  --category-idfk: int # format: int32
  --duration-type: string
  --end-date: string # format: date-time
  --hours-per-day: float # format: double
  --notes: string
  --project-idfk: int # format: int32
  --schedule-on-days-off: oneof<nothing, bool>
  --schedule-series-id: int # format: int64
  --start-date: string # format: date-time
  --task-idfk: int # format: int32
  --total-duration: float # format: double
  --user-idfk: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/ScheduleSeries/EditBooking"
    body: {content_type: "application/json", kind: json, fields: [{name: CategoryIDFK, var: category_idfk}, {name: DurationType, var: duration_type}, {name: EndDate, var: end_date}, {name: HoursPerDay, var: hours_per_day}, {name: Notes, var: notes}, {name: ProjectIDFK, var: project_idfk}, {name: ScheduleOnDaysOff, var: schedule_on_days_off}, {name: ScheduleSeriesID, var: schedule_series_id}, {name: StartDate, var: start_date}, {name: TaskIDFK, var: task_idfk}, {name: TotalDuration, var: total_duration}, {name: UserIDFK, var: user_idfk}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    category_idfk: $category_idfk, duration_type: $duration_type, end_date: $end_date, hours_per_day: $hours_per_day, notes: $notes, project_idfk: $project_idfk, schedule_on_days_off: $schedule_on_days_off, schedule_series_id: $schedule_series_id, start_date: $start_date, task_idfk: $task_idfk, total_duration: $total_duration, user_idfk: $user_idfk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Edit Leave Booking
#
# PUT /ScheduleSeries/EditLeave
# Returns: record<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int>
# operationId: ScheduleSeries_EditLeave
export def "schedule-series-edit-leave" [
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
  --end-date: string # format: date-time
  --hours-per-day: float # format: double
  --leave-type-idfk: int # format: int32
  --notes: string
  --schedule-series-id: int # format: int64
  --start-date: string # format: date-time
  --user-idfk: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/ScheduleSeries/EditLeave"
    body: {content_type: "application/json", kind: json, fields: [{name: EndDate, var: end_date}, {name: HoursPerDay, var: hours_per_day}, {name: LeaveTypeIDFK, var: leave_type_idfk}, {name: Notes, var: notes}, {name: ScheduleSeriesID, var: schedule_series_id}, {name: StartDate, var: start_date}, {name: UserIDFK, var: user_idfk}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    end_date: $end_date, hours_per_day: $hours_per_day, leave_type_idfk: $leave_type_idfk, notes: $notes, schedule_series_id: $schedule_series_id, start_date: $start_date, user_idfk: $user_idfk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Account Details
#
# GET /api/Account
# Returns: record<AccountEmail: string, AccountID: int, AllowHidingCompletedTasksOnTimesheet: bool, BrandPrimaryColor: string, BrandPrimaryColorLuminance: string, CompanyName: string, CurrentServerTimeISO: string, DefaultCurrencyCode: string, ExpenseApprovalRequired: bool, LockApprovedExpenses: bool, LockApprovedTimesheets: bool, SC: string, Subdomain: string, TimesheetDayOfWeek: int, TimesheetDisplayFormatCode: string, WeeklyTimesheetReminder: bool, has24HourTimesheetFormat: bool, hasStartEndTimesheets: bool>
# operationId: Account_Get
export def "account-get" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Account"
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Bills
#
# GET /api/Bill
# Returns: record<Bills: table<AccountIDFK: int, Balance: float, BillNumber: string, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, DateVerified: string, DueDate: string, ExchangeRate: float, Issuer: record, LineItems: list, Links: record, Notes: string, Recipient: record, Subject: string, SupplierPONumber: string, TaxAmount: float, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string, TransactionTaxConfigCode: string>, PageNumber: int, PageSize: int, TotalCount: int>
# operationId: Bill_Get
export def "bill-get" [
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
  --updated-after: string # format: date-time
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --sort: string
  --company-idfk: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Bill"
    query: [{name: UpdatedAfter, var: updated_after}, {name: pageSize, var: page_size}, {name: pageNumber, var: page_number}, {name: Sort, var: sort}, {name: CompanyIDFK, var: company_idfk}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    updated_after: $updated_after, page_size: $page_size, page_number: $page_number, sort: $sort, company_idfk: $company_idfk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new draft Bill
#
# POST /api/Bill
# Returns: record<AccountIDFK: int, Balance: float, BillNumber: string, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, DateVerified: string, DueDate: string, ExchangeRate: float, Issuer: record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, CompanyIDFK: int, CompanyName: string>, LineItems: table<Amount: float, Description: string, Discount: float, InventoryItemIDFK: int, InventoryItemName: string, InventoryItemSKU: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaxAmount: float, TaxCode: string, TaxIDFK: int, TaxName: string, TransactionLineItemID: int, UnitPrice: float>, Links: record<Edit: string, View: string, WebView: string>, Notes: string, Recipient: record<RecipientBillingAddressCity: string, RecipientBillingAddressCountryCode: string, RecipientBillingAddressLine: string, RecipientBillingAddressPostCode: string, RecipientBillingAddressState: string, RecipientFormattedBillingAddress: string>, Subject: string, SupplierPONumber: string, TaxAmount: float, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string, TransactionTaxConfigCode: string>
# operationId: Bill_Post
export def "bill-post" [
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
  --bill-number: string # Pass any string. If left blank it will use the next number in the auto incrementing sequence. If an integer is passed then the largest integer will be use as the seed to auto generate the next invoice number in the sequence.
  --bill-template-idfk: int # If left blank the account default invoice template will be used. (format: int32)
  --company-idfk: int # If left blank then you must specify Company Name. (format: int32)
  --company-name: string # If left blank then you must specify Company ID. Specified Name will be used to match existing customer record. If not matched then it will be used to create a new customer. First Name, Last Name and Email will only be used if it is a new company. If the Company name appears multiple times we will check the email address to find a matching company. If email address doesn't identify a matching company then the invoice creation will be rejected.
  --currency-code: string # Expects ISO Standard 3 character currency code. If left blank the currency will default to account's currency in general setting. For existing companies this field will be ignored and the invoice will use the currency of the customer. For new customers if the currency is not specified then account currency will be used otherwise the specified currency will be used.
  --date-issued: string # If not specified it will use today's date. The date should be specified as local date. (format: date-time)
  --due-date: string # It will be auto calculated based on the payment term and issue date. Due Date must be greater than or equal to Issue Date. If the Due Date is specified then Payment Terms will be set to -1 (Custom) (format: date-time)
  --email: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --exchange-rate: float # Exchange rate is only valid for invoices in currency other than default account currency. If not specified it will get the market rate based on the Date Issued. (format: double)
  --firstname: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --lastname: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --line-items: list # item shape: {Description?: string, Discount?: float, InventoryItemIDFK?: int, InventoryItemName?: string, ProjectIDFK?: int, Quantity: float, TaxIDFK?: int, TaxName?: string, TaxPercent?: float, UnitPrice: float}
  --notes: string # Plain UTF8 text. (no HTML). Max 2000 characters
  --payment-terms: int # "If left blank we will set it to customer default. If specified then it must match one of your existing pre configured payment term periods. Your account starts with: (-1 --- Custom, 0 --- Upon Receipt, 7 --- 7 Days, 15 --- 15 Days, 30 --- 30 Days, 45 --- 45 Days, 60 --- 60 Days) (format: int32)
  --subject: string # Plain UTF8 text. (no HTML). 255 characters max
  --supplier-po-number: string # Plain UTF8 text. 100 characters max
  --transaction-prefix: string # A prefix for the Invoice number. e.g. 'INV'. If left blank it will be set to the account default. Max length 20 characters.
  --transaction-tax-config-code: string # Possible values are (EX --- Tax Exclusive, INC --- Tax Inclusive). If left empty it will use the account default.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Bill"
    body: {content_type: "application/json", kind: json, fields: [{name: BillNumber, var: bill_number}, {name: BillTemplateIDFK, var: bill_template_idfk}, {name: CompanyIDFK, var: company_idfk}, {name: CompanyName, var: company_name}, {name: CurrencyCode, var: currency_code}, {name: DateIssued, var: date_issued}, {name: DueDate, var: due_date}, {name: Email, var: email}, {name: ExchangeRate, var: exchange_rate}, {name: Firstname, var: firstname}, {name: Lastname, var: lastname}, {name: LineItems, var: line_items}, {name: Notes, var: notes}, {name: PaymentTerms, var: payment_terms}, {name: Subject, var: subject}, {name: SupplierPONumber, var: supplier_po_number}, {name: TransactionPrefix, var: transaction_prefix}, {name: TransactionTaxConfigCode, var: transaction_tax_config_code}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    bill_number: $bill_number, bill_template_idfk: $bill_template_idfk, company_idfk: $company_idfk, company_name: $company_name, currency_code: $currency_code, date_issued: $date_issued, due_date: $due_date, email: $email, exchange_rate: $exchange_rate, firstname: $firstname, lastname: $lastname, line_items: $line_items, notes: $notes, payment_terms: $payment_terms, subject: $subject, supplier_po_number: $supplier_po_number, transaction_prefix: $transaction_prefix, transaction_tax_config_code: $transaction_tax_config_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a Bill by Bill ID
#
# GET /api/Bill/{id}
# operationId: Bill_GetByID
export def "bill-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: get
    path: "/api/Bill/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Bill Payments
#
# GET /api/BillPayment
# Returns: record<PageNumber: int, PageSize: int, Payments: table<AccountIDFK: int, Balance: float, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: list, PaymentNumber: string, PaymentProviderCode: string, SupplierIDFK: int, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string>, TotalCount: int>
# operationId: BillPayment_Get
export def "bill-payment-get" [
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
  --updated-after: string # format: date-time
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/BillPayment"
    query: [{name: UpdatedAfter, var: updated_after}, {name: pageSize, var: page_size}, {name: pageNumber, var: page_number}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    updated_after: $updated_after, page_size: $page_size, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create new Bill Payment and optionally assign payment allocations to Bills
#
# POST /api/BillPayment
# Returns: record<AccountIDFK: int, Balance: float, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: table<AllocationAmount: float, AllocationDate: string, BillTransactionIDFK: int, PaymentTransactionIDFK: int, TransactionAllocationID: int>, PaymentNumber: string, PaymentProviderCode: string, SupplierIDFK: int, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string>
# operationId: BillPayment_Post
export def "bill-payment-post" [
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
  --amount: float # format: double
  --company-idfk: int # Only required if no invoice allocations specified. (format: int32)
  --currency-code: string # Optional for specifying the Bill Payment's Currency (3 letter ISO Currency Code).
  --date-issued: string # Date of Payment. If not specified, assumes today. (format: date-time)
  --exchange-rate: float # Optional. Only used when the Company's currency is different from the Avaza account's base currency. Specifies the exchange rate that should apply between the Company currency and base currency. If not provided we will obtain an up to date exchange rate for the Payment Issue Date. (format: double)
  --notes: string
  --payment-allocations: list # List of amounts within this payment that are allocated to invoices. The sum of these be less than or equal to the payment amount. — item shape: {AllocationAmount?: float, AllocationDate?: string, BillTransactionIDFK?: int}
  --payment-number: string # Optional. If not specified will be automatically generated
  --payment-provider-code: string # Optional for storing the payment provider who was the source of funds.
  --transaction-prefix: string # Optional to override the default prefix added to Payment Numbers
  --transaction-reference: string # Optional for storing the reference # of the payment method.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/BillPayment"
    body: {content_type: "application/json", kind: json, fields: [{name: Amount, var: amount}, {name: CompanyIDFK, var: company_idfk}, {name: CurrencyCode, var: currency_code}, {name: DateIssued, var: date_issued}, {name: ExchangeRate, var: exchange_rate}, {name: Notes, var: notes}, {name: PaymentAllocations, var: payment_allocations}, {name: PaymentNumber, var: payment_number}, {name: PaymentProviderCode, var: payment_provider_code}, {name: TransactionPrefix, var: transaction_prefix}, {name: TransactionReference, var: transaction_reference}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    amount: $amount, company_idfk: $company_idfk, currency_code: $currency_code, date_issued: $date_issued, exchange_rate: $exchange_rate, notes: $notes, payment_allocations: $payment_allocations, payment_number: $payment_number, payment_provider_code: $payment_provider_code, transaction_prefix: $transaction_prefix, transaction_reference: $transaction_reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a Bill Payment by Payment Transaction ID
#
# GET /api/BillPayment/{id}
# Returns: record<AccountIDFK: int, Balance: float, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: table<AllocationAmount: float, AllocationDate: string, BillTransactionIDFK: int, PaymentTransactionIDFK: int, TransactionAllocationID: int>, PaymentNumber: string, PaymentProviderCode: string, SupplierIDFK: int, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string>
# operationId: BillPayment_GetByID
export def "bill-payment-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/BillPayment/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Companies
#
# GET /api/Company
# Returns: record<Companies: table<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, Comments: string, CompanyID: int, CompanyName: string, Contacts: list, CurrencyCode: string, DateCreated: string, DateUpdated: string, DefaultTradingTermIDFK: int, Fax: string, Phone: string, TaxNumber: string, website: string>, PageNumber: int, PageSize: int, TotalCount: int>
# operationId: Company_Get
export def "company-get" [
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
  --updated-after: string # format: date-time
  --page-size: int # Number of results per page (format: int32)
  --page-number: int # 1 based page number to retrieve (format: int32)
  --sort: string # (optional) Supply one of: "DateUpdated", "DateCreated", "CompanyName","DateUpdated desc","DateCreated desc", "CompanyName desc"
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Company"
    query: [{name: UpdatedAfter, var: updated_after}, {name: pageSize, var: page_size}, {name: pageNumber, var: page_number}, {name: Sort, var: sort}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    updated_after: $updated_after, page_size: $page_size, page_number: $page_number, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a Company
#
# POST /api/Company
# Returns: record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, Comments: string, CompanyID: int, CompanyName: string, Contacts: table<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>, CurrencyCode: string, DateCreated: string, DateUpdated: string, DefaultTradingTermIDFK: int, Fax: string, Phone: string, TaxNumber: string, website: string>
# operationId: Company_Post
export def "company-post" [
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
  --billing-address: string
  --billing-address-city: string
  --billing-address-line: string
  --billing-address-post-code: string
  --billing-address-state: string
  --billing-country-code: string
  --comments: string
  company_name: string
  --currency-code: string
  --fax: string
  --phone: string
  --tax-number: string
  --website: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Company"
    body: {content_type: "application/json", kind: json, fields: [{name: BillingAddress, var: billing_address}, {name: BillingAddressCity, var: billing_address_city}, {name: BillingAddressLine, var: billing_address_line}, {name: BillingAddressPostCode, var: billing_address_post_code}, {name: BillingAddressState, var: billing_address_state}, {name: BillingCountryCode, var: billing_country_code}, {name: Comments, var: comments}, {name: CompanyName, var: company_name}, {name: CurrencyCode, var: currency_code}, {name: Fax, var: fax}, {name: Phone, var: phone}, {name: TaxNumber, var: tax_number}, {name: website, var: website}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    billing_address: $billing_address, billing_address_city: $billing_address_city, billing_address_line: $billing_address_line, billing_address_post_code: $billing_address_post_code, billing_address_state: $billing_address_state, billing_country_code: $billing_country_code, comments: $comments, company_name: $company_name, currency_code: $currency_code, fax: $fax, phone: $phone, tax_number: $tax_number, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a Company record.
#
# PUT /api/Company
# Returns: record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, Comments: string, CompanyID: int, CompanyName: string, Contacts: table<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>, CurrencyCode: string, DateCreated: string, DateUpdated: string, DefaultTradingTermIDFK: int, Fax: string, Phone: string, TaxNumber: string, website: string>
# operationId: Company_Put
export def "company-put" [
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
  --billing-address: string
  --billing-address-city: string
  --billing-address-line: string
  --billing-address-post-code: string
  --billing-address-state: string
  --billing-country-code: string
  --comments: string
  --company-id: int # format: int32
  --company-name: string
  --fax: string
  --fields-to-update: list<string>
  --phone: string
  --tax-number: string
  --website: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/Company"
    body: {content_type: "application/json", kind: json, fields: [{name: BillingAddress, var: billing_address}, {name: BillingAddressCity, var: billing_address_city}, {name: BillingAddressLine, var: billing_address_line}, {name: BillingAddressPostCode, var: billing_address_post_code}, {name: BillingAddressState, var: billing_address_state}, {name: BillingCountryCode, var: billing_country_code}, {name: Comments, var: comments}, {name: CompanyID, var: company_id}, {name: CompanyName, var: company_name}, {name: Fax, var: fax}, {name: FieldsToUpdate, var: fields_to_update}, {name: Phone, var: phone}, {name: TaxNumber, var: tax_number}, {name: website, var: website}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    billing_address: $billing_address, billing_address_city: $billing_address_city, billing_address_line: $billing_address_line, billing_address_post_code: $billing_address_post_code, billing_address_state: $billing_address_state, billing_country_code: $billing_country_code, comments: $comments, company_id: $company_id, company_name: $company_name, fax: $fax, fields_to_update: $fields_to_update, phone: $phone, tax_number: $tax_number, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets minimal list of Companies.
#
# GET /api/Company/Lookup
# Returns: record<Companies: table<CompanyID: int, CompanyName: string>, PageNumber: int, PageSize: int, TotalCount: int>
# operationId: CompanyLookup
export def "company-lookup" [
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
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --search: string # Search string to match against Company title
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Company/Lookup"
    query: [{name: pageSize, var: page_size}, {name: pageNumber, var: page_number}, {name: search, var: search}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_number: $page_number, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets Company by Company ID
#
# GET /api/Company/{id}
# Returns: record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, Comments: string, CompanyID: int, CompanyName: string, Contacts: table<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>, CurrencyCode: string, DateCreated: string, DateUpdated: string, DefaultTradingTermIDFK: int, Fax: string, Phone: string, TaxNumber: string, website: string>
# operationId: Company_GetByID
export def "company-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Company/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Contacts
#
# GET /api/Contact
# Returns: record<Contacts: table<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>, PageNumber: int, PageSize: int, TotalCount: int>
# operationId: Contact_Get
export def "contact-get" [
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
  --updated-after: string # format: date-time
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --sort: string
  --company-idfk: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Contact"
    query: [{name: UpdatedAfter, var: updated_after}, {name: pageSize, var: page_size}, {name: pageNumber, var: page_number}, {name: Sort, var: sort}, {name: CompanyIDFK, var: company_idfk}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    updated_after: $updated_after, page_size: $page_size, page_number: $page_number, sort: $sort, company_idfk: $company_idfk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a Contact
#
# POST /api/Contact
# Returns: record<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>
# operationId: Contact_Post
export def "contact-post" [
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
  --company-billing-address: string
  --company-billing-address-city: string
  --company-billing-address-country-code: string
  --company-billing-address-line: string
  --company-billing-address-post-code: string
  --company-billing-address-state: string
  --company-idfk: int # format: int32
  --company-name: string
  contact_email: string
  --currency-code: string
  firstname: string
  lastname: string
  --mobile: string
  --phone: string
  --position-title: string
  --update-existing: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Contact"
    body: {content_type: "application/json", kind: json, fields: [{name: CompanyBillingAddress, var: company_billing_address}, {name: CompanyBillingAddressCity, var: company_billing_address_city}, {name: CompanyBillingAddressCountryCode, var: company_billing_address_country_code}, {name: CompanyBillingAddressLine, var: company_billing_address_line}, {name: CompanyBillingAddressPostCode, var: company_billing_address_post_code}, {name: CompanyBillingAddressState, var: company_billing_address_state}, {name: CompanyIDFK, var: company_idfk}, {name: CompanyName, var: company_name}, {name: ContactEmail, var: contact_email}, {name: CurrencyCode, var: currency_code}, {name: Firstname, var: firstname}, {name: Lastname, var: lastname}, {name: Mobile, var: mobile}, {name: Phone, var: phone}, {name: PositionTitle, var: position_title}, {name: UpdateExisting, var: update_existing}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    company_billing_address: $company_billing_address, company_billing_address_city: $company_billing_address_city, company_billing_address_country_code: $company_billing_address_country_code, company_billing_address_line: $company_billing_address_line, company_billing_address_post_code: $company_billing_address_post_code, company_billing_address_state: $company_billing_address_state, company_idfk: $company_idfk, company_name: $company_name, contact_email: $contact_email, currency_code: $currency_code, firstname: $firstname, lastname: $lastname, mobile: $mobile, phone: $phone, position_title: $position_title, update_existing: $update_existing
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets Contact by Contact ID
#
# GET /api/Contact/{id}
# Returns: record<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>
# operationId: Contact_GetByID
export def "contact-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Contact/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of CreditNotes
#
# GET /api/CreditNote
# Returns: record<CreditNotes: table<Balance: float, CreditNoteAllocations: list, CreditNoteLineItems: list, CreditNoteNumber: string, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, Notes: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string>, PageNumber: int, PageSize: int, TotalCount: int>
# operationId: CreditNote_Get
export def "credit-note-get" [
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
  --updated-after: string # format: date-time
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/CreditNote"
    query: [{name: UpdatedAfter, var: updated_after}, {name: pageSize, var: page_size}, {name: pageNumber, var: page_number}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    updated_after: $updated_after, page_size: $page_size, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets Credit Note by CreditNoteID
#
# GET /api/CreditNote/{id}
# Returns: record<Balance: float, CreditNoteAllocations: table<AllocationAmount: float, AllocationDate: string, CreditNoteTransactionIDFK: int, InvoiceTransactionIDFK: int, TransactionAllocationID: int>, CreditNoteLineItems: table<Amount: float, Description: string, Discount: float, Quantity: float, TaxAmount: float, TaxIDFK: int, TransactionLineItemID: int, UnitPrice: float>, CreditNoteNumber: string, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, Notes: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string>
# operationId: CreditNote_GetByID
export def "credit-note-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/CreditNote/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Currencies
#
# GET /api/Currency
# Returns: record<Currencies: table<CurrencyCode: string, DecimalPlaces: int, Name: string, Symbol: string, Symbol2: string>>
# operationId: Currency_Get
export def "currency-get" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Currency"
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Estimates
#
# GET /api/Estimate
# Returns: record<Estimates: table<AccountIDFK: int, Balance: float, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, DateCreated: string, DateIssued: string, DateSent: string, DateUpdated: string, DueDate: string, EstimateID: int, EstimateItemNumber: string, EstimatePrefix: string, EstimateStatusCode: string, EstimateTaxConfigCode: string, ExchangeRate: float, Issuer: record, LineItems: list, Links: record, Notes: string, Recipient: record, Subject: string, TaxAmount: float, TotalAmount: float>, PageNumber: int, PageSize: int, TotalCount: int>
# operationId: Estimate_Get
export def "estimate-get" [
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
  --updated-after: string # format: date-time
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --sort: string
  --company-idfk: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Estimate"
    query: [{name: UpdatedAfter, var: updated_after}, {name: pageSize, var: page_size}, {name: pageNumber, var: page_number}, {name: Sort, var: sort}, {name: CompanyIDFK, var: company_idfk}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    updated_after: $updated_after, page_size: $page_size, page_number: $page_number, sort: $sort, company_idfk: $company_idfk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new draft Estimate
#
# POST /api/Estimate
# Returns: record<AccountIDFK: int, Balance: float, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, DateCreated: string, DateIssued: string, DateSent: string, DateUpdated: string, DueDate: string, EstimateID: int, EstimateItemNumber: string, EstimatePrefix: string, EstimateStatusCode: string, EstimateTaxConfigCode: string, ExchangeRate: float, Issuer: record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, TaxNumber: string>, LineItems: table<Amount: float, Description: string, Discount: float, EstimateLineItemID: int, InventoryItemIDFK: int, InventoryItemName: string, InventoryItemSKU: string, Quantity: float, TaxAmount: float, TaxCode: string, TaxIDFK: int, TaxName: string, UnitPrice: float>, Links: record<ClientView: string, Edit: string, View: string>, Notes: string, Recipient: record<CompanyIDFK: int, CompanyName: string, RecipientBillingAddressCity: string, RecipientBillingAddressCountryCode: string, RecipientBillingAddressLine: string, RecipientBillingAddressPostCode: string, RecipientBillingAddressState: string, RecipientFormattedBillingAddress: string>, Subject: string, TaxAmount: float, TotalAmount: float>
# operationId: Estimate_Post
export def "estimate-post" [
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
  --company-idfk: int # If left blank then you must specify Company Name. (format: int32)
  --company-name: string # If left blank then you must specify Company ID. Specified Name will be used to match existing customer record. If not matched then it will be used to create a new customer. First Name, Last Name and Email will only be used if it is a new company. If the Company name appears multiple times we will check the email address to find a matching company. If email address doesn't identify a matching company then the Estimate creation will be rejected.
  --currency-code: string # Expects ISO Standard 3 character currency code. If left blank the currency will default to account's currency in general setting. For existing companies this field will be ignored and the Estimate will use the currency of the customer. For new customers if the currency is not specified then account currency will be used otherwise the specified currency will be used.
  --customer-po-number: string # Plain UTF8 text. 100 characters max
  --date-issued: string # If not specified it will use today's date. The date should be specified as local date. (format: date-time)
  --due-date: string # It will be auto calculated based on the payment term and issue date. Due Date must be greater than or equal to Issue Date. If the Due Date is specified then Payment Terms will be set to -1 (Custom) (format: date-time)
  --email: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --estimate-number: string # Pass any string. If left blank it will use the next number in the auto incrementing sequence. If an integer is passed then the largest integer will be use as the seed to auto generate the next Estimate number in the sequence.
  --estimate-prefix: string # A prefix for the Estimate number. e.g. 'INV'. If left blank it will be set to the account default. Max length 20 characters.
  --estimate-tax-config-code: string # Possible values are (EX --- Tax Exclusive, INC --- Tax Inclusive). If left empty it will use the account default.
  --exchange-rate: float # Exchange rate is only valid for Estimates in currency other than default account currency. If not specified it will get the market rate based on the Date Issued. (format: double)
  --firstname: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --invoice-template-idfk: int # If left blank the account default Estimate template will be used. (format: int32)
  --lastname: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --line-items: list # item shape: {Description?: string, Discount?: float, InventoryItemIDFK?: int, InventoryItemName?: string, Quantity: float, TaxIDFK?: int, TaxName?: string, TaxPercent?: float, UnitPrice: float}
  --notes: string # Plain UTF8 text. (no HTML). Max 2000 characters
  --subject: string # Plain UTF8 text. (no HTML). 255 characters max
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Estimate"
    body: {content_type: "application/json", kind: json, fields: [{name: CompanyIDFK, var: company_idfk}, {name: CompanyName, var: company_name}, {name: CurrencyCode, var: currency_code}, {name: CustomerPONumber, var: customer_po_number}, {name: DateIssued, var: date_issued}, {name: DueDate, var: due_date}, {name: Email, var: email}, {name: EstimateNumber, var: estimate_number}, {name: EstimatePrefix, var: estimate_prefix}, {name: EstimateTaxConfigCode, var: estimate_tax_config_code}, {name: ExchangeRate, var: exchange_rate}, {name: Firstname, var: firstname}, {name: InvoiceTemplateIDFK, var: invoice_template_idfk}, {name: Lastname, var: lastname}, {name: LineItems, var: line_items}, {name: Notes, var: notes}, {name: Subject, var: subject}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    company_idfk: $company_idfk, company_name: $company_name, currency_code: $currency_code, customer_po_number: $customer_po_number, date_issued: $date_issued, due_date: $due_date, email: $email, estimate_number: $estimate_number, estimate_prefix: $estimate_prefix, estimate_tax_config_code: $estimate_tax_config_code, exchange_rate: $exchange_rate, firstname: $firstname, invoice_template_idfk: $invoice_template_idfk, lastname: $lastname, line_items: $line_items, notes: $notes, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets Estimate by Estimate ID
#
# GET /api/Estimate/{id}
# operationId: Estimate_GetByID
export def "estimate-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: get
    path: "/api/Estimate/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a Timesheet Entry
#
# DELETE /api/Expense
# Returns: record<Results: table<ErrorMessage: string, ExpenseID: int, Success: bool>>
# operationId: Expense_Delete
export def "expense-delete" [
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
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/api/Expense"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Expenses
#
# GET /api/Expense
# Returns: record<Expenses: table<Amount: float, AttachmentPreviewURL: string, AttachmentURL: string, ChargeableStatusCode: string, CurrencyCode: string, CustomerIDFK: int, CustomerName: string, DateCreated: string, DateUpdated: string, Email: string, ExchangeRate: float, ExpenseApprovalStatusCode: string, ExpenseCategoryHasUnitPrice: bool, ExpenseCategoryIDFK: int, ExpenseCategoryName: string, ExpenseCategoryUnitName: string, ExpenseCategoryUnitPrice: float, ExpenseDate: string, ExpenseID: int, ExpensePaymentMethodIDFK: int, ExpensePaymentMethodName: string, ExpenseReimbursementIDFK: int, ExpenseReimbursementStatusCode: string, ExpenseReportIDFK: int, ExpenseReportName: string, FileAttachmentIDFK: int, Firstname: string, Lastname: string, Merchant: string, MerchantTaxNumber: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaskIDFK: int, TaskTitle: string, TaxAmount: float, TaxIDFK: int, TaxName: string, TransactionTaxConfigCode: string, TransactionTaxConfigName: string, UserIDFK: int, isChargeable: bool, isOfficialExchangeRate: bool, isReimbursable: bool>, PageNumber: int, PageSize: int, TotalCount: int>
# operationId: Expense_Get
export def "expense-get" [
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
  --updated-after: string # format: date-time
  --expense-date-from: string # format: date-time
  --expense-date-to: string # format: date-time
  --user-email: string
  --user-id: int # format: int32
  --category-name: string
  --customer-id: int # format: int32
  --project-id: int # format: int32
  --is-chargeable: oneof<nothing, bool>
  --is-invoiced: oneof<nothing, bool>
  --expense-reimbursement-idfk: int # format: int64
  --expense-payment-method-idfk: int # format: int32
  --expense-approval-status-code: string
  --search: string
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --sort: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Expense"
    query: [{name: UpdatedAfter, var: updated_after}, {name: ExpenseDateFrom, var: expense_date_from}, {name: ExpenseDateTo, var: expense_date_to}, {name: UserEmail, var: user_email}, {name: UserID, var: user_id}, {name: CategoryName, var: category_name}, {name: CustomerID, var: customer_id}, {name: ProjectID, var: project_id}, {name: isChargeable, var: is_chargeable}, {name: isInvoiced, var: is_invoiced}, {name: ExpenseReimbursementIDFK, var: expense_reimbursement_idfk}, {name: ExpensePaymentMethodIDFK, var: expense_payment_method_idfk}, {name: ExpenseApprovalStatusCode, var: expense_approval_status_code}, {name: Search, var: search}, {name: pageSize, var: page_size}, {name: pageNumber, var: page_number}, {name: Sort, var: sort}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    updated_after: $updated_after, expense_date_from: $expense_date_from, expense_date_to: $expense_date_to, user_email: $user_email, user_id: $user_id, category_name: $category_name, customer_id: $customer_id, project_id: $project_id, is_chargeable: $is_chargeable, is_invoiced: $is_invoiced, expense_reimbursement_idfk: $expense_reimbursement_idfk, expense_payment_method_idfk: $expense_payment_method_idfk, expense_approval_status_code: $expense_approval_status_code, search: $search, page_size: $page_size, page_number: $page_number, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an Expense
#
# POST /api/Expense
# Returns: record<Amount: float, AttachmentPreviewURL: string, AttachmentURL: string, ChargeableStatusCode: string, CurrencyCode: string, CustomerIDFK: int, CustomerName: string, DateCreated: string, DateUpdated: string, Email: string, ExchangeRate: float, ExpenseApprovalStatusCode: string, ExpenseCategoryHasUnitPrice: bool, ExpenseCategoryIDFK: int, ExpenseCategoryName: string, ExpenseCategoryUnitName: string, ExpenseCategoryUnitPrice: float, ExpenseDate: string, ExpenseID: int, ExpensePaymentMethodIDFK: int, ExpensePaymentMethodName: string, ExpenseReimbursementIDFK: int, ExpenseReimbursementStatusCode: string, ExpenseReportIDFK: int, ExpenseReportName: string, FileAttachmentIDFK: int, Firstname: string, Lastname: string, Merchant: string, MerchantTaxNumber: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaskIDFK: int, TaskTitle: string, TaxAmount: float, TaxIDFK: int, TaxName: string, TransactionTaxConfigCode: string, TransactionTaxConfigName: string, UserIDFK: int, isChargeable: bool, isOfficialExchangeRate: bool, isReimbursable: bool>
# operationId: Expense_Post
export def "expense-post" [
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
  --amount: float # Expense Amount (Required). Must be >= 0 (format: double)
  --currency-code: string # A 3-letter ISO CurrencyCode for the expense currency. (e.g. USD). If not provided, defaults to the Account base currency.
  --customer-idfk: int # The Avaza Customer ID to associate the Expense with. Either this field or CustomerName can be provided. (format: int32)
  --customer-name: string # The name of an existing customer in Avaza. Must be an exact (case insensitive) match.
  --exchange-rate: float # Optional (Only relevant if the expense currency is different to your account currency. If not provided we will look up the market exchange rate for you based on the expense date.) Exchange Rate = Expense Currency Amount / Base Currency Amount (e.g. if Expense currency is in AUD, and Base Currency is in USD, Exchange Rate = AUD $140 / USD $100 = 1.4) (format: double)
  --expense-category-idfk: int # The expense category to link the Expense to. If not provided, ExpenseCategoryName must be provided (format: int32)
  --expense-category-name: string # Must match an existing expense category name otherwise a new category will be created. If left blank Expense Category ID must be provided.
  --expense-date: string # The date of the expense entry (Required) (format: date-time)
  --expense-payment-method-idfk: int # (Optional) ID of Expense Payment Method. (format: int32)
  --file-attachment-i-ds: list<int> # Array of File Attachment IDs to associate with this expense. The files need to have already been uploaded. Currently only accepts a single file.
  --group-trip-name: string # Links the expense to a Grouping/Trip report. If no matching name found, creates a new Group/Trip Report name.
  --merchant: string # The name of the merchant.
  --merchant-tax-number: string # A Tax number identifier for the merchant.
  --notes: string # Expense Notes
  --project-idfk: int # The Avaza project ID to associate the Expense with. (format: int32)
  --project-name: string # Can work for matching an expense to a project, but only if it's an exact match for a single project under the customer.
  --quantity: float # Conditional - available for expenses that are assigned a unit priced based expense category. e.g Mileage (format: double)
  --task-idfk: int # (optional) TaskID of a Task to link the new Expense to. A Customer and Project must be provided also. (format: int32)
  --tax-idfk: int # Avaza Tax ID the expense belongs to. If left blank then Tax Name must be provided. (format: int32)
  --tax-name: string # Must exactly match an existing Tax Name that you have configured in Avaza Tax settings. If left blank then Tax ID must be provided.
  --transaction-tax-config-code: string # Optional - Enter "INC" if the tax amount is included in the expense amount otherwise enter "EX" when the amount exlcudes the tax. Defaults to "Ex". The tax amount on the expense will be autocalculated.
  --user-email: string # The email address of a Timesheet/Expense user in Avaza. If not provided, UserIDFK field must be provided.
  --user-idfk: int # UserID for a Timesheet/Expense user in Avaza. If not provided, UserEmail field must be provided (format: int32)
  --verify-and-save: oneof<nothing, bool> # Pass false if creating a draft expense. True otherwise.
  --is-chargeable: oneof<nothing, bool> # aka Billable. Defaults to false if not provided. If set to true, a CustomerIDFK or CustomerName must be provided.
  --is-reimbursable: oneof<nothing, bool> # Defaults to false if not provided.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Expense"
    body: {content_type: "application/json", kind: json, fields: [{name: Amount, var: amount}, {name: CurrencyCode, var: currency_code}, {name: CustomerIDFK, var: customer_idfk}, {name: CustomerName, var: customer_name}, {name: ExchangeRate, var: exchange_rate}, {name: ExpenseCategoryIDFK, var: expense_category_idfk}, {name: ExpenseCategoryName, var: expense_category_name}, {name: ExpenseDate, var: expense_date}, {name: ExpensePaymentMethodIDFK, var: expense_payment_method_idfk}, {name: FileAttachmentIDs, var: file_attachment_i_ds}, {name: GroupTripName, var: group_trip_name}, {name: Merchant, var: merchant}, {name: MerchantTaxNumber, var: merchant_tax_number}, {name: Notes, var: notes}, {name: ProjectIDFK, var: project_idfk}, {name: ProjectName, var: project_name}, {name: Quantity, var: quantity}, {name: TaskIDFK, var: task_idfk}, {name: TaxIDFK, var: tax_idfk}, {name: TaxName, var: tax_name}, {name: TransactionTaxConfigCode, var: transaction_tax_config_code}, {name: UserEmail, var: user_email}, {name: UserIDFK, var: user_idfk}, {name: VerifyAndSave, var: verify_and_save}, {name: isChargeable, var: is_chargeable}, {name: isReimbursable, var: is_reimbursable}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    amount: $amount, currency_code: $currency_code, customer_idfk: $customer_idfk, customer_name: $customer_name, exchange_rate: $exchange_rate, expense_category_idfk: $expense_category_idfk, expense_category_name: $expense_category_name, expense_date: $expense_date, expense_payment_method_idfk: $expense_payment_method_idfk, file_attachment_i_ds: $file_attachment_i_ds, group_trip_name: $group_trip_name, merchant: $merchant, merchant_tax_number: $merchant_tax_number, notes: $notes, project_idfk: $project_idfk, project_name: $project_name, quantity: $quantity, task_idfk: $task_idfk, tax_idfk: $tax_idfk, tax_name: $tax_name, transaction_tax_config_code: $transaction_tax_config_code, user_email: $user_email, user_idfk: $user_idfk, verify_and_save: $verify_and_save, is_chargeable: $is_chargeable, is_reimbursable: $is_reimbursable
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an Expense
#
# PUT /api/Expense
# Returns: record<Amount: float, AttachmentPreviewURL: string, AttachmentURL: string, ChargeableStatusCode: string, CurrencyCode: string, CustomerIDFK: int, CustomerName: string, DateCreated: string, DateUpdated: string, Email: string, ExchangeRate: float, ExpenseApprovalStatusCode: string, ExpenseCategoryHasUnitPrice: bool, ExpenseCategoryIDFK: int, ExpenseCategoryName: string, ExpenseCategoryUnitName: string, ExpenseCategoryUnitPrice: float, ExpenseDate: string, ExpenseID: int, ExpensePaymentMethodIDFK: int, ExpensePaymentMethodName: string, ExpenseReimbursementIDFK: int, ExpenseReimbursementStatusCode: string, ExpenseReportIDFK: int, ExpenseReportName: string, FileAttachmentIDFK: int, Firstname: string, Lastname: string, Merchant: string, MerchantTaxNumber: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaskIDFK: int, TaskTitle: string, TaxAmount: float, TaxIDFK: int, TaxName: string, TransactionTaxConfigCode: string, TransactionTaxConfigName: string, UserIDFK: int, isChargeable: bool, isOfficialExchangeRate: bool, isReimbursable: bool>
# operationId: Expense_Put
export def "expense-put" [
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
  --amount: float # Expense Amount (Required). Must be >= 0 (format: double)
  --currency-code: string # A 3-letter ISO CurrencyCode for the expense currency. (e.g. USD). If not provided, defaults to the Account base currency.
  --customer-idfk: int # The Avaza Customer ID to associate the Expense with. (format: int32)
  --exchange-rate: float # Optional (Only relevant if the expense currency is different to your account currency. If not provided we will look up the market exchange rate for you based on the expense date.) Exchange Rate = Expense Currency Amount / Base Currency Amount (e.g. if Expense currency is in AUD, and Base Currency is in USD, Exchange Rate = AUD $140 / USD $100 = 1.4) (format: double)
  --expense-category-idfk: int # The expense category to link the Expense to. (format: int32)
  --expense-date: string # The date of the expense entry (format: date-time)
  expense_id: int # format: int64
  --expense-payment-method-idfk: int # (Optional) ID of Expense Payment Method. (format: int32)
  fields_to_update: list<string>
  --file-attachment-i-ds: list<int> # Array of File Attachment IDs to associate with this expense. The files need to have already been uploaded. Currently only accepts a single file.
  --group-trip-name: string # Links the expense to a Grouping/Trip report. If no matching name found, creates a new Group/Trip Report name.
  --merchant: string # The name of the merchant.
  --merchant-tax-number: string # A Tax number identifier for the merchant.
  --notes: string # Expense Notes
  --project-idfk: int # The Avaza project ID to associate the Expense with. (format: int32)
  --quantity: float # Conditional - available for expenses that are assigned a unit priced based expense category. e.g Mileage (format: double)
  --task-idfk: int # (optional) TaskID of a Task to link the new Expense to. A Customer and Project must be provided also. (format: int32)
  --tax-idfk: int # Avaza Tax ID the expense belongs to. (format: int32)
  --transaction-tax-config-code: string # Optional - Enter "INC" if the tax amount is included in the expense amount otherwise enter "EX" when the amount exlcudes the tax. Defaults to "Ex". The tax amount on the expense will be autocalculated.
  --verify-and-save: oneof<nothing, bool> # Pass false if creating a draft expense. True otherwise.
  --is-chargeable: oneof<nothing, bool> # aka Billable. Defaults to false if not provided. If set to true, a CustomerIDFK or CustomerName must be provided.
  --is-reimbursable: oneof<nothing, bool> # Defaults to false if not provided.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/Expense"
    body: {content_type: "application/json", kind: json, fields: [{name: Amount, var: amount}, {name: CurrencyCode, var: currency_code}, {name: CustomerIDFK, var: customer_idfk}, {name: ExchangeRate, var: exchange_rate}, {name: ExpenseCategoryIDFK, var: expense_category_idfk}, {name: ExpenseDate, var: expense_date}, {name: ExpenseID, var: expense_id}, {name: ExpensePaymentMethodIDFK, var: expense_payment_method_idfk}, {name: FieldsToUpdate, var: fields_to_update}, {name: FileAttachmentIDs, var: file_attachment_i_ds}, {name: GroupTripName, var: group_trip_name}, {name: Merchant, var: merchant}, {name: MerchantTaxNumber, var: merchant_tax_number}, {name: Notes, var: notes}, {name: ProjectIDFK, var: project_idfk}, {name: Quantity, var: quantity}, {name: TaskIDFK, var: task_idfk}, {name: TaxIDFK, var: tax_idfk}, {name: TransactionTaxConfigCode, var: transaction_tax_config_code}, {name: VerifyAndSave, var: verify_and_save}, {name: isChargeable, var: is_chargeable}, {name: isReimbursable, var: is_reimbursable}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    amount: $amount, currency_code: $currency_code, customer_idfk: $customer_idfk, exchange_rate: $exchange_rate, expense_category_idfk: $expense_category_idfk, expense_date: $expense_date, expense_id: $expense_id, expense_payment_method_idfk: $expense_payment_method_idfk, fields_to_update: $fields_to_update, file_attachment_i_ds: $file_attachment_i_ds, group_trip_name: $group_trip_name, merchant: $merchant, merchant_tax_number: $merchant_tax_number, notes: $notes, project_idfk: $project_idfk, quantity: $quantity, task_idfk: $task_idfk, tax_idfk: $tax_idfk, transaction_tax_config_code: $transaction_tax_config_code, verify_and_save: $verify_and_save, is_chargeable: $is_chargeable, is_reimbursable: $is_reimbursable
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/Expense/Attachment
#
# Returns: record<FileAttachments: table<FileAttachmentID: int, OriginalFilename: string, PreviewBaseURL: string, PublicFileURL: string, SizeBytes: int>>
# operationId: ExpenseAttachment
export def "expense-attachment" [
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
  file: path # Upload software package
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Expense/Attachment"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: File, var: file}], files: [File]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets an Expense Entry by Expense ID
#
# GET /api/Expense/{id}
# Returns: record<Amount: float, AttachmentPreviewURL: string, AttachmentURL: string, ChargeableStatusCode: string, CurrencyCode: string, CustomerIDFK: int, CustomerName: string, DateCreated: string, DateUpdated: string, Email: string, ExchangeRate: float, ExpenseApprovalStatusCode: string, ExpenseCategoryHasUnitPrice: bool, ExpenseCategoryIDFK: int, ExpenseCategoryName: string, ExpenseCategoryUnitName: string, ExpenseCategoryUnitPrice: float, ExpenseDate: string, ExpenseID: int, ExpensePaymentMethodIDFK: int, ExpensePaymentMethodName: string, ExpenseReimbursementIDFK: int, ExpenseReimbursementStatusCode: string, ExpenseReportIDFK: int, ExpenseReportName: string, FileAttachmentIDFK: int, Firstname: string, Lastname: string, Merchant: string, MerchantTaxNumber: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaskIDFK: int, TaskTitle: string, TaxAmount: float, TaxIDFK: int, TaxName: string, TransactionTaxConfigCode: string, TransactionTaxConfigName: string, UserIDFK: int, isChargeable: bool, isOfficialExchangeRate: bool, isReimbursable: bool>
# operationId: Expense_GetByID
export def "expense-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Expense/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Submit Expenses for Approval.
#
# POST /api/ExpenseApproval/Submit
# Returns: record
# operationId: ExpenseApproval
export def "expense-approval" [
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
  --user-id: int # The user to submit the Expenses for. Defaults to current user. Only allowed to be different from the current user when the current user has rights to Impersonate other users. (format: int32)
  --send-notifications: oneof<nothing, bool> # Send email alerts to expense approvers. Defaults to true
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/ExpenseApproval/Submit"
    query: [{name: UserID, var: user_id}, {name: SendNotifications, var: send_notifications}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, send_notifications: $send_notifications, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Expense Categories
#
# GET /api/ExpenseCategory
# Returns: record<Categories: table<Enabled: bool, ExpenseCategoryID: int, Name: string, UnitName: string, UnitPrice: float, hasUnitPrice: bool>>
# operationId: ExpenseCategory_Get
export def "expense-category-get" [
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
  --is-enabled: oneof<nothing, bool> # Optional filter on for enabled/disabled categories. Defaults to true.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ExpenseCategory"
    query: [{name: isEnabled, var: is_enabled}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    is_enabled: $is_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets minimal list of Expense Groups.
#
# GET /api/ExpenseGroup/Lookup
# Returns: record<ExpenseGroups: table<ExpenseGroupID: int, Name: string>, PageNumber: int, PageSize: int, TotalCount: int>
# operationId: ExpenseGroupLookup
export def "expense-group-lookup" [
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
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --search: string # Search string to match against Expense Group Name
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ExpenseGroup/Lookup"
    query: [{name: pageSize, var: page_size}, {name: pageNumber, var: page_number}, {name: search, var: search}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_number: $page_number, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets minimal list of Expense Merchants.
#
# GET /api/ExpenseMerchant/Lookup
# Returns: record<ExpenseMerchants: table<MerchantName: string>, PageNumber: int, PageSize: int, TotalCount: int>
# operationId: ExpenseMerchangeLookup
export def "expense-merchange-lookup" [
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
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --search: string # Search string to match against Expense Group Name
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ExpenseMerchant/Lookup"
    query: [{name: pageSize, var: page_size}, {name: pageNumber, var: page_number}, {name: search, var: search}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_number: $page_number, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets minimal list of Expense Payment Methods.
#
# GET /api/ExpensePaymentMethod/Lookup
# Returns: record<ExpensePaymentMethods: table<ExpensePaymentMethodID: int, Name: string>>
# operationId: ExpensePaymentMethodLookup
export def "expense-payment-method-lookup" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ExpensePaymentMethod/Lookup"
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets Basic Summary of Expense Statistics
#
# GET /api/ExpenseSummary
# Returns: record<ExpenseDateFrom: string, ExpenseDateTo: string, GroupData: table<GroupData: list, GroupID: string, GroupName: string, TotalAmount: float>, GroupingLevels: list<string>, TotalAmount: float, UserID: list<int>>
# operationId: ExpenseSummary_Get
export def "expense-summary-get" [
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
  --model-group-by: list<string> # (Optional) Combine one, two or three levels of Grouping. Combine these possible grouping values: "Category", "ChargeableStatus", "Merchant", "ApprovalStatus", "ReimbursementStatus", "Customer", "Project", "User", "Task", "Year", "Month", "Day", "Week".
  --model-expense-date-from: string # (Required) Filter for expenses with expense dates greater or equal to the specified date. e.g. 2019-01-25. (format: date-time)
  --model-expense-date-to: string # (Required) Filter for expenses with an expense date smaller or equal to the specified date. e.g. 2019-01-25. (format: date-time)
  --model-user-id: list<int> # (Optional) Defaults to the current user. Provide one or more UserIDs of Users whose expenses should be retrieved. If the current user doesn't have impersonation rights, then they will only see their own data.
  --model-project-id: int # (Optional) Filter by Project (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ExpenseSummary"
    query: [{name: "model.groupBy", var: model_group_by, style: multi}, {name: "model.expenseDateFrom", var: model_expense_date_from}, {name: "model.expenseDateTo", var: model_expense_date_to}, {name: "model.userID", var: model_user_id, style: multi}, {name: "model.projectID", var: model_project_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    model_group_by: $model_group_by, model_expense_date_from: $model_expense_date_from, model_expense_date_to: $model_expense_date_to, model_user_id: $model_user_id, model_project_id: $model_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Fixed Amounts
#
# GET /api/FixedAmount
# Returns: record<FixedAmounts: table<Amount: float, DateCreated: string, DateUpdated: string, FixedAmountID: int, InventoryItemIDFK: int, InventoryItemName: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, TaskIDFK: int, TaskTitle: string, UpdatedByUserIDFK: int, isInvoiced: bool>, PageNumber: int, PageSize: int, TotalCount: int>
# operationId: FixedAmount_Get
export def "fixed-amount-get" [
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
  --updated-after: string # format: date-time
  --entry-date-from: string # format: date-time
  --entry-date-to: string # format: date-time
  --project-id: int # (Optional) The ProjectID of a Project to filter Fixed Amounts for (format: int32)
  --task-id: int # (Optional) The TaskID of a Task to filter Fixed Amounts for (format: int32)
  --is-invoiced: oneof<nothing, bool>
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --sort: string # Optional sorting instruction. Currently possible values: "DateUpdated", "DateCreated", "DateUpdated desc", "DateCreated desc","EntryDate", "EntryDate desc", "StartTimeLocal","StartTimeLocal desc", "TimeSheetEntryID", "TimeSheetEntryID desc"
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/FixedAmount"
    query: [{name: UpdatedAfter, var: updated_after}, {name: EntryDateFrom, var: entry_date_from}, {name: EntryDateTo, var: entry_date_to}, {name: ProjectID, var: project_id}, {name: TaskID, var: task_id}, {name: isInvoiced, var: is_invoiced}, {name: pageSize, var: page_size}, {name: pageNumber, var: page_number}, {name: Sort, var: sort}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    updated_after: $updated_after, entry_date_from: $entry_date_from, entry_date_to: $entry_date_to, project_id: $project_id, task_id: $task_id, is_invoiced: $is_invoiced, page_size: $page_size, page_number: $page_number, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Inventory
#
# GET /api/Inventory
# Returns: record<Inventory: table<CostPrice: float, DateCreated: string, DateUpdated: string, Description: string, InventoryItemID: int, Name: string, SKU: string, SalePrice: float, SaleTaxIDFK: int, isHidden: bool>, PageNumber: int, PageSize: int, TotalCount: int>
# operationId: Inventory_Get
export def "inventory-get" [
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
  --updated-after: string # format: date-time
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Inventory"
    query: [{name: UpdatedAfter, var: updated_after}, {name: pageSize, var: page_size}, {name: pageNumber, var: page_number}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    updated_after: $updated_after, page_size: $page_size, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets InventoryItem by InventoryItem ID
#
# GET /api/Inventory/{id}
# operationId: Inventory_GetByID
export def "inventory-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: get
    path: "/api/Inventory/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Invoices
#
# GET /api/Invoice
# Returns: record<Invoices: table<AccountIDFK: int, Balance: float, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, CustomerPONumber: string, DateCreated: string, DateIssued: string, DateSent: string, DateUpdated: string, DueDate: string, ExchangeRate: float, InvoiceNumber: string, Issuer: record, LineItems: list, Links: record, Notes: string, Recipient: record, Subject: string, TaxAmount: float, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string, TransactionTaxConfigCode: string>, PageNumber: int, PageSize: int, TotalCount: int>
# operationId: Invoice_Get
export def "invoice-get" [
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
  --updated-after: string # format: date-time
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --sort: string
  --company-idfk: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Invoice"
    query: [{name: UpdatedAfter, var: updated_after}, {name: pageSize, var: page_size}, {name: pageNumber, var: page_number}, {name: Sort, var: sort}, {name: CompanyIDFK, var: company_idfk}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    updated_after: $updated_after, page_size: $page_size, page_number: $page_number, sort: $sort, company_idfk: $company_idfk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new draft invoice
#
# POST /api/Invoice
# Returns: record<AccountIDFK: int, Balance: float, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, CustomerPONumber: string, DateCreated: string, DateIssued: string, DateSent: string, DateUpdated: string, DueDate: string, ExchangeRate: float, InvoiceNumber: string, Issuer: record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, TaxNumber: string>, LineItems: table<Amount: float, Description: string, Discount: float, InventoryItemIDFK: int, InventoryItemName: string, InventoryItemSKU: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaxAmount: float, TaxCode: string, TaxIDFK: int, TaxName: string, TransactionLineItemID: int, UnitPrice: float>, Links: record<ClientView: string, Edit: string, View: string>, Notes: string, Recipient: record<CompanyIDFK: int, CompanyName: string, RecipientBillingAddressCity: string, RecipientBillingAddressCountryCode: string, RecipientBillingAddressLine: string, RecipientBillingAddressPostCode: string, RecipientBillingAddressState: string, RecipientFormattedBillingAddress: string>, Subject: string, TaxAmount: float, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string, TransactionTaxConfigCode: string>
# operationId: Invoice_Post
export def "invoice-post" [
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
  --company-idfk: int # If left blank then you must specify Company Name. (format: int32)
  --company-name: string # If left blank then you must specify Company ID. Specified Name will be used to match existing customer record. If not matched then it will be used to create a new customer. First Name, Last Name and Email will only be used if it is a new company. If the Company name appears multiple times we will check the email address to find a matching company. If email address doesn't identify a matching company then the invoice creation will be rejected.
  --currency-code: string # Expects ISO Standard 3 character currency code. If left blank the currency will default to account's currency in general setting. For existing companies this field will be ignored and the invoice will use the currency of the customer. For new customers if the currency is not specified then account currency will be used otherwise the specified currency will be used.
  --customer-po-number: string # Plain UTF8 text. 100 characters max
  --date-issued: string # If not specified it will use today's date. The date should be specified as local date. (format: date-time)
  --due-date: string # It will be auto calculated based on the payment term and issue date. Due Date must be greater than or equal to Issue Date. If the Due Date is specified then Payment Terms will be set to -1 (Custom) (format: date-time)
  --email: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --exchange-rate: float # Exchange rate is only valid for invoices in currency other than default account currency. If not specified it will get the market rate based on the Date Issued. (format: double)
  --firstname: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --invoice-number: string # Pass any string. If left blank it will use the next number in the auto incrementing sequence. If an integer is passed then the largest integer will be use as the seed to auto generate the next invoice number in the sequence.
  --invoice-template-idfk: int # If left blank the account default invoice template will be used. (format: int32)
  --lastname: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --line-items: list # item shape: {Description?: string, Discount?: float, InventoryItemIDFK?: int, InventoryItemName?: string, ProjectIDFK?: int, Quantity: float, TaxIDFK?: int, TaxName?: string, TaxPercent?: float, UnitPrice: float}
  --notes: string # Plain UTF8 text. (no HTML). Max 2000 characters
  --payment-terms: int # "If left blank we will set it to customer default. If specified then it must match one of your existing pre configured payment term periods. Your account starts with: (-1 --- Custom, 0 --- Upon Receipt, 7 --- 7 Days, 15 --- 15 Days, 30 --- 30 Days, 45 --- 45 Days, 60 --- 60 Days) (format: int32)
  --subject: string # Plain UTF8 text. (no HTML). 255 characters max
  --transaction-prefix: string # A prefix for the Invoice number. e.g. 'INV'. If left blank it will be set to the account default. Max length 20 characters.
  --transaction-tax-config-code: string # Possible values are (EX --- Tax Exclusive, INC --- Tax Inclusive). If left empty it will use the account default.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Invoice"
    body: {content_type: "application/json", kind: json, fields: [{name: CompanyIDFK, var: company_idfk}, {name: CompanyName, var: company_name}, {name: CurrencyCode, var: currency_code}, {name: CustomerPONumber, var: customer_po_number}, {name: DateIssued, var: date_issued}, {name: DueDate, var: due_date}, {name: Email, var: email}, {name: ExchangeRate, var: exchange_rate}, {name: Firstname, var: firstname}, {name: InvoiceNumber, var: invoice_number}, {name: InvoiceTemplateIDFK, var: invoice_template_idfk}, {name: Lastname, var: lastname}, {name: LineItems, var: line_items}, {name: Notes, var: notes}, {name: PaymentTerms, var: payment_terms}, {name: Subject, var: subject}, {name: TransactionPrefix, var: transaction_prefix}, {name: TransactionTaxConfigCode, var: transaction_tax_config_code}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    company_idfk: $company_idfk, company_name: $company_name, currency_code: $currency_code, customer_po_number: $customer_po_number, date_issued: $date_issued, due_date: $due_date, email: $email, exchange_rate: $exchange_rate, firstname: $firstname, invoice_number: $invoice_number, invoice_template_idfk: $invoice_template_idfk, lastname: $lastname, line_items: $line_items, notes: $notes, payment_terms: $payment_terms, subject: $subject, transaction_prefix: $transaction_prefix, transaction_tax_config_code: $transaction_tax_config_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets Invoice by Invoice ID
#
# GET /api/Invoice/{id}
# operationId: Invoice_GetByID
export def "invoice-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: get
    path: "/api/Invoice/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: []
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Payments
#
# GET /api/Payment
# Returns: record<PageNumber: int, PageSize: int, Payments: table<AccountIDFK: int, Balance: float, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: list, PaymentNumber: string, PaymentProviderCode: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string>, TotalCount: int>
# operationId: Payment_Get
export def "payment-get" [
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
  --updated-after: string # format: date-time
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Payment"
    query: [{name: UpdatedAfter, var: updated_after}, {name: pageSize, var: page_size}, {name: pageNumber, var: page_number}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    updated_after: $updated_after, page_size: $page_size, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create new Payment and optionally assign payment allocations to Invoices
#
# POST /api/Payment
# Returns: record<AccountIDFK: int, Balance: float, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: table<AllocationAmount: float, AllocationDate: string, InvoiceTransactionIDFK: int, PaymentTransactionIDFK: int, TransactionAllocationID: int>, PaymentNumber: string, PaymentProviderCode: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string>
# operationId: Payment_Post
export def "payment-post" [
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
  --amount: float # format: double
  --customer-idfk: int # Only required if no invoice allocations specified. (format: int32)
  --date-issued: string # Date of Payment. If not specified, assumes today. (format: date-time)
  --exchange-rate: float # Optional. Only used when the Customer's currecy is different from the Avaza account's base currency. Specifies the exchange rate that should apply between the customer currency and base currency. If not provided we will obtain an up to date exchange rate for the Payment Issue Date. (format: double)
  --notes: string
  --payment-allocations: list # List of amounts within this payment that are allocated to invoices. The sum of these be less than or equal to the payment amount. — item shape: {AllocationAmount?: float, AllocationDate?: string, InvoiceTransactionIDFK?: int}
  --payment-number: string # Optional. If not specified will be automatically generated
  --payment-provider-code: string # Optional for storing the payment provider who was the source of funds.
  --transaction-prefix: string # Optional to override the default prefix added to Payment Numbers
  --transaction-reference: string # Optional for storing the reference # of the payment method.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Payment"
    body: {content_type: "application/json", kind: json, fields: [{name: Amount, var: amount}, {name: CustomerIDFK, var: customer_idfk}, {name: DateIssued, var: date_issued}, {name: ExchangeRate, var: exchange_rate}, {name: Notes, var: notes}, {name: PaymentAllocations, var: payment_allocations}, {name: PaymentNumber, var: payment_number}, {name: PaymentProviderCode, var: payment_provider_code}, {name: TransactionPrefix, var: transaction_prefix}, {name: TransactionReference, var: transaction_reference}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    amount: $amount, customer_idfk: $customer_idfk, date_issued: $date_issued, exchange_rate: $exchange_rate, notes: $notes, payment_allocations: $payment_allocations, payment_number: $payment_number, payment_provider_code: $payment_provider_code, transaction_prefix: $transaction_prefix, transaction_reference: $transaction_reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets Payment by Payment Transaction ID
#
# GET /api/Payment/{id}
# Returns: record<AccountIDFK: int, Balance: float, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: table<AllocationAmount: float, AllocationDate: string, InvoiceTransactionIDFK: int, PaymentTransactionIDFK: int, TransactionAllocationID: int>, PaymentNumber: string, PaymentProviderCode: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string>
# operationId: Payment_GetByID
export def "payment-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Payment/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Projects
#
# GET /api/Project
# Returns: record<PageNumber: int, PageSize: int, Projects: table<CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, DefaultAccountTaskTypeIDFK: int, DefaultAccountTaskTypeName: string, Notes: string, ProjectCategoryIDFK: int, ProjectCategoryName: string, ProjectCode: string, ProjectID: int, ProjectOwnerUserIDFK: int, Title: string, isArchived: bool, isTaskRequiredOnTimesheet: bool>, TotalCount: int>
# operationId: Project_Get
export def "project-get" [
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
  --updated-after: string # Only show project records updated after a certain date (UTC) (format: date-time)
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --sort: string # A column to sort on. Current possible values: "DateUpdated", "DateCreated", "DateUpdated desc", "DateCreated desc"
  --timesheet-user-id: int # Filter to the projects that the supplied UserID can add timesheets to (format: int32)
  --include-archived: oneof<nothing, bool> # Include Archived Projects in the results
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Project"
    query: [{name: UpdatedAfter, var: updated_after}, {name: pageSize, var: page_size}, {name: pageNumber, var: page_number}, {name: Sort, var: sort}, {name: TimesheetUserID, var: timesheet_user_id}, {name: includeArchived, var: include_archived}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    updated_after: $updated_after, page_size: $page_size, page_number: $page_number, sort: $sort, timesheet_user_id: $timesheet_user_id, include_archived: $include_archived
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a Project
#
# POST /api/Project
# Returns: record<BudgetAmount: float, BudgetHours: float, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, DefaultAccountTaskTypeIDFK: int, DefaultAccountTaskTypeName: string, EndDate: string, Members: table<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>, Notes: string, ProjectBillableTypeCode: string, ProjectBudgetTypeCode: string, ProjectCategoryColor: string, ProjectCategoryIDFK: int, ProjectCategoryName: string, ProjectCode: string, ProjectHourlyRate: float, ProjectID: int, ProjectOwnerUserIDFK: int, ProjectStatusCode: string, ProjectTags: table<Name: string, ProjectTagID: int>, Sections: table<DisplayOrder: int, EndDate: string, SectionID: int, StartDate: string, Title: string>, StartDate: string, Title: string, isArchived: bool, isTaskRequiredOnTimesheet: bool>
# operationId: Project_Post
export def "project-post" [
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
  --budget-amount: float # format: double
  --budget-hours: float # format: double
  --company-idfk: int # An ID of a company in Avaza to create the Project under. You must provide either a CompanyID, or a CompanyName (format: int32)
  --company-name: string # The name for a Company to create the project under. Will create company unless it matches an existing company name
  --currency-code: string # The ISO 3 letter currency code to use when creating a new Company. If not provided, the account's default currency will be used.
  --end-date: string # format: date-time
  --populate-default-project-members: oneof<nothing, bool> # Defaults to true.
  --project-category-idfk: int # format: int32
  --project-code: string # Used when Manual Project Codes are enabled
  --project-notes: string # Any descriptive notes about the project. (2000 characters max)
  --project-status-code: string
  project_title: string # The title of the new project. (255 characters max)
  --start-date: string # format: date-time
  --timesheet-approval-requiredby-default: oneof<nothing, bool>
  --is-task-required-on-timesheet: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Project"
    body: {content_type: "application/json", kind: json, fields: [{name: BudgetAmount, var: budget_amount}, {name: BudgetHours, var: budget_hours}, {name: CompanyIDFK, var: company_idfk}, {name: CompanyName, var: company_name}, {name: CurrencyCode, var: currency_code}, {name: EndDate, var: end_date}, {name: PopulateDefaultProjectMembers, var: populate_default_project_members}, {name: ProjectCategoryIDFK, var: project_category_idfk}, {name: ProjectCode, var: project_code}, {name: ProjectNotes, var: project_notes}, {name: ProjectStatusCode, var: project_status_code}, {name: ProjectTitle, var: project_title}, {name: StartDate, var: start_date}, {name: TimesheetApprovalRequiredbyDefault, var: timesheet_approval_requiredby_default}, {name: isTaskRequiredOnTimesheet, var: is_task_required_on_timesheet}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    budget_amount: $budget_amount, budget_hours: $budget_hours, company_idfk: $company_idfk, company_name: $company_name, currency_code: $currency_code, end_date: $end_date, populate_default_project_members: $populate_default_project_members, project_category_idfk: $project_category_idfk, project_code: $project_code, project_notes: $project_notes, project_status_code: $project_status_code, project_title: $project_title, start_date: $start_date, timesheet_approval_requiredby_default: $timesheet_approval_requiredby_default, is_task_required_on_timesheet: $is_task_required_on_timesheet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an Project
#
# PUT /api/Project
# Returns: record<BudgetAmount: float, BudgetHours: float, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, DefaultAccountTaskTypeIDFK: int, DefaultAccountTaskTypeName: string, EndDate: string, Members: table<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>, Notes: string, ProjectBillableTypeCode: string, ProjectBudgetTypeCode: string, ProjectCategoryColor: string, ProjectCategoryIDFK: int, ProjectCategoryName: string, ProjectCode: string, ProjectHourlyRate: float, ProjectID: int, ProjectOwnerUserIDFK: int, ProjectStatusCode: string, ProjectTags: table<Name: string, ProjectTagID: int>, Sections: table<DisplayOrder: int, EndDate: string, SectionID: int, StartDate: string, Title: string>, StartDate: string, Title: string, isArchived: bool, isTaskRequiredOnTimesheet: bool>
# operationId: Project_Put
export def "project-put" [
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
  --budget-amount: float # format: double
  --budget-hours: float # format: double
  --end-date: string # format: date-time
  --fields-to-update: list<string>
  --project-billable-type-code: string # The billing method of the project. (string, optional) Possible values: CategoryHourly, NoRate, NotBillable, PersonHourly, ProjectHourly
  --project-budget-type-code: string # The project budgeting type. (string, optional) Possible values: NoBudget, PersonHours, ProjectFees, ProjectHours, CategoryHours
  --project-category-idfk: int # format: int32
  --project-id: int # The ID of the Project to update (format: int32)
  --project-notes: string # (optional) Any descriptive notes about the project. (2000 characters max)
  --project-status-code: string # Update the project status (string, optional): (Possible values: NotStarted, InProgress, Complete, OnHold)
  --project-title: string # (optional) An updated project title. (255 characters max)
  --start-date: string # format: date-time
  --timesheet-approval-requiredby-default: oneof<nothing, bool> # Whether timesheet approval should be required by default for newly added project members.
  --is-task-required-on-timesheet: oneof<nothing, bool> # Whether timesheets entered against this project require a task to be selected.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/Project"
    body: {content_type: "application/json", kind: json, fields: [{name: BudgetAmount, var: budget_amount}, {name: BudgetHours, var: budget_hours}, {name: EndDate, var: end_date}, {name: FieldsToUpdate, var: fields_to_update}, {name: ProjectBillableTypeCode, var: project_billable_type_code}, {name: ProjectBudgetTypeCode, var: project_budget_type_code}, {name: ProjectCategoryIDFK, var: project_category_idfk}, {name: ProjectID, var: project_id}, {name: ProjectNotes, var: project_notes}, {name: ProjectStatusCode, var: project_status_code}, {name: ProjectTitle, var: project_title}, {name: StartDate, var: start_date}, {name: TimesheetApprovalRequiredbyDefault, var: timesheet_approval_requiredby_default}, {name: isTaskRequiredOnTimesheet, var: is_task_required_on_timesheet}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    budget_amount: $budget_amount, budget_hours: $budget_hours, end_date: $end_date, fields_to_update: $fields_to_update, project_billable_type_code: $project_billable_type_code, project_budget_type_code: $project_budget_type_code, project_category_idfk: $project_category_idfk, project_id: $project_id, project_notes: $project_notes, project_status_code: $project_status_code, project_title: $project_title, start_date: $start_date, timesheet_approval_requiredby_default: $timesheet_approval_requiredby_default, is_task_required_on_timesheet: $is_task_required_on_timesheet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets minimal list of active Projects for the current user
#
# GET /api/Project/Lookup
# Returns: record<PageSize: int, companies: table<CompanyID: int, CompanyName: string, projects: list>, hasMore: bool, pageNumber: int>
# operationId: ProjectLookup
export def "project-lookup" [
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
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --timesheet-user-id: int # Optionally Filter to the projects that the supplied UserID can add timesheets to (format: int32)
  --company-idfk: int # Optionally Filter for a specific Company ID (format: int32)
  --search: string # Search string to match against Project title and Customer name
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Project/Lookup"
    query: [{name: pageSize, var: page_size}, {name: pageNumber, var: page_number}, {name: TimesheetUserID, var: timesheet_user_id}, {name: CompanyIDFK, var: company_idfk}, {name: search, var: search}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_number: $page_number, timesheet_user_id: $timesheet_user_id, company_idfk: $company_idfk, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets Project by Project ID
#
# GET /api/Project/{id}
# Returns: record<BudgetAmount: float, BudgetHours: float, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, DefaultAccountTaskTypeIDFK: int, DefaultAccountTaskTypeName: string, EndDate: string, Members: table<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>, Notes: string, ProjectBillableTypeCode: string, ProjectBudgetTypeCode: string, ProjectCategoryColor: string, ProjectCategoryIDFK: int, ProjectCategoryName: string, ProjectCode: string, ProjectHourlyRate: float, ProjectID: int, ProjectOwnerUserIDFK: int, ProjectStatusCode: string, ProjectTags: table<Name: string, ProjectTagID: int>, Sections: table<DisplayOrder: int, EndDate: string, SectionID: int, StartDate: string, Title: string>, StartDate: string, Title: string, isArchived: bool, isTaskRequiredOnTimesheet: bool>
# operationId: Project_GetByID
export def "project-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Project/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Project Members
#
# GET /api/ProjectMember
# Returns: record<ProjectMembers: table<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>>
# operationId: ProjectMember_Get
export def "project-member-get" [
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
  --project-id: int # Get Project members filtered by ProjectID (format: int32)
  --user-id: int # Get Project members filtered by UserID (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ProjectMember"
    query: [{name: ProjectID, var: project_id}, {name: UserID, var: user_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Assign a user as a Member of a Project
#
# POST /api/ProjectMember
# Returns: record<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>
# operationId: ProjectMember_Post
export def "project-member-post" [
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
  --budget-amount: float # Optional (format: double)
  --cost-amount: float # Optional. If not provided, defaults to the User's default Cost Amount. (format: double)
  --project-idfk: int # Required. The ProjectID (format: int32)
  --rate-amount: float # Optional. If not provided, defaults to the User's default Rate Amount. (format: double)
  --user-idfk: int # Required. The UserID to assign (format: int32)
  --can-comment-on-tasks: oneof<nothing, bool>
  --can-create-tasks: oneof<nothing, bool>
  --can-delete-tasks: oneof<nothing, bool>
  --can-update-tasks: oneof<nothing, bool>
  --is-project-manager: oneof<nothing, bool>
  --is-timesheet-allowed: oneof<nothing, bool>
  --is-timesheet-approval-required: oneof<nothing, bool>
  --is-timesheet-approver: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/ProjectMember"
    body: {content_type: "application/json", kind: json, fields: [{name: BudgetAmount, var: budget_amount}, {name: CostAmount, var: cost_amount}, {name: ProjectIDFK, var: project_idfk}, {name: RateAmount, var: rate_amount}, {name: UserIDFK, var: user_idfk}, {name: canCommentOnTasks, var: can_comment_on_tasks}, {name: canCreateTasks, var: can_create_tasks}, {name: canDeleteTasks, var: can_delete_tasks}, {name: canUpdateTasks, var: can_update_tasks}, {name: isProjectManager, var: is_project_manager}, {name: isTimesheetAllowed, var: is_timesheet_allowed}, {name: isTimesheetApprovalRequired, var: is_timesheet_approval_required}, {name: isTimesheetApprover, var: is_timesheet_approver}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    budget_amount: $budget_amount, cost_amount: $cost_amount, project_idfk: $project_idfk, rate_amount: $rate_amount, user_idfk: $user_idfk, can_comment_on_tasks: $can_comment_on_tasks, can_create_tasks: $can_create_tasks, can_delete_tasks: $can_delete_tasks, can_update_tasks: $can_update_tasks, is_project_manager: $is_project_manager, is_timesheet_allowed: $is_timesheet_allowed, is_timesheet_approval_required: $is_timesheet_approval_required, is_timesheet_approver: $is_timesheet_approver
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a Member of a Project
#
# PUT /api/ProjectMember
# Returns: record<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>
# operationId: ProjectMember_Put
export def "project-member-put" [
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
  --budget-amount: float # A new Budget Amount. Defaults to null. (format: double)
  --cost-amount: float # A new Cost Amount. Defaults to null. (format: double)
  fields_to_update: list<string> # A string array of field names to be updated.
  project_idfk: int # Required. The ProjectID (format: int32)
  --rate-amount: float # A new Rate Amount. Defaults to null. (format: double)
  user_idfk: int # Required. The UserID (format: int32)
  --can-comment-on-tasks: oneof<nothing, bool>
  --can-create-tasks: oneof<nothing, bool>
  --can-delete-tasks: oneof<nothing, bool>
  --can-update-tasks: oneof<nothing, bool>
  --is-project-manager: oneof<nothing, bool>
  --is-timesheet-allowed: oneof<nothing, bool>
  --is-timesheet-approval-required: oneof<nothing, bool>
  --is-timesheet-approver: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/ProjectMember"
    body: {content_type: "application/json", kind: json, fields: [{name: BudgetAmount, var: budget_amount}, {name: CostAmount, var: cost_amount}, {name: FieldsToUpdate, var: fields_to_update}, {name: ProjectIDFK, var: project_idfk}, {name: RateAmount, var: rate_amount}, {name: UserIDFK, var: user_idfk}, {name: canCommentOnTasks, var: can_comment_on_tasks}, {name: canCreateTasks, var: can_create_tasks}, {name: canDeleteTasks, var: can_delete_tasks}, {name: canUpdateTasks, var: can_update_tasks}, {name: isProjectManager, var: is_project_manager}, {name: isTimesheetAllowed, var: is_timesheet_allowed}, {name: isTimesheetApprovalRequired, var: is_timesheet_approval_required}, {name: isTimesheetApprover, var: is_timesheet_approver}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    budget_amount: $budget_amount, cost_amount: $cost_amount, fields_to_update: $fields_to_update, project_idfk: $project_idfk, rate_amount: $rate_amount, user_idfk: $user_idfk, can_comment_on_tasks: $can_comment_on_tasks, can_create_tasks: $can_create_tasks, can_delete_tasks: $can_delete_tasks, can_update_tasks: $can_update_tasks, is_project_manager: $is_project_manager, is_timesheet_allowed: $is_timesheet_allowed, is_timesheet_approval_required: $is_timesheet_approval_required, is_timesheet_approver: $is_timesheet_approver
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Project Timesheet Categories
#
# GET /api/ProjectTimesheetCategory
# Returns: record<Categories: table<AccountIDFK: int, BudgetHours: float, CostAmount: float, Name: string, ProjectIDFK: int, RateAmount: float, TimeSheetCategoryIDFK: int, isBillable: bool, isDisabled: bool, isPayable: bool>>
# operationId: ProjectTimesheetCategory_Get
export def "project-timesheet-category-get" [
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
  --project-id: int # Get categories filtered by ProjectID (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ProjectTimesheetCategory"
    query: [{name: ProjectID, var: project_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Assign a TimeSheetCategory to a Project.
#
# POST /api/ProjectTimesheetCategory
# Returns: record<AccountIDFK: int, BudgetHours: float, CostAmount: float, Name: string, ProjectIDFK: int, RateAmount: float, TimeSheetCategoryIDFK: int, isBillable: bool, isDisabled: bool, isPayable: bool>
# operationId: ProjectTimesheetCategory_Post
export def "project-timesheet-category-post" [
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
  --budget-hours: float # format: double
  --cost-amount: float # format: double
  --project-idfk: int # format: int32
  --rate-amount: float # format: double
  --timesheet-category-idfk: int # format: int32
  --is-billable: oneof<nothing, bool>
  --is-payable: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/ProjectTimesheetCategory"
    body: {content_type: "application/json", kind: json, fields: [{name: BudgetHours, var: budget_hours}, {name: CostAmount, var: cost_amount}, {name: ProjectIDFK, var: project_idfk}, {name: RateAmount, var: rate_amount}, {name: TimesheetCategoryIDFK, var: timesheet_category_idfk}, {name: isBillable, var: is_billable}, {name: isPayable, var: is_payable}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    budget_hours: $budget_hours, cost_amount: $cost_amount, project_idfk: $project_idfk, rate_amount: $rate_amount, timesheet_category_idfk: $timesheet_category_idfk, is_billable: $is_billable, is_payable: $is_payable
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Schedule Assignments.
#
# GET /api/ScheduleAssignment
# Returns: record<PageNumber: int, PageSize: int, ScheduleAssignments: table<AccountIDFK: int, DateCreated: string, DateUpdated: string, Duration: float, ScheduleAssignmentID: int, ScheduleDate: string, ScheduleSeriesIDFK: int, UserIDFK: int>, TotalCount: int>
# operationId: ScheduleAssignment_Get
export def "schedule-assignment-get" [
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
  --updated-after: string # Limit results to records updated after the specified date (format: date-time)
  --schedule-date-from: string # Filter for schedule assignement that are on or after a specific date (format: date-time)
  --schedule-date-to: string # Filter for schedules that are on or before a specific date (format: date-time)
  --schedule-series-id: int # Filter to records for a particular Schedule Series (format: int64)
  --user-id: int # The UserID of a schedule user to filter assignments for. Only api users with Admin role can see all schedules across all users. Users with ScheduleUser role can access their own ScheduleSeries. (format: int32)
  --user-email: string # The email of the user who has been scheduled
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --sort: string # Optional sorting instruction. Currently possible values: "DateUpdated", "DateCreated", "DateUpdated desc", "DateCreated desc"
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ScheduleAssignment"
    query: [{name: UpdatedAfter, var: updated_after}, {name: ScheduleDateFrom, var: schedule_date_from}, {name: ScheduleDateTo, var: schedule_date_to}, {name: ScheduleSeriesID, var: schedule_series_id}, {name: UserID, var: user_id}, {name: UserEmail, var: user_email}, {name: pageSize, var: page_size}, {name: pageNumber, var: page_number}, {name: Sort, var: sort}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    updated_after: $updated_after, schedule_date_from: $schedule_date_from, schedule_date_to: $schedule_date_to, schedule_series_id: $schedule_series_id, user_id: $user_id, user_email: $user_email, page_size: $page_size, page_number: $page_number, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Schedule Series
#
# GET /api/ScheduleSeries
# Returns: record<PageNumber: int, PageSize: int, ScheduleSeries: table<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int>, TotalCount: int>
# operationId: ScheduleSeries_Get
export def "schedule-series-get" [
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
  --updated-after: string # Limit results to records updated after the specified date (format: date-time)
  --schedule-start-date-from: string # Filter for schedules that start on or after a specific date (format: date-time)
  --schedule-start-date-to: string # Filter for schedules that start on or before a specific date (format: date-time)
  --schedule-end-date-from: string # Filter for schedules that end on or after a specific date (format: date-time)
  --schedule-end-date-to: string # Filter for schedules that end on or before a specific date (format: date-time)
  --user-id: int # The UserID of a schedule user to filter assignments for. Only api users with Admin role can see all schedules across all users. Users with ScheduleUser role can access their own ScheduleSeries. (format: int32)
  --user-email: string # The email of the user who has been scheduled
  --time-sheet-category-id: int # Filter for schedule records linked to a specific timesheeet category (format: int32)
  --time-sheet-category-name: string # Filter for schedule records with a specific timesheeet category name (exact string match)
  --leave-type-id: int # Filter to records of a particular leave type (format: int32)
  --project-id: int # Filter to only include books linked to a specific project (format: int32)
  --company-id: int # Filter to only include records linked to projects, where that project belongs to a specific customer company (format: int32)
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --sort: string # Optional sorting instruction. Currently possible values: "DateUpdated", "DateCreated", "DateUpdated desc", "DateCreated desc"
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ScheduleSeries"
    query: [{name: UpdatedAfter, var: updated_after}, {name: ScheduleStartDateFrom, var: schedule_start_date_from}, {name: ScheduleStartDateTo, var: schedule_start_date_to}, {name: ScheduleEndDateFrom, var: schedule_end_date_from}, {name: ScheduleEndDateTo, var: schedule_end_date_to}, {name: UserID, var: user_id}, {name: UserEmail, var: user_email}, {name: TimeSheetCategoryID, var: time_sheet_category_id}, {name: TimeSheetCategoryName, var: time_sheet_category_name}, {name: LeaveTypeID, var: leave_type_id}, {name: ProjectID, var: project_id}, {name: CompanyID, var: company_id}, {name: pageSize, var: page_size}, {name: pageNumber, var: page_number}, {name: Sort, var: sort}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    updated_after: $updated_after, schedule_start_date_from: $schedule_start_date_from, schedule_start_date_to: $schedule_start_date_to, schedule_end_date_from: $schedule_end_date_from, schedule_end_date_to: $schedule_end_date_to, user_id: $user_id, user_email: $user_email, time_sheet_category_id: $time_sheet_category_id, time_sheet_category_name: $time_sheet_category_name, leave_type_id: $leave_type_id, project_id: $project_id, company_id: $company_id, page_size: $page_size, page_number: $page_number, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a Section
#
# DELETE /api/Section
# Returns: record
# operationId: Section_Delete
export def "section-delete" [
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
  --section-id: int # required, format: int64
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/Section"
    query: [{name: SectionID, var: section_id, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    section_id: $section_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Sections
#
# GET /api/Section
# Returns: record<Sections: table<DisplayOrder: int, EndDate: string, EndDateUTC: string, ProjectIDFK: int, SectionID: int, StartDate: string, StartDateUTC: string, Title: string>, TotalCount: int>
# operationId: Section_Get
export def "section-get" [
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
  --project-id: int # Get sections for Project with ProjectID (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Section"
    query: [{name: ProjectID, var: project_id, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a Section
#
# POST /api/Section
# Returns: record<DisplayOrder: int, EndDate: string, EndDateUTC: string, ProjectIDFK: int, SectionID: int, StartDate: string, StartDateUTC: string, Title: string>
# operationId: Section_Post
export def "section-post" [
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
  --end-date-utc: string # format: date-time
  --project-idfk: int # format: int32
  --start-date-utc: string # format: date-time
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Section"
    body: {content_type: "application/json", kind: json, fields: [{name: EndDateUTC, var: end_date_utc}, {name: ProjectIDFK, var: project_idfk}, {name: StartDateUTC, var: start_date_utc}, {name: Title, var: title}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    end_date_utc: $end_date_utc, project_idfk: $project_idfk, start_date_utc: $start_date_utc, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a Task
#
# DELETE /api/Task
# Returns: record
# operationId: Task_Delete
export def "task-delete" [
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
  --task-id: int # required, format: int64
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/Task"
    query: [{name: TaskID, var: task_id, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Tasks
#
# GET /api/Task
# Returns: record<PageNumber: int, PageSize: int, Tasks: table<AccountTaskTypeIDFK: int, ActualTime: float, AssignedToUsers: list, DateCompleted: string, DateCreated: string, DateDue: string, DateStart: string, DateUpdated: string, Description: string, DescriptionNoHTML: string, EstimatedEffort: float, PercentComplete: float, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, SectionIDFK: int, SectionTitle: string, Tags: list, TaskID: int, TaskPriorityCode: string, TaskPriorityName: string, TaskStatusCode: string, TaskStatusName: string, Title: string, isCompleteStatus: bool>, TotalCount: int>
# operationId: Task_Get
export def "task-get" [
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
  --updated-after: string # Optional filter to records updated after a specific date. (format: date-time)
  --page-size: int # Number of items per page. Defaults to 20. (format: int32)
  --page-number: int # Page to display. Starts from 1. Defaults to 1 (format: int32)
  --sort: string # Optional sorting instruction. Currently possible values: "DateUpdated", "DateCreated", "DateUpdated desc", "DateCreated desc", "SectionTitle", "Title"
  --is-complete: oneof<nothing, bool> # Optional filter to only display tasks linked to a Task Status where isComplete=false, or where isComplete=true
  --project-id: int # Optional filter to only display tasks belonging to a specific ProjectID (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Task"
    query: [{name: UpdatedAfter, var: updated_after}, {name: pageSize, var: page_size}, {name: pageNumber, var: page_number}, {name: Sort, var: sort}, {name: isComplete, var: is_complete}, {name: ProjectID, var: project_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    updated_after: $updated_after, page_size: $page_size, page_number: $page_number, sort: $sort, is_complete: $is_complete, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a Task
#
# POST /api/Task
# Returns: record<AccountTaskTypeIDFK: int, ActualTime: float, AssignedToUsers: table<AssignedToEmail: string, AssignedToFirstname: string, AssignedToLastname: string, AssignedToUserIDFK: int>, DateCompleted: string, DateCreated: string, DateDue: string, DateStart: string, DateUpdated: string, Description: string, DescriptionNoHTML: string, EstimatedEffort: float, PercentComplete: float, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, SectionIDFK: int, SectionTitle: string, Tags: table<Color: string, Name: string, TagID: int>, TaskID: int, TaskPriorityCode: string, TaskPriorityName: string, TaskStatusCode: string, TaskStatusName: string, Title: string, isCompleteStatus: bool>
# operationId: Task_Post
export def "task-post" [
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
  --account-task-type-idfk: int # format: int32
  --assigned-to-user-idf-ks: list<int>
  --date-due: string # format: date-time
  --date-start: string # format: date-time
  --description: string
  --estimated-effort: float # Decimal hours (format: double)
  project_idfk: int # format: int32
  section_idfk: int # format: int32
  --tags: list # Collection of tags specifying Name and Color (Hex) — item shape: {Color?: string, Name?: string}
  --task-priority-code: string
  title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Task"
    body: {content_type: "application/json", kind: json, fields: [{name: AccountTaskTypeIDFK, var: account_task_type_idfk}, {name: AssignedToUserIDFKs, var: assigned_to_user_idf_ks}, {name: DateDue, var: date_due}, {name: DateStart, var: date_start}, {name: Description, var: description}, {name: EstimatedEffort, var: estimated_effort}, {name: ProjectIDFK, var: project_idfk}, {name: SectionIDFK, var: section_idfk}, {name: Tags, var: tags}, {name: TaskPriorityCode, var: task_priority_code}, {name: Title, var: title}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    account_task_type_idfk: $account_task_type_idfk, assigned_to_user_idf_ks: $assigned_to_user_idf_ks, date_due: $date_due, date_start: $date_start, description: $description, estimated_effort: $estimated_effort, project_idfk: $project_idfk, section_idfk: $section_idfk, tags: $tags, task_priority_code: $task_priority_code, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a Task.
#
# PUT /api/Task
# Returns: record<AccountTaskTypeIDFK: int, ActualTime: float, AssignedToUsers: table<AssignedToEmail: string, AssignedToFirstname: string, AssignedToLastname: string, AssignedToUserIDFK: int>, DateCompleted: string, DateCreated: string, DateDue: string, DateStart: string, DateUpdated: string, Description: string, DescriptionNoHTML: string, EstimatedEffort: float, PercentComplete: float, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, SectionIDFK: int, SectionTitle: string, Tags: table<Color: string, Name: string, TagID: int>, TaskID: int, TaskPriorityCode: string, TaskPriorityName: string, TaskStatusCode: string, TaskStatusName: string, Title: string, isCompleteStatus: bool>
# operationId: Task_Put
export def "task-put" [
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
  --assigned-to-user-idfk: list<int>
  --date-due: string # format: date-time
  --date-start: string # format: date-time
  --description: string
  --estimated-effort: float # Decimal hours (format: double)
  fields_to_update: list<string>
  --percent-complete: int # format: int32
  --section-idfk: int # format: int32
  --tags: list # item shape: {Color?: string, Name?: string}
  task_id: int # format: int32
  --task-priority-code: string
  --task-status-code: string
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/Task"
    body: {content_type: "application/json", kind: json, fields: [{name: AssignedToUserIDFK, var: assigned_to_user_idfk}, {name: DateDue, var: date_due}, {name: DateStart, var: date_start}, {name: Description, var: description}, {name: EstimatedEffort, var: estimated_effort}, {name: FieldsToUpdate, var: fields_to_update}, {name: PercentComplete, var: percent_complete}, {name: SectionIDFK, var: section_idfk}, {name: Tags, var: tags}, {name: TaskID, var: task_id}, {name: TaskPriorityCode, var: task_priority_code}, {name: TaskStatusCode, var: task_status_code}, {name: Title, var: title}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    assigned_to_user_idfk: $assigned_to_user_idfk, date_due: $date_due, date_start: $date_start, description: $description, estimated_effort: $estimated_effort, fields_to_update: $fields_to_update, percent_complete: $percent_complete, section_idfk: $section_idfk, tags: $tags, task_id: $task_id, task_priority_code: $task_priority_code, task_status_code: $task_status_code, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets minimal list of Tasks for the current user
#
# GET /api/Task/Lookup
# Returns: record<PageSize: int, hasMore: bool, pageNumber: int, sections: table<SectionTitle: string, tasks: list>>
# operationId: TaskLookup
export def "task-lookup" [
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
  --project-id: int # (required) The ProjectID to use when filtering Tasks (required, format: int32)
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --hide-completed: oneof<nothing, bool> # (optional) true/false to hide completed tasks. Defaults false
  --search: string # (optional) Search string to match against Task title. Performs begins-with match
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Task/Lookup"
    query: [{name: projectID, var: project_id, required: true}, {name: pageSize, var: page_size}, {name: pageNumber, var: page_number}, {name: hideCompleted, var: hide_completed}, {name: search, var: search}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, page_size: $page_size, page_number: $page_number, hide_completed: $hide_completed, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets Task by Task ID
#
# GET /api/Task/{id}
# Returns: record<AccountTaskTypeIDFK: int, ActualTime: float, AssignedToUsers: table<AssignedToEmail: string, AssignedToFirstname: string, AssignedToLastname: string, AssignedToUserIDFK: int>, DateCompleted: string, DateCreated: string, DateDue: string, DateStart: string, DateUpdated: string, Description: string, DescriptionNoHTML: string, EstimatedEffort: float, PercentComplete: float, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, SectionIDFK: int, SectionTitle: string, Tags: table<Color: string, Name: string, TagID: int>, TaskID: int, TaskPriorityCode: string, TaskPriorityName: string, TaskStatusCode: string, TaskStatusName: string, Title: string, isCompleteStatus: bool>
# operationId: Task_GetByID
export def "task-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Task/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Task Statuses
#
# GET /api/TaskStatus
# Returns: record<statuses: table<AccountTaskTypeIDFK: int, Color: string, DisplayOrder: int, Name: string, TaskStatusCode: string, TaskTypeName: string, isComplete: bool>>
# operationId: TaskStatus_Get
export def "task-status-get" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/TaskStatus"
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Task Types
#
# GET /api/TaskType
# Returns: record<tasktypes: table<AccountTaskTypeID: int, Icon: string, IconType: string, Name: string, isDefault: bool>>
# operationId: TaskType_Get
export def "task-type-get" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/TaskType"
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get List of Taxes configured in the Avaza account.
#
# GET /api/Tax
# Returns: record<Taxes: table<CalculatedPercent: float, Name: string, TaxCode: string, TaxComponents: list, TaxID: int>>
# operationId: Tax_Get
export def "tax-get" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Tax"
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Timsheets
#
# GET /api/Timesheet
# Returns: record<PageNumber: int, PageSize: int, Timesheets: table<ApprovedBy: string, CategoryName: string, CustomMetadata: string, CustomerIDFK: int, CustomerName: string, DateApproved: string, DateCreated: string, DateUpdated: string, Duration: float, Email: string, EndTimeLocal: string, EndTimeUTC: string, EntryDate: string, Firstname: string, HasTimer: bool, InvoiceIDFK: int, InvoiceLineItemIDFK: int, Lastname: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, StartTimeLocal: string, StartTimeUTC: string, TaskIDFK: int, TaskTitle: string, TimerStartedAtUTC: string, TimesheetCategoryIDFK: int, TimesheetEntryApprovalStatusCode: string, TimesheetEntryID: int, TimesheetUserTimeZone: string, UserIDFK: int, isBillable: bool, isInvoiced: bool>, TotalCount: int>
# operationId: Timesheet_Get
export def "timesheet-get" [
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
  --updated-after: string # format: date-time
  --entry-date-from: string # format: date-time
  --entry-date-to: string # format: date-time
  --user-id: int # The UserID of a timesheet user to filter timesheets for. Only api users with certain higher roles can see timesheets across multiple users. (format: int32)
  --user-email: string
  --category-name: string
  --project-id: int # format: int32
  --is-billable: oneof<nothing, bool>
  --is-invoiced: oneof<nothing, bool>
  --is-timer-running: oneof<nothing, bool>
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --include-invoice-details: oneof<nothing, bool> # Defaults to false. When true, the InvoiceIDFK value will be included in the response.
  --sort: string # Optional sorting instruction. Currently possible values: "DateUpdated", "DateCreated", "DateUpdated desc", "DateCreated desc","EntryDate", "EntryDate desc", "StartTimeLocal","StartTimeLocal desc", "TimeSheetEntryID", "TimeSheetEntryID desc"
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Timesheet"
    query: [{name: UpdatedAfter, var: updated_after}, {name: EntryDateFrom, var: entry_date_from}, {name: EntryDateTo, var: entry_date_to}, {name: UserID, var: user_id}, {name: UserEmail, var: user_email}, {name: CategoryName, var: category_name}, {name: ProjectID, var: project_id}, {name: isBillable, var: is_billable}, {name: isInvoiced, var: is_invoiced}, {name: isTimerRunning, var: is_timer_running}, {name: pageSize, var: page_size}, {name: pageNumber, var: page_number}, {name: includeInvoiceDetails, var: include_invoice_details}, {name: Sort, var: sort}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    updated_after: $updated_after, entry_date_from: $entry_date_from, entry_date_to: $entry_date_to, user_id: $user_id, user_email: $user_email, category_name: $category_name, project_id: $project_id, is_billable: $is_billable, is_invoiced: $is_invoiced, is_timer_running: $is_timer_running, page_size: $page_size, page_number: $page_number, include_invoice_details: $include_invoice_details, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new Timesheet Entry
#
# POST /api/Timesheet
# Returns: record<ApprovedBy: string, CategoryName: string, CustomMetadata: string, CustomerIDFK: int, CustomerName: string, DateApproved: string, DateCreated: string, DateUpdated: string, Duration: float, Email: string, EndTimeLocal: string, EndTimeUTC: string, EntryDate: string, Firstname: string, HasTimer: bool, InvoiceIDFK: int, InvoiceLineItemIDFK: int, Lastname: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, StartTimeLocal: string, StartTimeUTC: string, TaskIDFK: int, TaskTitle: string, TimerStartedAtUTC: string, TimesheetCategoryIDFK: int, TimesheetEntryApprovalStatusCode: string, TimesheetEntryID: int, TimesheetUserTimeZone: string, UserIDFK: int, isBillable: bool, isInvoiced: bool>
# operationId: Timesheet_Post
export def "timesheet-post" [
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
  --custom-metadata: string # Optional. free nvarchar field available via Api to store any additional metadata against a timesheet. We suggest you use Json or your preferred serialisation format. 1000 characters max.
  --duration: float # The duration of the timesheet, in decimal hours. If null or 0, a timer will be started. (format: double)
  --entry-date: string # The date of the timesheet entry, with an optional start time component. (format: date-time)
  --notes: string # Timesheet Notes
  --project-idfk: int # The project to associate the timesheet with. (format: int32)
  --task-idfk: int # Optional. Link the timesheet to a specific task (format: int32)
  --timesheet-category-idfk: int # The Project timesheet category to link the timesheet to (format: int32)
  --user-idfk: int # UserID for a Timesheet user in Avaza (format: int32)
  --has-start-end-time: oneof<nothing, bool> # If true, the start time will be take from the time component of the Entry Date field, and the end time will be calculated by adding the Duration to the StartDate
  --is-invoiced: oneof<nothing, bool> # Optional. False by default. Allows you to mark the timesheet as invoiced in an external system.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Timesheet"
    body: {content_type: "application/json", kind: json, fields: [{name: CustomMetadata, var: custom_metadata}, {name: Duration, var: duration}, {name: EntryDate, var: entry_date}, {name: Notes, var: notes}, {name: ProjectIDFK, var: project_idfk}, {name: TaskIDFK, var: task_idfk}, {name: TimesheetCategoryIDFK, var: timesheet_category_idfk}, {name: UserIDFK, var: user_idfk}, {name: hasStartEndTime, var: has_start_end_time}, {name: isInvoiced, var: is_invoiced}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    custom_metadata: $custom_metadata, duration: $duration, entry_date: $entry_date, notes: $notes, project_idfk: $project_idfk, task_idfk: $task_idfk, timesheet_category_idfk: $timesheet_category_idfk, user_idfk: $user_idfk, has_start_end_time: $has_start_end_time, is_invoiced: $is_invoiced
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a Timesheet
#
# PUT /api/Timesheet
# Returns: record<ApprovedBy: string, CategoryName: string, CustomMetadata: string, CustomerIDFK: int, CustomerName: string, DateApproved: string, DateCreated: string, DateUpdated: string, Duration: float, Email: string, EndTimeLocal: string, EndTimeUTC: string, EntryDate: string, Firstname: string, HasTimer: bool, InvoiceIDFK: int, InvoiceLineItemIDFK: int, Lastname: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, StartTimeLocal: string, StartTimeUTC: string, TaskIDFK: int, TaskTitle: string, TimerStartedAtUTC: string, TimesheetCategoryIDFK: int, TimesheetEntryApprovalStatusCode: string, TimesheetEntryID: int, TimesheetUserTimeZone: string, UserIDFK: int, isBillable: bool, isInvoiced: bool>
# operationId: Timesheet_Put
export def "timesheet-put" [
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
  --custom-metadata: string # Optional. free nvarchar field available via Api to store any additional metadata against a timesheet. We suggest you use Json or your preferred serialisation format. 1000 characters max.
  --duration: float # format: double
  --entry-date: string # format: date-time
  fields_to_update: list<string>
  --notes: string
  project_idfk: int # format: int32
  --task-idfk: int # format: int32
  time_sheet_entry_id: int # format: int64
  --timesheet-category-idfk: int # format: int32
  --has-start-end-time: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/Timesheet"
    body: {content_type: "application/json", kind: json, fields: [{name: CustomMetadata, var: custom_metadata}, {name: Duration, var: duration}, {name: EntryDate, var: entry_date}, {name: FieldsToUpdate, var: fields_to_update}, {name: Notes, var: notes}, {name: ProjectIDFK, var: project_idfk}, {name: TaskIDFK, var: task_idfk}, {name: TimeSheetEntryID, var: time_sheet_entry_id}, {name: TimesheetCategoryIDFK, var: timesheet_category_idfk}, {name: hasStartEndTime, var: has_start_end_time}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    custom_metadata: $custom_metadata, duration: $duration, entry_date: $entry_date, fields_to_update: $fields_to_update, notes: $notes, project_idfk: $project_idfk, task_idfk: $task_idfk, time_sheet_entry_id: $time_sheet_entry_id, timesheet_category_idfk: $timesheet_category_idfk, has_start_end_time: $has_start_end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a Timesheet Entry
#
# DELETE /api/Timesheet/{id}
# Returns: record
# operationId: Timesheet_Delete
export def "timesheet-delete" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/Timesheet/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a Timesheet Entry by Timesheet ID
#
# GET /api/Timesheet/{id}
# Returns: record<ApprovedBy: string, CategoryName: string, CustomMetadata: string, CustomerIDFK: int, CustomerName: string, DateApproved: string, DateCreated: string, DateUpdated: string, Duration: float, Email: string, EndTimeLocal: string, EndTimeUTC: string, EntryDate: string, Firstname: string, HasTimer: bool, InvoiceIDFK: int, InvoiceLineItemIDFK: int, Lastname: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, StartTimeLocal: string, StartTimeUTC: string, TaskIDFK: int, TaskTitle: string, TimerStartedAtUTC: string, TimesheetCategoryIDFK: int, TimesheetEntryApprovalStatusCode: string, TimesheetEntryID: int, TimesheetUserTimeZone: string, UserIDFK: int, isBillable: bool, isInvoiced: bool>
# operationId: Timesheet_GetByID
export def "timesheet-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Timesheet/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Submit Timesheets for Approval.
#
# POST /api/TimesheetSubmission
# Returns: record
# operationId: TimesheetSubmission_Post
export def "timesheet-submission-post" [
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
  --send-notifications: oneof<nothing, bool> # Send email alerts to timesheet approvers. Defaults to true
  --whole-week-of: string # A date (yyyy-MM-dd) that falls within a Week to have all timesheets in that week submitted. Respects the First Day of Week setting in your account Timesheet Settings to determine the week range. (format: date-time)
  --whole-day-of: string # A date (yyyy-MM-dd) to submit all timesheets on this day (format: date-time)
  --user-id: int # The user to submit timesheets for. Defaults to current user. Only allowed to be different from the current user when the current user has rights to Impersonate other users. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/TimesheetSubmission"
    query: [{name: SendNotifications, var: send_notifications}, {name: WholeWeekOf, var: whole_week_of}, {name: WholeDayOf, var: whole_day_of}, {name: UserID, var: user_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    send_notifications: $send_notifications, whole_week_of: $whole_week_of, whole_day_of: $whole_day_of, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets Basic Summary of Timesheet Statistics
#
# GET /api/TimesheetSummary
# Returns: record<BillableHours: float, EntryDateFrom: string, EntryDateTo: string, GroupData: table<BillableHours: float, GroupData: list, GroupID: string, GroupName: string, TotalHours: float>, GroupingLevels: list<string>, TotalHours: float, UserID: list<int>>
# operationId: TimesheetSummary_Get
export def "timesheet-summary-get" [
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
  --model-group-by: list<string> # (Optional) Combine one, two or three levels of Grouping. Combine these possible grouping values: "Customer", "Project", "Category", "User", "Task", "Year", "Month", "Day", "Week".
  --model-entry-date-from: string # (Required) Filter for timesheets greater or equal to the specified date. e.g. 2019-01-25. You can optionally include a time component, otherwise it assumes 00:00 (format: date-time)
  --model-entry-date-to: string # (Required) Filter for timesheets with an entry date smaller or equal to the specified date. e.g. 2019-01-25. You can optionally include a time component, otherwise it assumes 00:00 (format: date-time)
  --model-user-id: list<int> # (Optional) Defaults to the current user. Provide one or more UserIDs of Users whose timesheets should be retrieved. If the current user doesn't have impersonation rights, then they will only see their own data.
  --model-project-id: int # (Optional) Filter by Project (format: int32)
  --model-is-billable: oneof<nothing, bool> # (Optional) Filter by the billable status of Timesheets.
  --model-is-invoiced: oneof<nothing, bool> # (Optional) Filter for timesheets by whether they have been Invoiced or not.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/TimesheetSummary"
    query: [{name: "model.groupBy", var: model_group_by, style: multi}, {name: "model.entryDateFrom", var: model_entry_date_from}, {name: "model.entryDateTo", var: model_entry_date_to}, {name: "model.userID", var: model_user_id, style: multi}, {name: "model.projectID", var: model_project_id}, {name: "model.isBillable", var: model_is_billable}, {name: "model.isInvoiced", var: model_is_invoiced}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    model_group_by: $model_group_by, model_entry_date_from: $model_entry_date_from, model_entry_date_to: $model_entry_date_to, model_user_id: $model_user_id, model_project_id: $model_project_id, model_is_billable: $model_is_billable, model_is_invoiced: $model_is_invoiced
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the Running Timer if there is one for a user.
#
# GET /api/TimesheetTimer
# Returns: record
# operationId: TimesheetTimer_GetRunningTimer
export def "timesheet-timer-get-running-timer" [
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
  --user-id: int # Optional - User ID number if impersonating a different user. Otherwise assumes the current user. Only users with certain security roles have permission to impersonate other users (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/TimesheetTimer"
    query: [{name: UserID, var: user_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Stop the timer running on an existing Timesheet Entry
#
# DELETE /api/TimesheetTimer/{id}
# Returns: record
# operationId: TimesheetTimer_StopTimer
export def "timesheet-timer-stop-timer" [
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
  --accept: string@accept-completer # Response content type
  --user-id: int # Optional - User ID number if impersonating a different user. Otherwise assumes the current user. Only users with certain security roles have permission to impersonate other users (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/TimesheetTimer/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: UserID, var: user_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Starts a Timer running on an existing Timesheet Entry
#
# POST /api/TimesheetTimer/{id}
# Returns: record
# operationId: TimesheetTimer_StartTimer
export def "timesheet-timer-start-timer" [
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
  --accept: string@accept-completer # Response content type
  --user-id: int # Optional - User ID number if impersonating a different user. Otherwise assumes the current user. Only users with certain security roles have permission to impersonate other users (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/TimesheetTimer/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: UserID, var: user_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Collection of Users who have roles in the current Avaza account.
#
# GET /api/UserProfile
# Returns: record<Users: table<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DefaultBillableRate: float, DefaultCostRate: float, Email: string, Firstname: string, FridayAvailableHours: float, IANATimezone: string, Lastname: string, Mobile: string, MondayAvailableHours: float, Phone: string, PositionTitle: string, Roles: list, SaturdayAvailableHours: float, SundayAvailableHours: float, Tags: list, ThursdayAvailableHours: float, TimeZone: string, TuesdayAvailableHours: float, UserID: int, WednesdayAvailableHours: float, isTeamMember: bool>>
# operationId: UserProfile_Get
export def "user-profile-get" [
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
  --roles: string # Optional list of comma separated role codes to filter users by (e.g. "TimesheetUser,Admin")
  --tags: string
  --current-user-only: oneof<nothing, bool> # Optional boolean (true/false) to filter to only show current authenticated user (always true for non Admin/InvoiceManager users)
  --company-idfk: int # Optionally filter by Company ID (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/UserProfile"
    query: [{name: Roles, var: roles}, {name: Tags, var: tags}, {name: CurrentUserOnly, var: current_user_only}, {name: CompanyIDFK, var: company_idfk}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    roles: $roles, tags: $tags, current_user_only: $current_user_only, company_idfk: $company_idfk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete webhook subscription by URL
#
# DELETE /api/Webhook
# Returns: record
# operationId: Webhook_DeleteByUrl
export def "webhook-delete-by-url" [
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
  --target-url: string # Target URL that should be used to delete subscriptions (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/Webhook"
    query: [{name: target_url, var: target_url, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    target_url: $target_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get list of Webhook Subscriptions
#
# GET /api/Webhook
# Returns: record<Webhooks: table<EventCode: string, NotificationURL: string, SubscriptionID: int, UserIDFK: int>>
# operationId: Webhook_Get
export def "webhook-get" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Webhook"
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Subscribe to Webhook. On success, returns ID of webhook subscription.
#
# POST /api/Webhook
# Returns: record<ID: int>
# operationId: Webhook_Post
export def "webhook-post" [
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
  event: string # The event code to be notified about. Possible values: company_created, contact_created, invoice_created, invoice_sent, project_created, task_created
  --secret: string # Optional Secret string (255 char max). If provided, the secret will be BASE 64 encoded and used as a basic authentication http header with webhook notifications. i.e. Authorization Basic [BASE64 of Secret]"
  target_url: string # The URL that should be notified of the event.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Webhook"
    body: {content_type: "application/json", kind: json, fields: [{name: event, var: event}, {name: secret, var: secret}, {name: target_url, var: target_url}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [201]
    auth: bearer
  } {
    event: $event, secret: $secret, target_url: $target_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete Webhook Subscription by ID
#
# DELETE /api/Webhook/{id}
# Returns: record
# operationId: Webhook_Delete
export def "webhook-delete" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/Webhook/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Webhook Subscription by SubscriptionID
#
# GET /api/Webhook/{id}
# Returns: record<Webhooks: table<EventCode: string, NotificationURL: string, SubscriptionID: int, UserIDFK: int>>
# operationId: Webhook_GetByID
export def "webhook-get-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Webhook/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
