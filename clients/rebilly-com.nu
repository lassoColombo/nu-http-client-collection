# Auto-generated client for Rebilly REST API v2.1
# Source: https://api.apis.guru/v2/specs/rebilly.com/2.1/openapi.json
# Auth: --token flag or $env.REBILLY_REST_API_TOKEN

const CLIENT = {
  base_url: "https://api-sandbox.rebilly.com"
  token_env_var: "REBILLY_REST_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
    {name: reb-apikey, in: header, header_name: REB-APIKEY, prefix: ""}
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

def base-url-completer [] { ["https://api-sandbox.rebilly.com" "https://api.rebilly.com"] }
def auth-scheme-completer [] { ["bearer" "reb-apikey"] }

# Completers for enum parameters
def enrolled-completer [] { ["N" "U" "Y"] }
def payer-auth-response-status-completer [] { ["A" "N" "U" "Y"] }
def signature-verification-completer [] { ["N" "Y"] }
def related-type-completer [] { ["customer" "customer-timeline-comment" "dispute" "gateway-timeline-comment" "invoice" "order-timeline-comment" "organization" "payment" "plan" "product" "subscription" "transaction" "transaction-timeline-comment"] }
def mode-completer [] { ["password" "passwordless"] }
def account-type-completer [] { ["checking" "other" "savings"] }
def type-completer [] { ["address" "bank-account" "bin" "country" "customer-id" "email" "email-domain" "fingerprint" "ip-address" "payment-card"] }
def resource-completer [] { ["bump-offers" "customers" "payment-instruments" "plans" "products" "subscriptions" "transactions" "websites"] }
def type-completer-1 [] { ["array" "boolean" "datetime" "integer" "monetary" "number" "string"] }
def type-completer-2 [] { ["aml-list-was-possibly-matched" "coupon-applied" "coupon-redeemed" "coupon-redemption-canceled" "custom-event" "custom-event-processed" "custom-fields-changed" "customer-bank-account-blocked" "customer-blocked" "customer-comment-created" "customer-created" "customer-payment-card-blocked" "default-payment-instrument-changed" "email-message-sent" "experian-check-performed" "invoice-abandoned" "invoice-created" "invoice-disputed" "invoice-issued" "invoice-paid" "invoice-partially-paid" "invoice-partially-refunded" "invoice-past-due" "invoice-refunded" "invoice-voided" "kyc-document-accepted" "kyc-document-created" "kyc-document-manually-accepted" "kyc-document-manually-rejected" "kyc-document-modified" "kyc-document-rejected" "lead-source-changed" "order-activated" "order-canceled" "order-churned" "order-completed" "order-created" "order-downgraded" "order-paid-early" "order-reactivated" "order-renewed" "order-upgraded" "payment-card-expired" "payment-instrument-created" "payment-instrument-deactivated" "primary-address-changed" "transaction-abandoned" "transaction-amount-discrepancy-found" "transaction-approved" "transaction-canceled" "transaction-declined" "transaction-discrepancy-found" "transaction-refunded" "transaction-voided" "transaction-waiting-gateway"] }
def type-completer-3 [] { ["Apple Pay"] }
def reason-code-completer [] { ["0" "00" "1" "10.1" "10.2" "10.3" "10.4" "10.5" "1000" "11.1" "11.2" "11.3" "12" "12.1" "12.2" "12.3" "12.4" "12.5" "12.6" "12.7" "13.1" "13.2" "13.3" "13.4" "13.5" "13.6" "13.7" "13.8" "13.9" "2" "2" "3" "30" "31" "35" "37" "4" "40" "41" "42" "46" "47" "49" "5" "50" "51" "53" "54" "55" "57" "59" "6" "60" "62" "63" "7" "7" "70" "71" "72" "73" "74" "75" "76" "77" "79" "8" "80" "81" "82" "83" "85" "86" "9" "93" "A" "A01" "A02" "A08" "AL" "AP" "AW" "B" "C02" "C04" "C05" "C08" "C14" "C18" "C28" "C31" "C32" "CA" "CD" "CR" "DA" "DP" "DP1" "EX" "F10" "F14" "F22" "F24" "F29" "FR1" "FR4" "FR6" "IC" "IN" "IS" "LP" "M01" "M10" "M49" "N" "NA" "NC" "P" "P01" "P03" "P04" "P05" "P07" "P08" "P22" "P23" "R03" "R13" "RG" "RM" "RN1" "RN2" "SV" "TF" "TNM" "UA01" "UA02" "UA03" "UA10" "UA11" "UA12" "UA18" "UA20" "UA21" "UA22" "UA23" "UA28" "UA30" "UA31" "UA32" "UA38" "UA99" "bank_cannot_process" "credit_not_processed" "customer_initiated" "debit_not_authorized" "duplicate" "fraudulent" "general" "incorrect_account_details" "insufficient_funds" "pre-chargeback-alert" "product_not_received" "product_unacceptable" "subscription_canceled" "unrecognized"] }
def status-completer [] { ["forfeited" "lost" "response-needed" "under-review" "unknown" "won"] }
def type-completer-4 [] { ["arbitration" "ethoca-alert" "first-chargeback" "fraud" "information-request" "second-chargeback" "verifi-alert"] }
def extension-completer [] { [".gif" ".jpg" ".png"] }
def accept-completer [] { ["application/json" "application/pdf"] }
def type-completer-5 [] { ["credit" "debit"] }
def document-subtype-completer [] { ["bank-statement" "birth-certificate" "copy-credit-card" "credit-card-statement" "driver-license" "ewallet-holder-details" "ewallet-transaction-statement" "id-card" "inheritance-documentation" "lease-agreement" "other" "passport" "proof-of-age-card" "public-health-card" "public-service" "rental-receipt" "reverse-of-id" "salary-slip" "sale-of-assets" "tax-return" "utility-bill"] }
def document-type-completer [] { ["address-proof" "funds-proof" "identity-proof" "purchase-proof"] }
def type-completer-6 [] { ["document-expired" "document-not-matching" "document-unreadable" "other" "underage-person"] }
def method-completer [] { ["payment-card"] }
def method-completer-1 [] { ["paypal"] }
def tax-category-id-completer [] { ["00000" "20010" "30070" "31000" "40030" "51010" "51020" "99999"] }
def canceled-by-completer [] { ["customer" "merchant"] }
def reason-completer [] { ["billing-failure" "bugs-or-problems" "contract-expired" "did-not-use" "did-not-want" "do-not-remember" "missing-features" "other" "risk-warning" "too-expensive"] }
def status-completer-1 [] { ["completed" "confirmed" "draft" "revoked"] }
def order-type-completer [] { ["one-time-order" "subscription-order"] }
def renewal-policy-completer [] { ["reset" "retain"] }
def type-completer-7 [] { ["3ds-authentication" "authorize" "sale"] }
def result-completer [] { ["abandoned" "approved" "canceled" "declined"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get3-d-secure-collection: "table<_links: list<record>, amount: float, cavv: string, createdTime: string, currency: string, customerId: string, eci: int, enrolled: string, enrollmentEci: string, gatewayAccountId: string, id: string, payerAuthResponseStatus: string, paymentCardId: string, signatureVerification: string, websiteId: string, xid: string>"
    post3-d-secure: "record<_links: table<rel: string, href: string>, amount: float, cavv: string, createdTime: string, currency: string, customerId: string, eci: int, enrolled: string, enrollmentEci: string, gatewayAccountId: string, id: string, payerAuthResponseStatus: string, paymentCardId: string, signatureVerification: string, websiteId: string, xid: string>"
    get3-d-secure: "record<_links: table<rel: string, href: string>, amount: float, cavv: string, createdTime: string, currency: string, customerId: string, eci: int, enrolled: string, enrollmentEci: string, gatewayAccountId: string, id: string, payerAuthResponseStatus: string, paymentCardId: string, signatureVerification: string, websiteId: string, xid: string>"
    get-aml-entry: "table<_links: list<record>, address: list<record>, aliases: list<record>, comments: string, confidence: string, dob: list<string>, firstName: string, gender: string, lastName: string, legalBasis: list<string>, nationality: string, passport: list<record>, regime: string, source: string, sourceType: string, title: list<string>, type: string>"
    get-attachment-collection: "table<_embedded: list<any>, _links: list<any>, createdTime: string, description: string, fileId: string, id: string, name: string, relatedId: string, relatedType: string, updatedTime: string>"
    post-attachment: "record<_embedded: list<any>, _links: list<any>, createdTime: string, description: string, fileId: string, id: string, name: string, relatedId: string, relatedType: string, updatedTime: string>"
    get-attachment: "record<_embedded: list<any>, _links: list<any>, createdTime: string, description: string, fileId: string, id: string, name: string, relatedId: string, relatedType: string, updatedTime: string>"
    put-attachment: "record<_embedded: list<any>, _links: list<any>, createdTime: string, description: string, fileId: string, id: string, name: string, relatedId: string, relatedType: string, updatedTime: string>"
    get-authentication-option: "table<authTokenTtl: int, credentialTtl: int, otpRequired: bool, passwordPattern: string, resetTokenTtl: int>"
    put-authentication-option: "record<authTokenTtl: int, credentialTtl: int, otpRequired: bool, passwordPattern: string, resetTokenTtl: int>"
    get-authentication-token-collection: "table<credentialId: string, mode: string, otpRequired: bool, token: string>"
    post-authentication-token: "record<credentialId: string, mode: string, otpRequired: bool, token: string>"
    get-authentication-token-verification: "record<credentialId: string, mode: string, otpRequired: bool, token: string>"
    post-authentication-token-exchange: "record<_links: table<rel: string, href: string>, acl: table<permissions: list, scope: record>, createdTime: string, customClaims: record, customerId: string, expiredTime: string, id: string, invalidate: bool, oneTimePassword: string, token: string, type: string, updatedTime: string>"
    get-bank-account-collection: "table<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, fingerprint: string, id: string, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>>"
    post-bank-account: "record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, fingerprint: string, id: string, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>>"
    get-bank-account: "record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, fingerprint: string, id: string, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>>"
    patch-bank-account: "record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, fingerprint: string, id: string, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>>"
    put-bank-account: "record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, fingerprint: string, id: string, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>>"
    post-bank-account-deactivation: "record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, fingerprint: string, id: string, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>>"
    get-blocklist-collection: "table<_links: list<record>, createdTime: string, expirationTime: string, id: string, type: string, updatedTime: string, value: string>"
    post-blocklist: "record<_links: table<rel: string, href: string>, createdTime: string, expirationTime: string, id: string, type: string, updatedTime: string, value: string>"
    get-blocklist: "record<_links: table<rel: string, href: string>, createdTime: string, expirationTime: string, id: string, type: string, updatedTime: string, value: string>"
    put-blocklist: "record<_links: table<rel: string, href: string>, createdTime: string, expirationTime: string, id: string, type: string, updatedTime: string, value: string>"
    get-coupon-collection: "table<_links: list<record>, createdTime: string, description: string, discount: record<type: string>, expiredTime: string, id: string, issuedTime: string, redemptionsCount: int, restrictions: list<record>, status: string, updatedTime: string>"
    post-coupon: "record<_links: table<rel: string, href: string>, createdTime: string, description: string, discount: record<type: string>, expiredTime: string, id: string, issuedTime: string, redemptionsCount: int, restrictions: table<type: string>, status: string, updatedTime: string>"
    get-coupon-redemption-collection: "table<_links: list<record>, additionalRestrictions: list<record>, canceledTime: string, couponId: string, createdTime: string, customerId: string, id: string>"
    post-coupon-redemption: "record<_links: table<rel: string, href: string>, additionalRestrictions: table<type: string>, canceledTime: string, couponId: string, createdTime: string, customerId: string, id: string>"
    get-coupon-redemption: "record<_links: table<rel: string, href: string>, additionalRestrictions: table<type: string>, canceledTime: string, couponId: string, createdTime: string, customerId: string, id: string>"
    get-coupon: "record<_links: table<rel: string, href: string>, createdTime: string, description: string, discount: record<type: string>, expiredTime: string, id: string, issuedTime: string, redemptionsCount: int, restrictions: table<type: string>, status: string, updatedTime: string>"
    put-coupon: "record<_links: table<rel: string, href: string>, createdTime: string, description: string, discount: record<type: string>, expiredTime: string, id: string, issuedTime: string, redemptionsCount: int, restrictions: table<type: string>, status: string, updatedTime: string>"
    post-coupon-expiration: "record<_links: table<rel: string, href: string>, createdTime: string, description: string, discount: record<type: string>, expiredTime: string, id: string, issuedTime: string, redemptionsCount: int, restrictions: table<type: string>, status: string, updatedTime: string>"
    get-credential-collection: "table<_links: list<any>, customerId: string, expiredTime: string, id: string, password: string, username: string>"
    post-credential: "record<_links: list<any>, customerId: string, expiredTime: string, id: string, password: string, username: string>"
    get-credential: "record<_links: list<any>, customerId: string, expiredTime: string, id: string, password: string, username: string>"
    put-credential: "record<_links: list<any>, customerId: string, expiredTime: string, id: string, password: string, username: string>"
    get-custom-field-collection: "table<_links: list<record>, additionalSchema: any, description: string, name: string, type: string>"
    get-custom-field: "record<_links: table<rel: string, href: string>, additionalSchema: any, description: string, name: string, type: string>"
    put-custom-field: "record<_links: table<rel: string, href: string>, additionalSchema: any, description: string, name: string, type: string>"
    get-customer-timeline-custom-event-type-collection: "table<_links: list<record>, createdTime: string, id: string, name: string, updatedTime: string>"
    post-customer-timeline-custom-event-type: "record<_links: table<rel: string, href: string>, createdTime: string, id: string, name: string, updatedTime: string>"
    get-customer-timeline-custom-event-type: "record<_links: table<rel: string, href: string>, createdTime: string, id: string, name: string, updatedTime: string>"
    get-customer-timeline-event-collection: "table<_links: list<record>, customData: record, customEventType: string, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>"
    get-customer-collection: "table<_embedded: list<any>, _links: list<any>, averageValue: record<amount: float, amountUsd: float, currency: string>, createdTime: string, customFields: record, defaultPaymentInstrument: record, email: string, firstName: string, id: string, invoiceCount: int, lastName: string, lastPaymentTime: string, lifetimeRevenue: record<amount: float, amountUsd: float, currency: string>, paymentCount: int, paymentToken: string, primaryAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, revision: int, tags: list<record>, updatedTime: string, websiteId: string>"
    post-customer: "record<_embedded: list<any>, _links: list<any>, averageValue: record<amount: float, amountUsd: float, currency: string>, createdTime: string, customFields: record, defaultPaymentInstrument: record, email: string, firstName: string, id: string, invoiceCount: int, lastName: string, lastPaymentTime: string, lifetimeRevenue: record<amount: float, amountUsd: float, currency: string>, paymentCount: int, paymentToken: string, primaryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, revision: int, tags: table<_links: list, createdTime: string, id: string, name: string, updatedTime: string>, updatedTime: string, websiteId: string>"
    get-customer: "record<_embedded: list<any>, _links: list<any>, averageValue: record<amount: float, amountUsd: float, currency: string>, createdTime: string, customFields: record, defaultPaymentInstrument: record, email: string, firstName: string, id: string, invoiceCount: int, lastName: string, lastPaymentTime: string, lifetimeRevenue: record<amount: float, amountUsd: float, currency: string>, paymentCount: int, paymentToken: string, primaryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, revision: int, tags: table<_links: list, createdTime: string, id: string, name: string, updatedTime: string>, updatedTime: string, websiteId: string>"
    put-customer: "record<_embedded: list<any>, _links: list<any>, averageValue: record<amount: float, amountUsd: float, currency: string>, createdTime: string, customFields: record, defaultPaymentInstrument: record, email: string, firstName: string, id: string, invoiceCount: int, lastName: string, lastPaymentTime: string, lifetimeRevenue: record<amount: float, amountUsd: float, currency: string>, paymentCount: int, paymentToken: string, primaryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, revision: int, tags: table<_links: list, createdTime: string, id: string, name: string, updatedTime: string>, updatedTime: string, websiteId: string>"
    get-customer-lead-source: "record<_links: list<any>, affiliate: string, campaign: string, clickId: string, content: string, createdTime: string, medium: string, path: string, referrer: string, salesAgent: string, source: string, subAffiliate: string, term: string, original: record<_links: list<any>, affiliate: string, campaign: string, clickId: string, content: string, createdTime: string, medium: string, path: string, referrer: string, salesAgent: string, source: string, subAffiliate: string, term: string>>"
    put-customer-lead-source: "record<_links: list<any>, affiliate: string, campaign: string, clickId: string, content: string, createdTime: string, medium: string, path: string, referrer: string, salesAgent: string, source: string, subAffiliate: string, term: string, original: record<_links: list<any>, affiliate: string, campaign: string, clickId: string, content: string, createdTime: string, medium: string, path: string, referrer: string, salesAgent: string, source: string, subAffiliate: string, term: string>>"
    get-customer-timeline-collection: "table<_links: list<record>, customData: record, customEventType: string, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>"
    post-customer-timeline: "record<_links: table<rel: string, href: string>, customData: record, customEventType: string, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>"
    get-customer-timeline: "record<_links: table<rel: string, href: string>, customData: record, customEventType: string, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>"
    get-customer-upcoming-invoice-collection: "table<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, discountAmount: float, discounts: list<record>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: list<record>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list, afterRetryEndPolicies: list, attempts: list>, revision: int, transactions: list<record>, type: string>"
    post-digital-wallet-validation: "record<type: string>"
    get-dispute-collection: "table<_embedded: list<any>, _links: list<any>, acquirerReferenceNumber: string, amount: float, caseId: string, category: string, createdTime: string, currency: string, customerId: string, deadlineTime: string, id: string, postedTime: string, rawResponse: string, reasonCode: string, resolvedTime: string, status: string, transactionId: string, type: string, updatedTime: string>"
    post-dispute: "record<_embedded: list<any>, _links: list<any>, acquirerReferenceNumber: string, amount: float, caseId: string, category: string, createdTime: string, currency: string, customerId: string, deadlineTime: string, id: string, postedTime: string, rawResponse: string, reasonCode: string, resolvedTime: string, status: string, transactionId: string, type: string, updatedTime: string>"
    get-dispute: "record<_embedded: list<any>, _links: list<any>, acquirerReferenceNumber: string, amount: float, caseId: string, category: string, createdTime: string, currency: string, customerId: string, deadlineTime: string, id: string, postedTime: string, rawResponse: string, reasonCode: string, resolvedTime: string, status: string, transactionId: string, type: string, updatedTime: string>"
    put-dispute: "record<_embedded: list<any>, _links: list<any>, acquirerReferenceNumber: string, amount: float, caseId: string, category: string, createdTime: string, currency: string, customerId: string, deadlineTime: string, id: string, postedTime: string, rawResponse: string, reasonCode: string, resolvedTime: string, status: string, transactionId: string, type: string, updatedTime: string>"
    get-file-collection: "table<_links: list<any>, createdTime: string, description: string, extension: string, height: int, id: string, isPublic: bool, mime: string, name: string, sha1: string, size: int, tags: list<string>, updatedTime: string, width: int>"
    post-file: "record<_links: list<any>, createdTime: string, description: string, extension: string, height: int, id: string, isPublic: bool, mime: string, name: string, sha1: string, size: int, tags: list<string>, updatedTime: string, width: int>"
    get-file: "record<_links: list<any>, createdTime: string, description: string, extension: string, height: int, id: string, isPublic: bool, mime: string, name: string, sha1: string, size: int, tags: list<string>, updatedTime: string, width: int>"
    put-file: "record<_links: list<any>, createdTime: string, description: string, extension: string, height: int, id: string, isPublic: bool, mime: string, name: string, sha1: string, size: int, tags: list<string>, updatedTime: string, width: int>"
    get-file-download: "string"
    get-file-download-extension: "string"
    get-invoice-collection: "table<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, discountAmount: float, discounts: list<record>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: list<record>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list, afterRetryEndPolicies: list, attempts: list>, revision: int, transactions: list<record>, type: string>"
    post-invoice: "record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<\"3ds\": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>"
    get-invoice: "record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<\"3ds\": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>"
    put-invoice: "record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<\"3ds\": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>"
    post-invoice-abandonment: "record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<\"3ds\": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>"
    post-invoice-issuance: "record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<\"3ds\": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>"
    get-invoice-item-collection: "table<_embedded: list<any>, _links: list<any>, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>"
    post-invoice-item: "record<_embedded: list<any>, _links: list<any>, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>"
    post-invoice-recalculation: "record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<\"3ds\": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>"
    post-invoice-reissuance: "record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<\"3ds\": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>"
    get-invoice-timeline-collection: "table<_links: list<record>, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>"
    post-invoice-timeline: "record<_links: table<rel: string, href: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>"
    get-invoice-timeline: "record<_links: table<rel: string, href: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>"
    post-invoice-transaction: "record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<\"3ds\": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>"
    get-invoice-transaction-allocation-collection: "table<_links: list<any>, amount: float, currency: string, invoiceId: string, transactionId: string>"
    post-invoice-void: "record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<\"3ds\": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>"
    get-kyc-document-collection: "list<any>"
    get-kyc-request-collection: "table<createdTime: string, documents: list<record>, expirationTime: string, id: string, redirectUrl: string, updatedTime: string, _links: list<any>, customerId: string, matchLevel: int, reason: string>"
    post-kyc-request: "record<createdTime: string, documents: table<maxAttempts: int, subtypes: list, type: string>, expirationTime: string, id: string, redirectUrl: string, updatedTime: string, _links: list<any>, customerId: string, matchLevel: int, reason: string>"
    get-kyc-request: "record<createdTime: string, documents: table<maxAttempts: int, subtypes: list, type: string>, expirationTime: string, id: string, redirectUrl: string, updatedTime: string, _links: list<any>, customerId: string, matchLevel: int, reason: string>"
    patch-kyc-request: "record<createdTime: string, documents: table<maxAttempts: int, subtypes: list, type: string>, expirationTime: string, id: string, redirectUrl: string, updatedTime: string, _links: list<any>, customerId: string, matchLevel: int, reason: string>"
    get-password-token-collection: "table<_links: list<record>, credentialId: string, expiredTime: string, token: string, username: string>"
    post-password-token: "record<_links: table<rel: string, href: string>, credentialId: string, expiredTime: string, token: string, username: string>"
    get-password-token: "record<_links: table<rel: string, href: string>, credentialId: string, expiredTime: string, token: string, username: string>"
    get-payment-card-collection: "table<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, bin: string, brand: string, createdTime: string, customFields: record, customerId: string, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: string, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: string, stickyGatewayAccountId: string>"
    post-payment-card: "record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: string, createdTime: string, customFields: record, customerId: string, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: string, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: string, stickyGatewayAccountId: string>"
    get-payment-card: "record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: string, createdTime: string, customFields: record, customerId: string, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: string, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: string, stickyGatewayAccountId: string>"
    patch-payment-card: "record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: string, createdTime: string, customFields: record, customerId: string, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: string, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: string, stickyGatewayAccountId: string>"
    put-payment-card: "record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: string, createdTime: string, customFields: record, customerId: string, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: string, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: string, stickyGatewayAccountId: string>"
    post-payment-card-deactivation: "record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: string, createdTime: string, customFields: record, customerId: string, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: string, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: string, stickyGatewayAccountId: string>"
    get-payment-instrument-collection: "list<any>"
    post-payout: "record<\"3ds\": record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list<string>, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, acquirerName: string, arn: string, bin: string, bumpOffer: record<language: string, order: record<amount: float, currency: string>, outcome: string, presentedOffers: list<record>, selectedOffer: record<bumpAmount: float, bumpAmountInUsd: float, customFields: record, offerId: string, offerType: string>, version: string>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: float>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>"
    get-pay-pal-account-collection: "table<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, id: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, username: string, _embedded: list<any>, _links: list<any>>"
    post-pay-pal-account: "record<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, id: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, username: string, _embedded: list<any>, _links: list<any>>"
    get-pay-pal-account: "record<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, id: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, username: string, _embedded: list<any>, _links: list<any>>"
    put-pay-pal-account: "record<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, id: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, username: string, _embedded: list<any>, _links: list<any>>"
    post-pay-pal-account-deactivation: "record<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, id: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, username: string, _embedded: list<any>, _links: list<any>>"
    get-plan-collection: "table<createdTime: string, currency: string, currencySign: string, customFields: record, id: string, isTrialOnly: bool, name: string, pricing: record<formula: string>, productId: string, productOptions: record, recurringInterval: record<length: int, unit: string, billingTiming: string, limit: int>, revision: int, setup: record<price: float>, trial: record<period: record, price: float>, updatedTime: string, _links: list<record>, invoiceTimeShift: record<dueTimeShift: record, issueTimeShift: record>>"
    post-plan: "record<createdTime: string, currency: string, currencySign: string, customFields: record, id: string, isTrialOnly: bool, name: string, pricing: record<formula: string>, productId: string, productOptions: record, recurringInterval: record<length: int, unit: string, billingTiming: string, limit: int>, revision: int, setup: record<price: float>, trial: record<period: record<length: int, unit: string>, price: float>, updatedTime: string, _links: table<rel: string, href: string>, invoiceTimeShift: record<dueTimeShift: record<duration: int, unit: any>, issueTimeShift: record<chronology: string, duration: int, unit: any>>>"
    get-plan: "record<createdTime: string, currency: string, currencySign: string, customFields: record, id: string, isTrialOnly: bool, name: string, pricing: record<formula: string>, productId: string, productOptions: record, recurringInterval: record<length: int, unit: string, billingTiming: string, limit: int>, revision: int, setup: record<price: float>, trial: record<period: record<length: int, unit: string>, price: float>, updatedTime: string, _links: table<rel: string, href: string>, invoiceTimeShift: record<dueTimeShift: record<duration: int, unit: any>, issueTimeShift: record<chronology: string, duration: int, unit: any>>>"
    put-plan: "record<createdTime: string, currency: string, currencySign: string, customFields: record, id: string, isTrialOnly: bool, name: string, pricing: record<formula: string>, productId: string, productOptions: record, recurringInterval: record<length: int, unit: string, billingTiming: string, limit: int>, revision: int, setup: record<price: float>, trial: record<period: record<length: int, unit: string>, price: float>, updatedTime: string, _links: table<rel: string, href: string>, invoiceTimeShift: record<dueTimeShift: record<duration: int, unit: any>, issueTimeShift: record<chronology: string, duration: int, unit: any>>>"
    get-product-collection: "table<createdTime: string, customFields: record, description: string, id: string, name: string, options: list<string>, requiresShipping: bool, unitLabel: string, updatedTime: string, _links: list<record>, accountingCode: string, taxCategoryId: string>"
    post-product: "record<createdTime: string, customFields: record, description: string, id: string, name: string, options: list<string>, requiresShipping: bool, unitLabel: string, updatedTime: string, _links: table<rel: string, href: string>, accountingCode: string, taxCategoryId: string>"
    get-product: "record<createdTime: string, customFields: record, description: string, id: string, name: string, options: list<string>, requiresShipping: bool, unitLabel: string, updatedTime: string, _links: table<rel: string, href: string>, accountingCode: string, taxCategoryId: string>"
    put-product: "record<createdTime: string, customFields: record, description: string, id: string, name: string, options: list<string>, requiresShipping: bool, unitLabel: string, updatedTime: string, _links: table<rel: string, href: string>, accountingCode: string, taxCategoryId: string>"
    post-ready-to-pay: "list<any>"
    get-search: "table<customers: list<record>, invoices: list<record>, orders: list<record>, searched: list<string>, transactions: list<record>>"
    get-shipping-zone-collection: "table<_links: list<record>, countries: list<string>, createdTime: string, id: string, isDefault: any, name: string, rates: list<record>, updatedTime: string>"
    post-shipping-zone: "record<_links: table<rel: string, href: string>, countries: list<string>, createdTime: string, id: string, isDefault: any, name: string, rates: table<_links: list, currency: string, maxOrderSubtotal: float, minOrderSubtotal: float, name: string, price: float>, updatedTime: string>"
    get-shipping-zone: "record<_links: table<rel: string, href: string>, countries: list<string>, createdTime: string, id: string, isDefault: any, name: string, rates: table<_links: list, currency: string, maxOrderSubtotal: float, minOrderSubtotal: float, name: string, price: float>, updatedTime: string>"
    put-shipping-zone: "record<_links: table<rel: string, href: string>, countries: list<string>, createdTime: string, id: string, isDefault: any, name: string, rates: table<_links: list, currency: string, maxOrderSubtotal: float, minOrderSubtotal: float, name: string, price: float>, updatedTime: string>"
    get-subscription-cancellation-collection: "table<_links: list<record>, appliedInvoiceId: string, canceledBy: string, canceledTime: string, churnTime: string, createdTime: string, description: string, id: string, lineItemSubtotal: float, lineItems: list<record>, prorated: bool, proratedInvoiceId: string, reason: string, status: string, subscriptionId: string>"
    post-subscription-cancellation: "record<_links: table<rel: string, href: string>, appliedInvoiceId: string, canceledBy: string, canceledTime: string, churnTime: string, createdTime: string, description: string, id: string, lineItemSubtotal: float, lineItems: table<createdTime: string, description: string, periodEndTime: string, periodStartTime: string, quantity: int, type: string, unitPriceAmount: float, unitPriceCurrency: string>, prorated: bool, proratedInvoiceId: string, reason: string, status: string, subscriptionId: string>"
    get-subscription-cancellation: "record<_links: table<rel: string, href: string>, appliedInvoiceId: string, canceledBy: string, canceledTime: string, churnTime: string, createdTime: string, description: string, id: string, lineItemSubtotal: float, lineItems: table<createdTime: string, description: string, periodEndTime: string, periodStartTime: string, quantity: int, type: string, unitPriceAmount: float, unitPriceCurrency: string>, prorated: bool, proratedInvoiceId: string, reason: string, status: string, subscriptionId: string>"
    put-subscription-cancellation: "record<_links: table<rel: string, href: string>, appliedInvoiceId: string, canceledBy: string, canceledTime: string, churnTime: string, createdTime: string, description: string, id: string, lineItemSubtotal: float, lineItems: table<createdTime: string, description: string, periodEndTime: string, periodStartTime: string, quantity: int, type: string, unitPriceAmount: float, unitPriceCurrency: string>, prorated: bool, proratedInvoiceId: string, reason: string, status: string, subscriptionId: string>"
    get-subscription-reactivation-collection: "table<_links: list<record>, cancellationId: string, createdTime: string, description: string, effectiveTime: string, id: string, renewalTime: string, subscriptionId: string>"
    post-subscription-reactivation: "record<_links: table<rel: string, href: string>, cancellationId: string, createdTime: string, description: string, effectiveTime: string, id: string, renewalTime: string, subscriptionId: string>"
    get-subscription-reactivation: "record<_links: table<rel: string, href: string>, cancellationId: string, createdTime: string, description: string, effectiveTime: string, id: string, renewalTime: string, subscriptionId: string>"
    get-subscription-collection: "table<orderType: string>"
    post-subscription: "record<orderType: string>"
    get-subscription: "record<orderType: string>"
    put-subscription: "record<orderType: string>"
    post-subscription-items-change: "record<orderType: string>"
    post-subscription-interim-invoice: "record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<\"3ds\": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>"
    get-subscription-timeline-collection: "table<_links: list<record>, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>"
    post-subscription-timeline: "record<_links: table<rel: string, href: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>"
    get-subscription-timeline: "record<_links: table<rel: string, href: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>"
    get-subscription-upcoming-invoice-collection: "table<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, discountAmount: float, discounts: list<record>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: list<record>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list, afterRetryEndPolicies: list, attempts: list>, revision: int, transactions: list<record>, type: string>"
    post-upcoming-invoice-issuance: "record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<\"3ds\": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>"
    get-tag-collection: "table<_links: list<any>, createdTime: string, id: string, name: string, updatedTime: string>"
    post-tag: "record<_links: list<any>, createdTime: string, id: string, name: string, updatedTime: string>"
    get-tag: "record<_links: list<any>, createdTime: string, id: string, name: string, updatedTime: string>"
    patch-tag: "record<_links: list<any>, createdTime: string, id: string, name: string, updatedTime: string>"
    get-token-collection: "list<any>"
    get-transaction-collection: "table<\"3ds\": record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list<string>, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, acquirerName: string, arn: string, bin: string, bumpOffer: record<language: string, order: record, outcome: string, presentedOffers: list, selectedOffer: record, version: string>, dcc: record<base: record, outcome: string, quote: record, usdMarkup: float>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record, cvvResponse: record, response: record>, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>"
    post-transaction: "record<\"3ds\": record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list<string>, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, acquirerName: string, arn: string, bin: string, bumpOffer: record<language: string, order: record<amount: float, currency: string>, outcome: string, presentedOffers: list<record>, selectedOffer: record<bumpAmount: float, bumpAmountInUsd: float, customFields: record, offerId: string, offerType: string>, version: string>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: float>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>"
    get-transaction: "record<\"3ds\": record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list<string>, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, acquirerName: string, arn: string, bin: string, bumpOffer: record<language: string, order: record<amount: float, currency: string>, outcome: string, presentedOffers: list<record>, selectedOffer: record<bumpAmount: float, bumpAmountInUsd: float, customFields: record, offerId: string, offerType: string>, version: string>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: float>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>"
    patch-transaction: "record<\"3ds\": record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list<string>, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, acquirerName: string, arn: string, bin: string, bumpOffer: record<language: string, order: record<amount: float, currency: string>, outcome: string, presentedOffers: list<record>, selectedOffer: record<bumpAmount: float, bumpAmountInUsd: float, customFields: record, offerId: string, offerType: string>, version: string>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: float>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>"
    post-transaction-query: "record<amount: float, currency: string, result: string, status: string>"
    post-transaction-refund: "record<\"3ds\": record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list<string>, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, acquirerName: string, arn: string, bin: string, bumpOffer: record<language: string, order: record<amount: float, currency: string>, outcome: string, presentedOffers: list<record>, selectedOffer: record<bumpAmount: float, bumpAmountInUsd: float, customFields: record, offerId: string, offerType: string>, version: string>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: float>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>"
    get-transaction-timeline-collection: "table<_links: list<record>, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>"
    post-transaction-timeline: "record<_links: table<rel: string, href: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>"
    get-transaction-timeline: "record<_links: table<rel: string, href: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>"
    post-transaction-update: "record<\"3ds\": record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list<string>, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, acquirerName: string, arn: string, bin: string, bumpOffer: record<language: string, order: record<amount: float, currency: string>, outcome: string, presentedOffers: list<record>, selectedOffer: record<bumpAmount: float, bumpAmountInUsd: float, customFields: record, offerId: string, offerType: string>, version: string>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: float>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get3-d-secure-collection" "post3-d-secure" "get3-d-secure" "get-aml-entry" "get-attachment-collection" "post-attachment" "delete-attachment" "get-attachment" "put-attachment" "get-authentication-option" "put-authentication-option" "get-authentication-token-collection" "post-authentication-token" "delete-authentication-token" "get-authentication-token-verification" "post-authentication-token-exchange" "get-bank-account-collection" "post-bank-account" "get-bank-account" "patch-bank-account" "put-bank-account" "post-bank-account-deactivation" "get-blocklist-collection" "post-blocklist" "delete-blocklist" "get-blocklist" "put-blocklist" "get-coupon-collection" "post-coupon" "get-coupon-redemption-collection" "post-coupon-redemption" "get-coupon-redemption" "post-coupon-redemption-cancellation" "get-coupon" "put-coupon" "post-coupon-expiration" "get-credential-collection" "post-credential" "delete-credential" "get-credential" "put-credential" "get-custom-field-collection" "get-custom-field" "put-custom-field" "get-customer-timeline-custom-event-type-collection" "post-customer-timeline-custom-event-type" "get-customer-timeline-custom-event-type" "get-customer-timeline-event-collection" "get-customer-collection" "post-customer" "delete-customer" "get-customer" "put-customer" "delete-customer-lead-source" "get-customer-lead-source" "put-customer-lead-source" "get-customer-timeline-collection" "post-customer-timeline" "delete-customer-timeline" "get-customer-timeline" "get-customer-upcoming-invoice-collection" "post-digital-wallet-validation" "get-dispute-collection" "post-dispute" "get-dispute" "put-dispute" "get-file-collection" "post-file" "delete-file" "get-file" "put-file" "get-file-download" "get-file-download-extension" "get-invoice-collection" "post-invoice" "get-invoice" "put-invoice" "post-invoice-abandonment" "post-invoice-issuance" "get-invoice-item-collection" "post-invoice-item" "post-invoice-recalculation" "post-invoice-reissuance" "get-invoice-timeline-collection" "post-invoice-timeline" "delete-invoice-timeline" "get-invoice-timeline" "post-invoice-transaction" "get-invoice-transaction-allocation-collection" "post-invoice-void" "get-kyc-document-collection" "post-kyc-document" "get-kyc-document" "put-kyc-document" "post-kyc-document-acceptance" "post-kyc-document-matches" "post-kyc-document-rejection" "post-kyc-document-review" "get-kyc-request-collection" "post-kyc-request" "delete-kyc-request" "get-kyc-request" "patch-kyc-request" "get-password-token-collection" "post-password-token" "delete-password-token" "get-password-token" "get-payment-card-collection" "post-payment-card" "get-payment-card" "patch-payment-card" "put-payment-card" "post-payment-card-deactivation" "get-payment-instrument-collection" "post-payment-instrument" "get-payment-instrument" "patch-payment-instrument" "post-payment-instrument-deactivation" "post-payout" "get-pay-pal-account-collection" "post-pay-pal-account" "get-pay-pal-account" "put-pay-pal-account" "post-pay-pal-account-deactivation" "get-plan-collection" "post-plan" "delete-plan" "get-plan" "put-plan" "get-product-collection" "post-product" "delete-product" "get-product" "put-product" "post-ready-to-pay" "get-search" "get-shipping-zone-collection" "post-shipping-zone" "delete-shipping-zone" "get-shipping-zone" "put-shipping-zone" "get-subscription-cancellation-collection" "post-subscription-cancellation" "delete-subscription-cancellation" "get-subscription-cancellation" "put-subscription-cancellation" "get-subscription-reactivation-collection" "post-subscription-reactivation" "get-subscription-reactivation" "get-subscription-collection" "post-subscription" "get-subscription" "put-subscription" "post-subscription-items-change" "post-subscription-interim-invoice" "get-subscription-timeline-collection" "post-subscription-timeline" "delete-subscription-timeline" "get-subscription-timeline" "get-subscription-upcoming-invoice-collection" "post-upcoming-invoice-issuance" "get-tag-collection" "post-tag" "delete-tag" "get-tag" "patch-tag" "delete-tag-customer-collection" "post-tag-customer-collection" "delete-tag-customer" "post-tag-customer" "get-token-collection" "post-token" "get-token" "get-transaction-collection" "post-transaction" "get-transaction" "patch-transaction" "post-transaction-query" "post-transaction-refund" "get-transaction-timeline-collection" "post-transaction-timeline" "delete-transaction-timeline" "get-transaction-timeline" "post-transaction-update" "commands"] | sort) } | get name | first)
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

# Retrieve a list of ThreeDSecure entries
#
# GET /3dsecure
# Returns: table<_links: list<record>, amount: float, cavv: string, createdTime: string, currency: string, customerId: string, eci: int, enrolled: string, enrollmentEci: string, gatewayAccountId: string, id: string, payerAuthResponseStatus: string, paymentCardId: string, signatureVerification: string, websiteId: string, xid: string>
# operationId: Get3DSecureCollection
export def "get3-d-secure-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/3dsecure"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a ThreeDSecure entry
#
# POST /3dsecure
# Returns: record<_links: table<rel: string, href: string>, amount: float, cavv: string, createdTime: string, currency: string, customerId: string, eci: int, enrolled: string, enrollmentEci: string, gatewayAccountId: string, id: string, payerAuthResponseStatus: string, paymentCardId: string, signatureVerification: string, websiteId: string, xid: string>
# operationId: Post3DSecure
export def "post3-d-secure" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  amount: float # Transaction amount. (format: double)
  --cavv: string # The 3D Secure entry cardholder authentication verification value.
  --created-time: string # The 3D Secure entry created time. (format: date-time)
  currency: string # ISO 4217 alphabetic currency code.
  customer_id: string # Related customer ID.
  --eci: int # The 3D Secure entry electronic commerce indicator.
  enrolled: string@enrolled-completer # Is the cardholder enrolled in 3DSecure.
  enrollment_eci: string # The 3D Secure entry enrollment eci.
  gateway_account_id: string # Related gateway account ID.
  --payer-auth-response-status: string@payer-auth-response-status-completer # The 3D Secure entry Auth Response Status.
  payment_card_id: string # Related payment card ID.
  --signature-verification: string@signature-verification-completer # If signature was verified.
  website_id: string # Related Website ID.
  --xid: string # The 3D Secure entry transaction Id.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/3dsecure"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: cavv, var: cavv}, {name: createdTime, var: created_time}, {name: currency, var: currency}, {name: customerId, var: customer_id}, {name: eci, var: eci}, {name: enrolled, var: enrolled}, {name: enrollmentEci, var: enrollment_eci}, {name: gatewayAccountId, var: gateway_account_id}, {name: payerAuthResponseStatus, var: payer_auth_response_status}, {name: paymentCardId, var: payment_card_id}, {name: signatureVerification, var: signature_verification}, {name: websiteId, var: website_id}, {name: xid, var: xid}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, amount: $amount, cavv: $cavv, created_time: $created_time, currency: $currency, customer_id: $customer_id, eci: $eci, enrolled: $enrolled, enrollment_eci: $enrollment_eci, gateway_account_id: $gateway_account_id, payer_auth_response_status: $payer_auth_response_status, payment_card_id: $payment_card_id, signature_verification: $signature_verification, website_id: $website_id, xid: $xid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a ThreeDSecure entry
#
# GET /3dsecure/{id}
# Returns: record<_links: table<rel: string, href: string>, amount: float, cavv: string, createdTime: string, currency: string, customerId: string, eci: int, enrolled: string, enrollmentEci: string, gatewayAccountId: string, id: string, payerAuthResponseStatus: string, paymentCardId: string, signatureVerification: string, websiteId: string, xid: string>
# operationId: Get3DSecure
export def "get3-d-secure" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/3dsecure/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search PEP/Sanctions/Adverse Media lists
#
# GET /aml
# Returns: table<_links: list<record>, address: list<record>, aliases: list<record>, comments: string, confidence: string, dob: list<string>, firstName: string, gender: string, lastName: string, legalBasis: list<string>, nationality: string, passport: list<record>, regime: string, source: string, sourceType: string, title: list<string>, type: string>
# operationId: GetAmlEntry
export def "get-aml-entry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string # First name of individual to search. (required)
  --last-name: string # Last name of individual to search. (required)
  --dob: string # Date of birth in format YYYY-MM-DD.
  --country: string # Country of individual as an ISO Alpha-2 code.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/aml"
    query: [{name: firstName, var: first_name, required: true}, {name: lastName, var: last_name, required: true}, {name: dob, var: dob}, {name: country, var: country}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    first_name: $first_name, last_name: $last_name, dob: $dob, country: $country, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of Attachments
#
# GET /attachments
# Returns: table<_embedded: list<any>, _links: list<any>, createdTime: string, description: string, fileId: string, id: string, name: string, relatedId: string, relatedType: string, updatedTime: string>
# operationId: GetAttachmentCollection
export def "get-attachment-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --fields: string # Limit the returned fields to the list specified, separated by comma. Note that id is always returned.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/attachments"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: q, var: q}, {name: expand, var: expand}, {name: fields, var: fields}, {name: sort, var: sort, style: csv}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, filter: $filter, q: $q, expand: $expand, fields: $fields, sort: $sort, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Attachment
#
# POST /attachments
# Returns: record<_embedded: list<any>, _links: list<any>, createdTime: string, description: string, fileId: string, id: string, name: string, relatedId: string, relatedType: string, updatedTime: string>
# operationId: PostAttachment
export def "post-attachment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # Creation date/time. (format: date-time)
  --description: string # The Attachment description.
  file_id: string # Linked File object id.
  --name: string # The Original Attachment name.
  related_id: string # Linked object Id.
  related_type: string@related-type-completer # Linked object type.
  --updated-time: string # Latest update date/time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/attachments"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: description, var: description}, {name: fileId, var: file_id}, {name: name, var: name}, {name: relatedId, var: related_id}, {name: relatedType, var: related_type}, {name: updatedTime, var: updated_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, created_time: $created_time, description: $description, file_id: $file_id, name: $name, related_id: $related_id, related_type: $related_type, updated_time: $updated_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Attachment
#
# DELETE /attachments/{id}
# operationId: DeleteAttachment
export def "delete-attachment" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/attachments/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an Attachment
#
# GET /attachments/{id}
# Returns: record<_embedded: list<any>, _links: list<any>, createdTime: string, description: string, fileId: string, id: string, name: string, relatedId: string, relatedType: string, updatedTime: string>
# operationId: GetAttachment
export def "get-attachment" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/attachments/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the Attachment with predefined ID
#
# PUT /attachments/{id}
# Returns: record<_embedded: list<any>, _links: list<any>, createdTime: string, description: string, fileId: string, id: string, name: string, relatedId: string, relatedType: string, updatedTime: string>
# operationId: PutAttachment
export def "put-attachment" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # Creation date/time. (format: date-time)
  --description: string # The Attachment description.
  file_id: string # Linked File object id.
  --name: string # The Original Attachment name.
  related_id: string # Linked object Id.
  related_type: string@related-type-completer # Linked object type.
  --updated-time: string # Latest update date/time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/attachments/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: description, var: description}, {name: fileId, var: file_id}, {name: name, var: name}, {name: relatedId, var: related_id}, {name: relatedType, var: related_type}, {name: updatedTime, var: updated_time}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, created_time: $created_time, description: $description, file_id: $file_id, name: $name, related_id: $related_id, related_type: $related_type, updated_time: $updated_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read current authentication options
#
# GET /authentication-options
# Returns: table<authTokenTtl: int, credentialTtl: int, otpRequired: bool, passwordPattern: string, resetTokenTtl: int>
# operationId: GetAuthenticationOption
export def "get-authentication-option" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/authentication-options"
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change authentication options
#
# PUT /authentication-options
# Returns: record<authTokenTtl: int, credentialTtl: int, otpRequired: bool, passwordPattern: string, resetTokenTtl: int>
# operationId: PutAuthenticationOption
export def "put-authentication-option" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --auth-token-ttl: int # The default lifetime of the auth-token in seconds.
  --credential-ttl: int # The default lifetime of the credential in seconds.
  --otp-required: oneof<nothing, bool> # Should OTP be required to exchange token.
  --password-pattern: string # Allowed password pattern.
  --reset-token-ttl: int # The default lifetime of the reset-token in seconds.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/authentication-options"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authTokenTtl, var: auth_token_ttl}, {name: credentialTtl, var: credential_ttl}, {name: otpRequired, var: otp_required}, {name: passwordPattern, var: password_pattern}, {name: resetTokenTtl, var: reset_token_ttl}]}
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    organization_id: $organization_id, auth_token_ttl: $auth_token_ttl, credential_ttl: $credential_ttl, otp_required: $otp_required, password_pattern: $password_pattern, reset_token_ttl: $reset_token_ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of auth tokens
#
# GET /authentication-tokens
# Returns: table<credentialId: string, mode: string, otpRequired: bool, token: string>
# operationId: GetAuthenticationTokenCollection
export def "get-authentication-token-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/authentication-tokens"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Login
#
# POST /authentication-tokens
# Discriminator (request): mode = password, passwordless
# Returns: record<credentialId: string, mode: string, otpRequired: bool, token: string>
# operationId: PostAuthenticationToken
export def "post-authentication-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  mode: string@mode-completer # The token's generation mode. (default: password)
  --otp-required: oneof<nothing, bool> # Should OTP be required to exchange this token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/authentication-tokens"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: mode, var: mode}, {name: otpRequired, var: otp_required}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, mode: $mode, otp_required: $otp_required
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Logout a customer
#
# DELETE /authentication-tokens/{token}
# operationId: DeleteAuthenticationToken
export def "delete-authentication-token" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/authentication-tokens/{token}"
    path_params: [{name: token, var: token_arg}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    token_arg: $token_arg, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify
#
# GET /authentication-tokens/{token}
# Discriminator (response): mode = password, passwordless
# Returns: record<credentialId: string, mode: string, otpRequired: bool, token: string>
# operationId: GetAuthenticationTokenVerification
export def "get-authentication-token-verification" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/authentication-tokens/{token}"
    path_params: [{name: token, var: token_arg}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    token_arg: $token_arg, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exchange
#
# POST /authentication-tokens/{token}/exchange
# Returns: record<_links: table<rel: string, href: string>, acl: table<permissions: list, scope: record>, createdTime: string, customClaims: record, customerId: string, expiredTime: string, id: string, invalidate: bool, oneTimePassword: string, token: string, type: string, updatedTime: string>
# operationId: PostAuthenticationTokenExchange
export def "post-authentication-token-exchange" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --acl: list # item shape: {permissions: list<string>, scope: record}
  --custom-claims: record # e.g. {documents: [identity-proof, address-proof], redirectUrl: https://mywebsite.com}
  --expired-time: string # Session expired time. Defaults to one hour. (format: date-time)
  --invalidate: oneof<nothing, bool> # Whether to invalidate token after exchange or not. (default: true, e.g. true)
  --one-time-password: string # The one time password sent via an email. Should contain digits only. (e.g. 123456)
  --updated-time: string # Session updated time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/authentication-tokens/{token}/exchange"
    path_params: [{name: token, var: token_arg}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: acl, var: acl}, {name: customClaims, var: custom_claims}, {name: expiredTime, var: expired_time}, {name: invalidate, var: invalidate}, {name: oneTimePassword, var: one_time_password}, {name: updatedTime, var: updated_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    token_arg: $token_arg, organization_id: $organization_id, acl: $acl, custom_claims: $custom_claims, expired_time: $expired_time, invalidate: $invalidate, one_time_password: $one_time_password, updated_time: $updated_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of bank accounts
#
# GET /bank-accounts
# Returns: table<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, fingerprint: string, id: string, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>>
# operationId: GetBankAccountCollection
export def "get-bank-account-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The partial search of the text fields.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/bank-accounts"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: q, var: q}, {name: sort, var: sort, style: csv}, {name: filter, var: filter}, {name: expand, var: expand}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, q: $q, sort: $sort, filter: $filter, expand: $expand, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Bank Account
#
# POST /bank-accounts
# Returns: record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, fingerprint: string, id: string, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>>
# operationId: PostBankAccount
export def "post-bank-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --customer-id: string # The Customer's ID.
  --body-token: string # BankAccountToken ID. (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bank-accounts"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, custom_fields: $custom_fields, customer_id: $customer_id, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Bank Account
#
# GET /bank-accounts/{id}
# Returns: record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, fingerprint: string, id: string, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>>
# operationId: GetBankAccount
export def "get-bank-account" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bank-accounts/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a bank account's values
#
# PATCH /bank-accounts/{id}
# Returns: record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, fingerprint: string, id: string, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>>
# operationId: PatchBankAccount
export def "patch-bank-account" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --account-type: string@account-type-completer # Bank's account type.
  --bank-name: string # Bank's name.
  --billing-address: record # The billing address. — shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/bank-accounts/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountType, var: account_type}, {name: bankName, var: bank_name}, {name: billingAddress, var: billing_address}, {name: customFields, var: custom_fields}]}
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, account_type: $account_type, bank_name: $bank_name, billing_address: $billing_address, custom_fields: $custom_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Bank Account with predefined ID
#
# PUT /bank-accounts/{id}
# Returns: record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, fingerprint: string, id: string, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>>
# operationId: PutBankAccount
export def "put-bank-account" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --customer-id: string # The Customer's ID.
  --body-token: string # BankAccountToken ID. (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/bank-accounts/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, custom_fields: $custom_fields, customer_id: $customer_id, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate a Bank Account
#
# POST /bank-accounts/{id}/deactivation
# Returns: record<accountNumberType: string, accountType: string, bankName: string, bic: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, fingerprint: string, id: string, last4: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, routingNumber: string, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>>
# operationId: PostBankAccountDeactivation
export def "post-bank-account-deactivation" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/bank-accounts/{id}/deactivation"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of blocklists
#
# GET /blocklists
# Returns: table<_links: list<record>, createdTime: string, expirationTime: string, id: string, type: string, updatedTime: string, value: string>
# operationId: GetBlocklistCollection
export def "get-blocklist-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/blocklists"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: sort, var: sort, style: csv}, {name: filter, var: filter}, {name: q, var: q}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, sort: $sort, filter: $filter, q: $q, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a blocklist
#
# POST /blocklists
# Returns: record<_links: table<rel: string, href: string>, createdTime: string, expirationTime: string, id: string, type: string, updatedTime: string, value: string>
# operationId: PostBlocklist
export def "post-blocklist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # The blocklist created time. (format: date-time)
  --expiration-time: string # The blocklist expiration time. (format: date-time)
  type: string@type-completer # The blocklist type.
  --updated-time: string # The blocklist updated time. (format: date-time)
  value: string # The blocklist value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/blocklists"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: expirationTime, var: expiration_time}, {name: type, var: type}, {name: updatedTime, var: updated_time}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, created_time: $created_time, expiration_time: $expiration_time, type: $type, updated_time: $updated_time, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a blocklist
#
# DELETE /blocklists/{id}
# operationId: DeleteBlocklist
export def "delete-blocklist" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/blocklists/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a blocklist
#
# GET /blocklists/{id}
# Returns: record<_links: table<rel: string, href: string>, createdTime: string, expirationTime: string, id: string, type: string, updatedTime: string, value: string>
# operationId: GetBlocklist
export def "get-blocklist" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/blocklists/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a blocklist with predefined ID
#
# PUT /blocklists/{id}
# Returns: record<_links: table<rel: string, href: string>, createdTime: string, expirationTime: string, id: string, type: string, updatedTime: string, value: string>
# operationId: PutBlocklist
export def "put-blocklist" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # The blocklist created time. (format: date-time)
  --expiration-time: string # The blocklist expiration time. (format: date-time)
  type: string@type-completer # The blocklist type.
  --updated-time: string # The blocklist updated time. (format: date-time)
  value: string # The blocklist value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/blocklists/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: expirationTime, var: expiration_time}, {name: type, var: type}, {name: updatedTime, var: updated_time}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, created_time: $created_time, expiration_time: $expiration_time, type: $type, updated_time: $updated_time, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of coupons
#
# GET /coupons
# Returns: table<_links: list<record>, createdTime: string, description: string, discount: record<type: string>, expiredTime: string, id: string, issuedTime: string, redemptionsCount: int, restrictions: list<record>, status: string, updatedTime: string>
# operationId: GetCouponCollection
export def "get-coupon-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/coupons"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: q, var: q}, {name: sort, var: sort, style: csv}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, filter: $filter, q: $q, sort: $sort, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a coupon
#
# POST /coupons
# Returns: record<_links: table<rel: string, href: string>, createdTime: string, description: string, discount: record<type: string>, expiredTime: string, id: string, issuedTime: string, redemptionsCount: int, restrictions: table<type: string>, status: string, updatedTime: string>
# operationId: PostCoupon
export def "post-coupon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # Coupon created time. (format: date-time)
  --description: string # Your coupon description. When it is not empty this is used for invoice discount item description, otherwise the item's description uses coupon's ID like 'Coupon "COUPON-ID"'.
  discount: record # shape: {type: "fixed"|"percent"}
  --expired-time: string # Coupon's expire time (end time). (format: date-time)
  issued_time: string # Coupon's issued time (start time). (format: date-time)
  --restrictions: list # Coupon restrictions. — item shape: {type: "discounts-per-redemption"|"minimum-order-amount"|"paid-by-time"|"redemptions-per-customer"|"restrict-to-invoices"|"restrict-to-plans"|"restrict-to-products"|"restrict-to-subscriptions"|"total-redemptions"}
  --updated-time: string # Coupon updated time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/coupons"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: description, var: description}, {name: discount, var: discount}, {name: expiredTime, var: expired_time}, {name: issuedTime, var: issued_time}, {name: restrictions, var: restrictions}, {name: updatedTime, var: updated_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, created_time: $created_time, description: $description, discount: $discount, expired_time: $expired_time, issued_time: $issued_time, restrictions: $restrictions, updated_time: $updated_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of coupon redemptions
#
# GET /coupons-redemptions
# Returns: table<_links: list<record>, additionalRestrictions: list<record>, canceledTime: string, couponId: string, createdTime: string, customerId: string, id: string>
# operationId: GetCouponRedemptionCollection
export def "get-coupon-redemption-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/coupons-redemptions"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: q, var: q}, {name: sort, var: sort, style: csv}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, filter: $filter, q: $q, sort: $sort, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Redeem a coupon
#
# POST /coupons-redemptions
# Returns: record<_links: table<rel: string, href: string>, additionalRestrictions: table<type: string>, canceledTime: string, couponId: string, createdTime: string, customerId: string, id: string>
# operationId: PostCouponRedemption
export def "post-coupon-redemption" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --additional-restrictions: list # Additional restrictions for coupon's redemptions. — item shape: {type: "discounts-per-redemption"|"minimum-order-amount"|"paid-by-time"|"restrict-to-invoices"|"restrict-to-plans"|"restrict-to-products"|"restrict-to-subscriptions"}
  --coupon-id: string # Coupon's ID.
  --customer-id: string # Customer's ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/coupons-redemptions"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalRestrictions, var: additional_restrictions}, {name: couponId, var: coupon_id}, {name: customerId, var: customer_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, additional_restrictions: $additional_restrictions, coupon_id: $coupon_id, customer_id: $customer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a coupon redemption with specified identifier string
#
# GET /coupons-redemptions/{id}
# Returns: record<_links: table<rel: string, href: string>, additionalRestrictions: table<type: string>, canceledTime: string, couponId: string, createdTime: string, customerId: string, id: string>
# operationId: GetCouponRedemption
export def "get-coupon-redemption" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/coupons-redemptions/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel a coupon redemption
#
# POST /coupons-redemptions/{id}/cancel
# operationId: PostCouponRedemptionCancellation
export def "post-coupon-redemption-cancellation" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: post
    path: "/coupons-redemptions/{id}/cancel"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a coupon
#
# GET /coupons/{id}
# Returns: record<_links: table<rel: string, href: string>, createdTime: string, description: string, discount: record<type: string>, expiredTime: string, id: string, issuedTime: string, redemptionsCount: int, restrictions: table<type: string>, status: string, updatedTime: string>
# operationId: GetCoupon
export def "get-coupon" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/coupons/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update a coupon with predefined coupon ID
#
# PUT /coupons/{id}
# Returns: record<_links: table<rel: string, href: string>, createdTime: string, description: string, discount: record<type: string>, expiredTime: string, id: string, issuedTime: string, redemptionsCount: int, restrictions: table<type: string>, status: string, updatedTime: string>
# operationId: PutCoupon
export def "put-coupon" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # Coupon created time. (format: date-time)
  --description: string # Your coupon description. When it is not empty this is used for invoice discount item description, otherwise the item's description uses coupon's ID like 'Coupon "COUPON-ID"'.
  discount: record # shape: {type: "fixed"|"percent"}
  --expired-time: string # Coupon's expire time (end time). (format: date-time)
  issued_time: string # Coupon's issued time (start time). (format: date-time)
  --restrictions: list # Coupon restrictions. — item shape: {type: "discounts-per-redemption"|"minimum-order-amount"|"paid-by-time"|"redemptions-per-customer"|"restrict-to-invoices"|"restrict-to-plans"|"restrict-to-products"|"restrict-to-subscriptions"|"total-redemptions"}
  --updated-time: string # Coupon updated time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/coupons/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: description, var: description}, {name: discount, var: discount}, {name: expiredTime, var: expired_time}, {name: issuedTime, var: issued_time}, {name: restrictions, var: restrictions}, {name: updatedTime, var: updated_time}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, created_time: $created_time, description: $description, discount: $discount, expired_time: $expired_time, issued_time: $issued_time, restrictions: $restrictions, updated_time: $updated_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set a coupon's expiration time
#
# POST /coupons/{id}/expiration
# Returns: record<_links: table<rel: string, href: string>, createdTime: string, description: string, discount: record<type: string>, expiredTime: string, id: string, issuedTime: string, redemptionsCount: int, restrictions: table<type: string>, status: string, updatedTime: string>
# operationId: PostCouponExpiration
export def "post-coupon-expiration" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  expired_time: string # The coupon's expiry time, must be greater than the issued time. Null or empty string will immediately expire the coupon. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/coupons/{id}/expiration"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: expiredTime, var: expired_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, expired_time: $expired_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of credentials
#
# GET /credentials
# Returns: table<_links: list<any>, customerId: string, expiredTime: string, id: string, password: string, username: string>
# operationId: GetCredentialCollection
export def "get-credential-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/credentials"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a credential
#
# POST /credentials
# Returns: record<_links: list<any>, customerId: string, expiredTime: string, id: string, password: string, username: string>
# operationId: PostCredential
export def "post-credential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  customer_id: string # The credential's customer ID.
  --expired-time: string # The credential's expired time. (format: date-time)
  password: string # The credential's password. (format: password)
  username: string # Credential's username.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/credentials"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customerId, var: customer_id}, {name: expiredTime, var: expired_time}, {name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, customer_id: $customer_id, expired_time: $expired_time, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a credential
#
# DELETE /credentials/{id}
# operationId: DeleteCredential
export def "delete-credential" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/credentials/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a credential
#
# GET /credentials/{id}
# Returns: record<_links: list<any>, customerId: string, expiredTime: string, id: string, password: string, username: string>
# operationId: GetCredential
export def "get-credential" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/credentials/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update a credential with predefined ID
#
# PUT /credentials/{id}
# Returns: record<_links: list<any>, customerId: string, expiredTime: string, id: string, password: string, username: string>
# operationId: PutCredential
export def "put-credential" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  customer_id: string # The credential's customer ID.
  --expired-time: string # The credential's expired time. (format: date-time)
  password: string # The credential's password. (format: password)
  username: string # Credential's username.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/credentials/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customerId, var: customer_id}, {name: expiredTime, var: expired_time}, {name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, customer_id: $customer_id, expired_time: $expired_time, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Custom Fields
#
# GET /custom-fields/{resource}
# Returns: table<_links: list<record>, additionalSchema: any, description: string, name: string, type: string>
# operationId: GetCustomFieldCollection
export def "get-custom-field-collection" [
  resource: string@resource-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/custom-fields/{resource}"
    path_params: [{name: resource, var: resource}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    resource: $resource, limit: $limit, offset: $offset, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Custom Field
#
# GET /custom-fields/{resource}/{name}
# Returns: record<_links: table<rel: string, href: string>, additionalSchema: any, description: string, name: string, type: string>
# operationId: GetCustomField
export def "get-custom-field" [
  resource: string@resource-completer
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/custom-fields/{resource}/{name}"
    path_params: [{name: resource, var: resource}, {name: name, var: name}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    resource: $resource, name: $name, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or alter a Custom Field
#
# PUT /custom-fields/{resource}/{name}
# Returns: record<_links: table<rel: string, href: string>, additionalSchema: any, description: string, name: string, type: string>
# operationId: PutCustomField
export def "put-custom-field" [
  resource: string@resource-completer
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --additional-schema: any # Additional parameters which can be added according to type: Parameter Name | Types | Description -------------- | ------------- | ------------- allowedValues | string, array | List of allowed values maxLength | string | Maximum allowed length for the string, 255 by default, up to 4000 The additional schema adds additional constrains for values.
  --description: string # The custom field description.
  type: string@type-completer-1 # Type value | Description ------------- | ------------- array | An array of strings up to 255 characters, maximum size is 1000 elements boolean | true or false date | String of format "full-date" (YYYY-MM-DD) from RFC-3339 (full-date) datetime | String of format "date-time" (YYYY-MM-DDTHH:MM:SSZ) from RFC-3339 (date-time) integer | Cardinal value of -2^31..2^31-1 number | Float value. It can take cardinal values also which are interpreted as float string | Regular string up to 255 characters monetary | A map of 3-letters currency code and amount, e.g. {"currency": "EUR", "amount": 25.30} The type cannot be changed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/custom-fields/{resource}/{name}"
    path_params: [{name: resource, var: resource}, {name: name, var: name}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalSchema, var: additional_schema}, {name: description, var: description}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: reb-apikey
  } {
    resource: $resource, name: $name, organization_id: $organization_id, additional_schema: $additional_schema, description: $description, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of customer timeline custom event types
#
# GET /customer-timeline-custom-events
# Returns: table<_links: list<record>, createdTime: string, id: string, name: string, updatedTime: string>
# operationId: GetCustomerTimelineCustomEventTypeCollection
export def "get-customer-timeline-custom-event-type-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/customer-timeline-custom-events"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, filter: $filter, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Customer Timeline custom event type
#
# POST /customer-timeline-custom-events
# Returns: record<_links: table<rel: string, href: string>, createdTime: string, id: string, name: string, updatedTime: string>
# operationId: PostCustomerTimelineCustomEventType
export def "post-customer-timeline-custom-event-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # Customer Timeline Custom event created time. (format: date-time)
  name: string # Customer Timeline Custom Event type name. It must not be similar to any Rebilly system event.
  --updated-time: string # Customer Timeline Custom event updated time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/customer-timeline-custom-events"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: name, var: name}, {name: updatedTime, var: updated_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, created_time: $created_time, name: $name, updated_time: $updated_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve customer timeline custom event type with specified identifier string
#
# GET /customer-timeline-custom-events/{id}
# Returns: record<_links: table<rel: string, href: string>, createdTime: string, id: string, name: string, updatedTime: string>
# operationId: GetCustomerTimelineCustomEventType
export def "get-customer-timeline-custom-event-type" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/customer-timeline-custom-events/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of customer timeline messages for all customers
#
# GET /customer-timeline-events
# Returns: table<_links: list<record>, customData: record, customEventType: string, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>
# operationId: GetCustomerTimelineEventCollection
export def "get-customer-timeline-event-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/customer-timeline-events"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, filter: $filter, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of customers
#
# GET /customers
# Returns: table<_embedded: list<any>, _links: list<any>, averageValue: record<amount: float, amountUsd: float, currency: string>, createdTime: string, customFields: record, defaultPaymentInstrument: record, email: string, firstName: string, id: string, invoiceCount: int, lastName: string, lastPaymentTime: string, lifetimeRevenue: record<amount: float, amountUsd: float, currency: string>, paymentCount: int, paymentToken: string, primaryAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, revision: int, tags: list<record>, updatedTime: string, websiteId: string>
# operationId: GetCustomerCollection
export def "get-customer-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --fields: string # Limit the returned fields to the list specified, separated by comma. Note that id is always returned.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/customers"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: q, var: q}, {name: expand, var: expand}, {name: fields, var: fields}, {name: sort, var: sort, style: csv}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, filter: $filter, q: $q, expand: $expand, fields: $fields, sort: $sort, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a customer (without an ID)
#
# POST /customers
# Returns: record<_embedded: list<any>, _links: list<any>, averageValue: record<amount: float, amountUsd: float, currency: string>, createdTime: string, customFields: record, defaultPaymentInstrument: record, email: string, firstName: string, id: string, invoiceCount: int, lastName: string, lastPaymentTime: string, lifetimeRevenue: record<amount: float, amountUsd: float, currency: string>, paymentCount: int, paymentToken: string, primaryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, revision: int, tags: table<_links: list, createdTime: string, id: string, name: string, updatedTime: string>, updatedTime: string, websiteId: string>
# operationId: PostCustomer
export def "post-customer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # The customer created time. (format: date-time)
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --default-payment-instrument: record # shape: {method: "payment-card"|"ach"|"paypal", paymentInstrumentId?: string, receivedBy?: string, reference?: string}
  --last-payment-time: string # The most recent time of an approved payment for the customer. (format: date-time)
  --payment-token: string # A write-only payment token; if supplied, it will be converted into a payment instrument and be set as the `defaultPaymentInstrument`. The value of this property will override the `defaultPaymentInstrument` in the case that both are supplied. The token may only be used once before it is expired.
  --primary-address: record # shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  --updated-time: string # The customer updated time. (format: date-time)
  --website-id: string # The website's ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/customers"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: customFields, var: custom_fields}, {name: defaultPaymentInstrument, var: default_payment_instrument}, {name: lastPaymentTime, var: last_payment_time}, {name: paymentToken, var: payment_token}, {name: primaryAddress, var: primary_address}, {name: updatedTime, var: updated_time}, {name: websiteId, var: website_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, created_time: $created_time, custom_fields: $custom_fields, default_payment_instrument: $default_payment_instrument, last_payment_time: $last_payment_time, payment_token: $payment_token, primary_address: $primary_address, updated_time: $updated_time, website_id: $website_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Merge and delete a customer
#
# DELETE /customers/{id}
# operationId: DeleteCustomer
export def "delete-customer" [
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
  --target-customer-id: string # The customer identifier to get the data of the deleted duplicate customer. (required)
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/customers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: targetCustomerId, var: target_customer_id, required: true}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    id: $id, target_customer_id: $target_customer_id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a customer
#
# GET /customers/{id}
# Returns: record<_embedded: list<any>, _links: list<any>, averageValue: record<amount: float, amountUsd: float, currency: string>, createdTime: string, customFields: record, defaultPaymentInstrument: record, email: string, firstName: string, id: string, invoiceCount: int, lastName: string, lastPaymentTime: string, lifetimeRevenue: record<amount: float, amountUsd: float, currency: string>, paymentCount: int, paymentToken: string, primaryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, revision: int, tags: table<_links: list, createdTime: string, id: string, name: string, updatedTime: string>, updatedTime: string, websiteId: string>
# operationId: GetCustomer
export def "get-customer" [
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
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --fields: string # Limit the returned fields to the list specified, separated by comma. Note that id is always returned.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/customers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: expand, var: expand}, {name: fields, var: fields}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, expand: $expand, fields: $fields, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upsert a customer with predefined ID
#
# PUT /customers/{id}
# Returns: record<_embedded: list<any>, _links: list<any>, averageValue: record<amount: float, amountUsd: float, currency: string>, createdTime: string, customFields: record, defaultPaymentInstrument: record, email: string, firstName: string, id: string, invoiceCount: int, lastName: string, lastPaymentTime: string, lifetimeRevenue: record<amount: float, amountUsd: float, currency: string>, paymentCount: int, paymentToken: string, primaryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, revision: int, tags: table<_links: list, createdTime: string, id: string, name: string, updatedTime: string>, updatedTime: string, websiteId: string>
# operationId: PutCustomer
export def "put-customer" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # The customer created time. (format: date-time)
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --default-payment-instrument: record # shape: {method: "payment-card"|"ach"|"paypal", paymentInstrumentId?: string, receivedBy?: string, reference?: string}
  --last-payment-time: string # The most recent time of an approved payment for the customer. (format: date-time)
  --payment-token: string # A write-only payment token; if supplied, it will be converted into a payment instrument and be set as the `defaultPaymentInstrument`. The value of this property will override the `defaultPaymentInstrument` in the case that both are supplied. The token may only be used once before it is expired.
  --primary-address: record # shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  --updated-time: string # The customer updated time. (format: date-time)
  --website-id: string # The website's ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/customers/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: customFields, var: custom_fields}, {name: defaultPaymentInstrument, var: default_payment_instrument}, {name: lastPaymentTime, var: last_payment_time}, {name: paymentToken, var: payment_token}, {name: primaryAddress, var: primary_address}, {name: updatedTime, var: updated_time}, {name: websiteId, var: website_id}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, created_time: $created_time, custom_fields: $custom_fields, default_payment_instrument: $default_payment_instrument, last_payment_time: $last_payment_time, payment_token: $payment_token, primary_address: $primary_address, updated_time: $updated_time, website_id: $website_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Lead Source for a customer
#
# DELETE /customers/{id}/lead-source
# operationId: DeleteCustomerLeadSource
export def "delete-customer-lead-source" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/customers/{id}/lead-source"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a customer's Lead Source
#
# GET /customers/{id}/lead-source
# Returns: record<_links: list<any>, affiliate: string, campaign: string, clickId: string, content: string, createdTime: string, medium: string, path: string, referrer: string, salesAgent: string, source: string, subAffiliate: string, term: string, original: record<_links: list<any>, affiliate: string, campaign: string, clickId: string, content: string, createdTime: string, medium: string, path: string, referrer: string, salesAgent: string, source: string, subAffiliate: string, term: string>>
# operationId: GetCustomerLeadSource
export def "get-customer-lead-source" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/customers/{id}/lead-source"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Lead Source for a customer
#
# PUT /customers/{id}/lead-source
# Returns: record<_links: list<any>, affiliate: string, campaign: string, clickId: string, content: string, createdTime: string, medium: string, path: string, referrer: string, salesAgent: string, source: string, subAffiliate: string, term: string, original: record<_links: list<any>, affiliate: string, campaign: string, clickId: string, content: string, createdTime: string, medium: string, path: string, referrer: string, salesAgent: string, source: string, subAffiliate: string, term: string>>
# operationId: PutCustomerLeadSource
export def "put-customer-lead-source" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --affiliate: string # Lead source affiliate (eg 123, Bob Smith).
  --campaign: string # Lead source campaign (eg go-big-123).
  --click-id: string # Lead source click id (may come from an ad server).
  --content: string # Lead source content (eg smiley faces).
  --created-time: string # Lead source created time. (format: date-time)
  --medium: string # Lead source medium (eg search, display).
  --path: string # Lead source path url (eg www.example.com/some/landing/path).
  --referrer: string # Lead source [`referer` url](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referer) as determined (eg www.example.com/some/landing/path).
  --sales-agent: string # Lead source sales agent (eg James Bond).
  --source: string # Lead source origin (eg google, yahoo).
  --sub-affiliate: string # Lead source sub-affiliate also called a sub-id or click id in some circles (eg 123456).
  --term: string # Lead source term (eg salt shakers).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/customers/{id}/lead-source"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: affiliate, var: affiliate}, {name: campaign, var: campaign}, {name: clickId, var: click_id}, {name: content, var: content}, {name: createdTime, var: created_time}, {name: medium, var: medium}, {name: path, var: path}, {name: referrer, var: referrer}, {name: salesAgent, var: sales_agent}, {name: source, var: source}, {name: subAffiliate, var: sub_affiliate}, {name: term, var: term}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, affiliate: $affiliate, campaign: $campaign, click_id: $click_id, content: $content, created_time: $created_time, medium: $medium, path: $path, referrer: $referrer, sales_agent: $sales_agent, source: $source, sub_affiliate: $sub_affiliate, term: $term
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of customer timeline messages
#
# GET /customers/{id}/timeline
# Returns: table<_links: list<record>, customData: record, customEventType: string, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>
# operationId: GetCustomerTimelineCollection
export def "get-customer-timeline-collection" [
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
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --q: string # The partial search of the text fields.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/customers/{id}/timeline"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: sort, var: sort, style: csv}, {name: q, var: q}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, limit: $limit, offset: $offset, filter: $filter, sort: $sort, q: $q, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a customer Timeline comment or custom defined event
#
# POST /customers/{id}/timeline
# Returns: record<_links: table<rel: string, href: string>, customData: record, customEventType: string, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>
# operationId: PostCustomerTimeline
export def "post-customer-timeline" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --custom-data: record # Timeline custom event data. Used with `custom-event` type. Will be transformed to `extraData` two-column table in response. (e.g. {customAttribute: customValue, otherAttribute: otherValue})
  --custom-event-type: string # Timeline custom event type. Used with `custom-event` type. Must be defined using [Customer Timeline custom event API](#operation/PostCustomerTimelineCustomEventType). (nullable)
  --message: string # The message that describes the message details.
  --occurred-time: string # Timeline message time. (format: date-time)
  --type: string@type-completer-2 # Timeline message type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/customers/{id}/timeline"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customData, var: custom_data}, {name: customEventType, var: custom_event_type}, {name: message, var: message}, {name: occurredTime, var: occurred_time}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, custom_data: $custom_data, custom_event_type: $custom_event_type, message: $message, occurred_time: $occurred_time, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Customer Timeline message
#
# DELETE /customers/{id}/timeline/{messageId}
# operationId: DeleteCustomerTimeline
export def "delete-customer-timeline" [
  id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/customers/{id}/timeline/{messageId}"
    path_params: [{name: id, var: id}, {name: messageId, var: message_id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    id: $id, message_id: $message_id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a customer Timeline message
#
# GET /customers/{id}/timeline/{messageId}
# Returns: record<_links: table<rel: string, href: string>, customData: record, customEventType: string, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>
# operationId: GetCustomerTimeline
export def "get-customer-timeline" [
  id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/customers/{id}/timeline/{messageId}"
    path_params: [{name: id, var: id}, {name: messageId, var: message_id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, message_id: $message_id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve customer's upcoming invoices
#
# GET /customers/{id}/upcoming-invoices
# Returns: table<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, discountAmount: float, discounts: list<record>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: list<record>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list, afterRetryEndPolicies: list, attempts: list>, revision: int, transactions: list<record>, type: string>
# operationId: GetCustomerUpcomingInvoiceCollection
export def "get-customer-upcoming-invoice-collection" [
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
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/customers/{id}/upcoming-invoices"
    path_params: [{name: id, var: id}]
    query: [{name: expand, var: expand}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, expand: $expand, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate a digital wallet session
#
# POST /digital-wallets/validation
# Discriminator (request): type = Apple Pay
# Returns: record<type: string>
# operationId: PostDigitalWalletValidation
export def "post-digital-wallet-validation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-3 # Type of the digital wallet to validate.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/digital-wallets/validation"
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of disputes
#
# GET /disputes
# Returns: table<_embedded: list<any>, _links: list<any>, acquirerReferenceNumber: string, amount: float, caseId: string, category: string, createdTime: string, currency: string, customerId: string, deadlineTime: string, id: string, postedTime: string, rawResponse: string, reasonCode: string, resolvedTime: string, status: string, transactionId: string, type: string, updatedTime: string>
# operationId: GetDisputeCollection
export def "get-dispute-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/disputes"
    query: [{name: filter, var: filter}, {name: sort, var: sort, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: q, var: q}, {name: expand, var: expand}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    filter: $filter, sort: $sort, limit: $limit, offset: $offset, q: $q, expand: $expand, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a dispute
#
# POST /disputes
# Returns: record<_embedded: list<any>, _links: list<any>, acquirerReferenceNumber: string, amount: float, caseId: string, category: string, createdTime: string, currency: string, customerId: string, deadlineTime: string, id: string, postedTime: string, rawResponse: string, reasonCode: string, resolvedTime: string, status: string, transactionId: string, type: string, updatedTime: string>
# operationId: PostDispute
export def "post-dispute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --acquirer-reference-number: string # The dispute's acquirer reference number.
  amount: float # The dispute amount. (format: double)
  --case-id: string # The case ID for the dispute.
  --created-time: string # Dispute created time. (format: date-time)
  currency: string # ISO 4217 alphabetic currency code.
  --deadline-time: string # Dispute deadline time. (format: date-time)
  posted_time: string # Dispute posted time. (format: date-time)
  reason_code: string@reason-code-completer # The dispute's reason code.
  --resolved-time: string # Dispute resolved time. (format: date-time)
  status: string@status-completer # The dispute's status.
  transaction_id: string # The dispute's transaction ID.
  type: string@type-completer-4 # The dispute's type.
  --updated-time: string # Dispute updated time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/disputes"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: acquirerReferenceNumber, var: acquirer_reference_number}, {name: amount, var: amount}, {name: caseId, var: case_id}, {name: createdTime, var: created_time}, {name: currency, var: currency}, {name: deadlineTime, var: deadline_time}, {name: postedTime, var: posted_time}, {name: reasonCode, var: reason_code}, {name: resolvedTime, var: resolved_time}, {name: status, var: status}, {name: transactionId, var: transaction_id}, {name: type, var: type}, {name: updatedTime, var: updated_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, acquirer_reference_number: $acquirer_reference_number, amount: $amount, case_id: $case_id, created_time: $created_time, currency: $currency, deadline_time: $deadline_time, posted_time: $posted_time, reason_code: $reason_code, resolved_time: $resolved_time, status: $status, transaction_id: $transaction_id, type: $type, updated_time: $updated_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a dispute
#
# GET /disputes/{id}
# Returns: record<_embedded: list<any>, _links: list<any>, acquirerReferenceNumber: string, amount: float, caseId: string, category: string, createdTime: string, currency: string, customerId: string, deadlineTime: string, id: string, postedTime: string, rawResponse: string, reasonCode: string, resolvedTime: string, status: string, transactionId: string, type: string, updatedTime: string>
# operationId: GetDispute
export def "get-dispute" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/disputes/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update a Dispute with predefined ID
#
# PUT /disputes/{id}
# Returns: record<_embedded: list<any>, _links: list<any>, acquirerReferenceNumber: string, amount: float, caseId: string, category: string, createdTime: string, currency: string, customerId: string, deadlineTime: string, id: string, postedTime: string, rawResponse: string, reasonCode: string, resolvedTime: string, status: string, transactionId: string, type: string, updatedTime: string>
# operationId: PutDispute
export def "put-dispute" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --acquirer-reference-number: string # The dispute's acquirer reference number.
  amount: float # The dispute amount. (format: double)
  --case-id: string # The case ID for the dispute.
  --created-time: string # Dispute created time. (format: date-time)
  currency: string # ISO 4217 alphabetic currency code.
  --deadline-time: string # Dispute deadline time. (format: date-time)
  posted_time: string # Dispute posted time. (format: date-time)
  reason_code: string@reason-code-completer # The dispute's reason code.
  --resolved-time: string # Dispute resolved time. (format: date-time)
  status: string@status-completer # The dispute's status.
  transaction_id: string # The dispute's transaction ID.
  type: string@type-completer-4 # The dispute's type.
  --updated-time: string # Dispute updated time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/disputes/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: acquirerReferenceNumber, var: acquirer_reference_number}, {name: amount, var: amount}, {name: caseId, var: case_id}, {name: createdTime, var: created_time}, {name: currency, var: currency}, {name: deadlineTime, var: deadline_time}, {name: postedTime, var: posted_time}, {name: reasonCode, var: reason_code}, {name: resolvedTime, var: resolved_time}, {name: status, var: status}, {name: transactionId, var: transaction_id}, {name: type, var: type}, {name: updatedTime, var: updated_time}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, acquirer_reference_number: $acquirer_reference_number, amount: $amount, case_id: $case_id, created_time: $created_time, currency: $currency, deadline_time: $deadline_time, posted_time: $posted_time, reason_code: $reason_code, resolved_time: $resolved_time, status: $status, transaction_id: $transaction_id, type: $type, updated_time: $updated_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of files
#
# GET /files
# Returns: table<_links: list<any>, createdTime: string, description: string, extension: string, height: int, id: string, isPublic: bool, mime: string, name: string, sha1: string, size: int, tags: list<string>, updatedTime: string, width: int>
# operationId: GetFileCollection
export def "get-file-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --fields: string # Limit the returned fields to the list specified, separated by comma. Note that id is always returned.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/files"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: q, var: q}, {name: expand, var: expand}, {name: fields, var: fields}, {name: sort, var: sort, style: csv}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, filter: $filter, q: $q, expand: $expand, fields: $fields, sort: $sort, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a file
#
# POST /files
# Returns: record<_links: list<any>, createdTime: string, description: string, extension: string, height: int, id: string, isPublic: bool, mime: string, name: string, sha1: string, size: int, tags: list<string>, updatedTime: string, width: int>
# operationId: PostFile
export def "post-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --description: string # The file description. (e.g. My file description)
  --file: string # The file in base64 encoded format. (e.g. R0lGODlhAQABAIAAAAUEBAAAACwAAAAAAQABAAACAkQBADs=)
  --is-public: oneof<nothing, bool> # The File visibility. If public a permalink is provided. (e.g. false)
  --name: string # The file name used for downloading. (e.g. logo.png)
  --tags: list<string> # The tags list. (e.g. [test, tags])
  --url: string # The URL of the file to upload. (e.g. https://blog.rebilly.com/wp-content/uploads/2017/09/rb_LogoInverted_Small.png)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: file, var: file}, {name: isPublic, var: is_public}, {name: name, var: name}, {name: tags, var: tags}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, description: $description, file: $file, is_public: $is_public, name: $name, tags: $tags, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a File
#
# DELETE /files/{id}
# operationId: DeleteFile
export def "delete-file" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/files/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a File Record
#
# GET /files/{id}
# Returns: record<_links: list<any>, createdTime: string, description: string, extension: string, height: int, id: string, isPublic: bool, mime: string, name: string, sha1: string, size: int, tags: list<string>, updatedTime: string, width: int>
# operationId: GetFile
export def "get-file" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the File with predefined ID
#
# PUT /files/{id}
# Returns: record<_links: list<any>, createdTime: string, description: string, extension: string, height: int, id: string, isPublic: bool, mime: string, name: string, sha1: string, size: int, tags: list<string>, updatedTime: string, width: int>
# operationId: PutFile
export def "put-file" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # The upload date/time. (format: date-time)
  --description: string # The File description.
  --extension: string # The File extension.
  --is-public: oneof<nothing, bool> # Is the file available publicly (without authentication). If true, the permalink in the _links section contains the public URL.
  --name: string # Original File name.
  --tags: list<string> # The tags list.
  --updated-time: string # The latest update date/time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/files/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: description, var: description}, {name: extension, var: extension}, {name: isPublic, var: is_public}, {name: name, var: name}, {name: tags, var: tags}, {name: updatedTime, var: updated_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, created_time: $created_time, description: $description, extension: $extension, is_public: $is_public, name: $name, tags: $tags, updated_time: $updated_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a file
#
# GET /files/{id}/download
# Returns: string
# operationId: GetFileDownload
export def "get-file-download" [
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
  --image-size: string # Resize image to specified size. Supports any sizes from 10x10 to 2000x2000 (format `{width}x{height}`). The image will be returned in the original size if the value is invalid. This parameter will be ignored for non-image files. (e.g. 700x700)
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: get
    path: "/files/{id}/download"
    path_params: [{name: id, var: id}]
    query: [{name: imageSize, var: image_size}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200, 302]
    auth: reb-apikey
  } {
    id: $id, image_size: $image_size, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download image in specific format
#
# GET /files/{id}/download{extension}
# Returns: string
# operationId: GetFileDownloadExtension
export def "get-file-download-extension" [
  id: string
  extension: string@extension-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: get
    path: "/files/{id}/download{extension}"
    path_params: [{name: id, var: id}, {name: extension, var: extension}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, extension: $extension, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of invoices
#
# GET /invoices
# Returns: table<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, discountAmount: float, discounts: list<record>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: list<record>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list, afterRetryEndPolicies: list, attempts: list>, revision: int, transactions: list<record>, type: string>
# operationId: GetInvoiceCollection
export def "get-invoice-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/invoices"
    query: [{name: filter, var: filter}, {name: sort, var: sort, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: q, var: q}, {name: expand, var: expand}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    filter: $filter, sort: $sort, limit: $limit, offset: $offset, q: $q, expand: $expand, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an invoice
#
# POST /invoices
# Returns: record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<"3ds": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>
# operationId: PostInvoice
export def "post-invoice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --abandoned-time: string # Invoice abandoned time. (format: date-time)
  --autopay-scheduled-time: string # Invoice autopay scheduled time. (format: date-time)
  --billing-address: record # Invoice's billing address. — shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  --created-time: string # Invoice created time. (format: date-time)
  currency: string # ISO 4217 alphabetic currency code.
  --delivery-address: record # Invoice's delivery address. — shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  --due-time: string # Invoice due time. (format: date-time)
  --issued-time: string # Invoice issued time. (format: date-time)
  --notes: string # Notes for the customer which will be displayed on the invoice.
  --paid-time: string # Invoice paid time. (format: date-time)
  --po-number: string # Purchase order number which will be displayed on the invoice. (nullable, e.g. PO123456)
  --shipping: record # Invoice shipping. — shape: {calculator: "manual"|"rebilly"}
  --tax: record # Invoice taxes. — shape: {amount?: int, calculator: "manual"|"rebilly"}
  --updated-time: string # Invoice updated time. (format: date-time)
  --voided-time: string # Invoice voided time. (format: date-time)
  website_id: string # The website ID.
  customer_id: string # The сustomer's ID.
  --due-reminder-time: string # Time past due reminder event will be triggered. (nullable, format: date-time)
  --retry-instruction: record # The invoice retry instruction. — shape: {afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invoices"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: abandonedTime, var: abandoned_time}, {name: autopayScheduledTime, var: autopay_scheduled_time}, {name: billingAddress, var: billing_address}, {name: createdTime, var: created_time}, {name: currency, var: currency}, {name: deliveryAddress, var: delivery_address}, {name: dueTime, var: due_time}, {name: issuedTime, var: issued_time}, {name: notes, var: notes}, {name: paidTime, var: paid_time}, {name: poNumber, var: po_number}, {name: shipping, var: shipping}, {name: tax, var: tax}, {name: updatedTime, var: updated_time}, {name: voidedTime, var: voided_time}, {name: websiteId, var: website_id}, {name: customerId, var: customer_id}, {name: dueReminderTime, var: due_reminder_time}, {name: retryInstruction, var: retry_instruction}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, abandoned_time: $abandoned_time, autopay_scheduled_time: $autopay_scheduled_time, billing_address: $billing_address, created_time: $created_time, currency: $currency, delivery_address: $delivery_address, due_time: $due_time, issued_time: $issued_time, notes: $notes, paid_time: $paid_time, po_number: $po_number, shipping: $shipping, tax: $tax, updated_time: $updated_time, voided_time: $voided_time, website_id: $website_id, customer_id: $customer_id, due_reminder_time: $due_reminder_time, retry_instruction: $retry_instruction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an invoice
#
# GET /invoices/{id}
# Returns: record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<"3ds": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>
# operationId: GetInvoice
export def "get-invoice" [
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
  --accept: string@accept-completer # Response content type
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --hdr-accept: string@accept-completer # The response media type. (default: application/json) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/invoices/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: expand, var: expand}]
    header: [{name: Organization-Id, var: organization_id}, {name: Accept, var: hdr_accept}]
    accept: ["application/json", "application/pdf"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, expand: $expand, organization_id: $organization_id, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create or update an invoice with predefined ID
#
# PUT /invoices/{id}
# Returns: record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<"3ds": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>
# operationId: PutInvoice
export def "put-invoice" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --abandoned-time: string # Invoice abandoned time. (format: date-time)
  --autopay-scheduled-time: string # Invoice autopay scheduled time. (format: date-time)
  --billing-address: record # Invoice's billing address. — shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  --created-time: string # Invoice created time. (format: date-time)
  currency: string # ISO 4217 alphabetic currency code.
  --delivery-address: record # Invoice's delivery address. — shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  --due-time: string # Invoice due time. (format: date-time)
  --issued-time: string # Invoice issued time. (format: date-time)
  --notes: string # Notes for the customer which will be displayed on the invoice.
  --paid-time: string # Invoice paid time. (format: date-time)
  --po-number: string # Purchase order number which will be displayed on the invoice. (nullable, e.g. PO123456)
  --shipping: record # Invoice shipping. — shape: {calculator: "manual"|"rebilly"}
  --tax: record # Invoice taxes. — shape: {amount?: int, calculator: "manual"|"rebilly"}
  --updated-time: string # Invoice updated time. (format: date-time)
  --voided-time: string # Invoice voided time. (format: date-time)
  website_id: string # The website ID.
  customer_id: string # The сustomer's ID.
  --due-reminder-time: string # Time past due reminder event will be triggered. (nullable, format: date-time)
  --retry-instruction: record # The invoice retry instruction. — shape: {afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/invoices/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: abandonedTime, var: abandoned_time}, {name: autopayScheduledTime, var: autopay_scheduled_time}, {name: billingAddress, var: billing_address}, {name: createdTime, var: created_time}, {name: currency, var: currency}, {name: deliveryAddress, var: delivery_address}, {name: dueTime, var: due_time}, {name: issuedTime, var: issued_time}, {name: notes, var: notes}, {name: paidTime, var: paid_time}, {name: poNumber, var: po_number}, {name: shipping, var: shipping}, {name: tax, var: tax}, {name: updatedTime, var: updated_time}, {name: voidedTime, var: voided_time}, {name: websiteId, var: website_id}, {name: customerId, var: customer_id}, {name: dueReminderTime, var: due_reminder_time}, {name: retryInstruction, var: retry_instruction}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, abandoned_time: $abandoned_time, autopay_scheduled_time: $autopay_scheduled_time, billing_address: $billing_address, created_time: $created_time, currency: $currency, delivery_address: $delivery_address, due_time: $due_time, issued_time: $issued_time, notes: $notes, paid_time: $paid_time, po_number: $po_number, shipping: $shipping, tax: $tax, updated_time: $updated_time, voided_time: $voided_time, website_id: $website_id, customer_id: $customer_id, due_reminder_time: $due_reminder_time, retry_instruction: $retry_instruction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Abandon an invoice
#
# POST /invoices/{id}/abandon
# Returns: record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<"3ds": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>
# operationId: PostInvoiceAbandonment
export def "post-invoice-abandonment" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/invoices/{id}/abandon"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Issue an invoice
#
# POST /invoices/{id}/issue
# Returns: record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<"3ds": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>
# operationId: PostInvoiceIssuance
export def "post-invoice-issuance" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --due-time: string # Invoice due time. Will be set same as `issuedTime` if `null` or omitted. (nullable, format: date-time)
  --issued-time: string # Invoice issued time. Will be issued immediately if `null` or omitted. (nullable, format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invoices/{id}/issue"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: dueTime, var: due_time}, {name: issuedTime, var: issued_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, due_time: $due_time, issued_time: $issued_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve invoice items
#
# GET /invoices/{id}/items
# Returns: table<_embedded: list<any>, _links: list<any>, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>
# operationId: GetInvoiceItemCollection
export def "get-invoice-item-collection" [
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
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/invoices/{id}/items"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: expand, var: expand}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, limit: $limit, offset: $offset, expand: $expand, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an invoice item
#
# POST /invoices/{id}/items
# Returns: record<_embedded: list<any>, _links: list<any>, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>
# operationId: PostInvoiceItem
export def "post-invoice-item" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # Invoice item created time. (format: date-time)
  --description: string # Invoice item's description.
  --period-end-time: string # End time. (format: date-time)
  --period-number: int # Invoice item subscription order period number.
  --period-start-time: string # Start time. (format: date-time)
  --product-id: string # The product's ID.
  --quantity: int # Invoice item's quantity.
  type: string@type-completer-5 # Invoice item's type.
  unit_price: float # Invoice item's price. (format: double)
  --updated-time: string # Invoice item updated time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invoices/{id}/items"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: description, var: description}, {name: periodEndTime, var: period_end_time}, {name: periodNumber, var: period_number}, {name: periodStartTime, var: period_start_time}, {name: productId, var: product_id}, {name: quantity, var: quantity}, {name: type, var: type}, {name: unitPrice, var: unit_price}, {name: updatedTime, var: updated_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, created_time: $created_time, description: $description, period_end_time: $period_end_time, period_number: $period_number, period_start_time: $period_start_time, product_id: $product_id, quantity: $quantity, type: $type, unit_price: $unit_price, updated_time: $updated_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recalculate an invoice
#
# POST /invoices/{id}/recalculate
# Returns: record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<"3ds": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>
# operationId: PostInvoiceRecalculation
export def "post-invoice-recalculation" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/invoices/{id}/recalculate"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reissue an invoice
#
# POST /invoices/{id}/reissue
# Returns: record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<"3ds": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>
# operationId: PostInvoiceReissuance
export def "post-invoice-reissuance" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --due-time: string # Invoice due time. Will be set as current date-time if `null` or omitted. (nullable, format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invoices/{id}/reissue"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: dueTime, var: due_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, due_time: $due_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of invoice timeline messages
#
# GET /invoices/{id}/timeline
# Returns: table<_links: list<record>, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>
# operationId: GetInvoiceTimelineCollection
export def "get-invoice-timeline-collection" [
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
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --q: string # The partial search of the text fields.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/invoices/{id}/timeline"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: sort, var: sort, style: csv}, {name: q, var: q}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, limit: $limit, offset: $offset, filter: $filter, sort: $sort, q: $q, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an invoice Timeline comment
#
# POST /invoices/{id}/timeline
# Returns: record<_links: table<rel: string, href: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>
# operationId: PostInvoiceTimeline
export def "post-invoice-timeline" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --message: string # The message that describes the message details.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invoices/{id}/timeline"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Invoice Timeline message
#
# DELETE /invoices/{id}/timeline/{messageId}
# operationId: DeleteInvoiceTimeline
export def "delete-invoice-timeline" [
  id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/invoices/{id}/timeline/{messageId}"
    path_params: [{name: id, var: id}, {name: messageId, var: message_id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    id: $id, message_id: $message_id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an Invoice Timeline message
#
# GET /invoices/{id}/timeline/{messageId}
# Returns: record<_links: table<rel: string, href: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>
# operationId: GetInvoiceTimeline
export def "get-invoice-timeline" [
  id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/invoices/{id}/timeline/{messageId}"
    path_params: [{name: id, var: id}, {name: messageId, var: message_id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, message_id: $message_id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Apply a transaction to an invoice
#
# POST /invoices/{id}/transaction
# Returns: record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<"3ds": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>
# operationId: PostInvoiceTransaction
export def "post-invoice-transaction" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --amount: float # Amount which needs to be applied to the invoice. Can't be more than the transaction's amount. If omitted, the lesser of the transaction's unused amount or the invoice's amount due will be used. (format: double)
  transaction_id: string # Transaction to be applied to the invoice.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invoices/{id}/transaction"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: transactionId, var: transaction_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, amount: $amount, transaction_id: $transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get transaction amounts allocated to an invoice
#
# GET /invoices/{id}/transaction-allocations
# Returns: table<_links: list<any>, amount: float, currency: string, invoiceId: string, transactionId: string>
# operationId: GetInvoiceTransactionAllocationCollection
export def "get-invoice-transaction-allocation-collection" [
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
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/invoices/{id}/transaction-allocations"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, limit: $limit, offset: $offset, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Void an invoice
#
# POST /invoices/{id}/void
# Returns: record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<"3ds": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>
# operationId: PostInvoiceVoid
export def "post-invoice-void" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/invoices/{id}/void"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of KYC documents
#
# GET /kyc-documents
# Returns: list<any>
# operationId: GetKycDocumentCollection
export def "get-kyc-document-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/kyc-documents"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: sort, var: sort, style: csv}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, filter: $filter, sort: $sort, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a KYC Document
#
# POST /kyc-documents
# Discriminator (request): documentType = address-proof, funds-proof, identity-proof, purchase-proof
# operationId: PostKycDocument
@deprecated --flag file-id
export def "post-kyc-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # Creation date/time. (format: date-time)
  --document-subtype: string@document-subtype-completer # Document subtype submitted for validation.
  document_type: string@document-type-completer # Document type submitted for validation, only identity-proof type is analyzed in an automated manner.
  --file-id: string # Linked file object id. (DEPRECATED)
  --file-ids: list<string> # Linked file object id's.
  --processed-time: string # Processing date/time. (format: date-time)
  --updated-time: string # Latest update date/time. (format: date-time)
  customer_id: string # The сustomer's ID.
  --match-level: int # The level of strictness for the document matches. (e.g. 2)
  --notes: string # Reviewer notes. (nullable)
  --reason: string # Reason for uploading.
  --review-time: string # Date and time of manual review. (nullable, format: date-time)
]: any -> any {
  $in | http-request {
    method: post
    path: "/kyc-documents"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: documentSubtype, var: document_subtype}, {name: documentType, var: document_type}, {name: fileId, var: file_id}, {name: fileIds, var: file_ids}, {name: processedTime, var: processed_time}, {name: updatedTime, var: updated_time}, {name: customerId, var: customer_id}, {name: matchLevel, var: match_level}, {name: notes, var: notes}, {name: reason, var: reason}, {name: reviewTime, var: review_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, created_time: $created_time, document_subtype: $document_subtype, document_type: $document_type, file_id: $file_id, file_ids: $file_ids, processed_time: $processed_time, updated_time: $updated_time, customer_id: $customer_id, match_level: $match_level, notes: $notes, reason: $reason, review_time: $review_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a KYC Document
#
# GET /kyc-documents/{id}
# Discriminator (response): documentType = address-proof, funds-proof, identity-proof, purchase-proof
# operationId: GetKycDocument
export def "get-kyc-document" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: get
    path: "/kyc-documents/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update a KYC document with predefined ID
#
# PUT /kyc-documents/{id}
# Discriminator (request): documentType = address-proof, funds-proof, identity-proof, purchase-proof
# operationId: PutKycDocument
@deprecated --flag file-id
export def "put-kyc-document" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # Creation date/time. (format: date-time)
  --document-subtype: string@document-subtype-completer # Document subtype submitted for validation.
  document_type: string@document-type-completer # Document type submitted for validation, only identity-proof type is analyzed in an automated manner.
  --file-id: string # Linked file object id. (DEPRECATED)
  --file-ids: list<string> # Linked file object id's.
  --processed-time: string # Processing date/time. (format: date-time)
  --updated-time: string # Latest update date/time. (format: date-time)
  customer_id: string # The сustomer's ID.
  --match-level: int # The level of strictness for the document matches. (e.g. 2)
  --notes: string # Reviewer notes. (nullable)
  --reason: string # Reason for uploading.
  --review-time: string # Date and time of manual review. (nullable, format: date-time)
]: any -> any {
  $in | http-request {
    method: put
    path: "/kyc-documents/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: documentSubtype, var: document_subtype}, {name: documentType, var: document_type}, {name: fileId, var: file_id}, {name: fileIds, var: file_ids}, {name: processedTime, var: processed_time}, {name: updatedTime, var: updated_time}, {name: customerId, var: customer_id}, {name: matchLevel, var: match_level}, {name: notes, var: notes}, {name: reason, var: reason}, {name: reviewTime, var: review_time}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, created_time: $created_time, document_subtype: $document_subtype, document_type: $document_type, file_id: $file_id, file_ids: $file_ids, processed_time: $processed_time, updated_time: $updated_time, customer_id: $customer_id, match_level: $match_level, notes: $notes, reason: $reason, review_time: $review_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accept a KYC document
#
# POST /kyc-documents/{id}/acceptance
# Discriminator (response): documentType = address-proof, funds-proof, identity-proof, purchase-proof
# operationId: PostKycDocumentAcceptance
export def "post-kyc-document-acceptance" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: post
    path: "/kyc-documents/{id}/acceptance"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a KYC document's documentMatches
#
# POST /kyc-documents/{id}/matches
# operationId: PostKycDocumentMatches
export def "post-kyc-document-matches" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --contains-image: oneof<nothing, bool> # Flag that indicates if there is an image that contains a face on it. (e.g. true)
  --date-of-birth: string # The date of birth found on the document, null if not found. (format: date-time)
  --expiry-date: string # The expiry date found on the document, null if not found. (format: date-time)
  --first-name: string # The customer first name if it was matched, null otherwise. (e.g. John)
  --is-identity-document: oneof<nothing, bool> # Flag that indicates if this looks like and ID. (e.g. true)
  --is-published-online: oneof<nothing, bool> # If there is an exact match found online. (e.g. false)
  --issue-date: string # The issued date found on the document, null if not found. (format: date-time)
  --last-name: string # The customer last name if it was matched, null otherwise. (e.g. Doe)
  --nationality: string # The nationality found on the document, null otherwise. (e.g. US)
  --city: string # The customer city if it was matched, null otherwise. (e.g. London)
  --date: string # The date on the document proving the document is recent. (format: date, e.g. 2021-01-01T00:00:00.000Z)
  --line1: string # The customer address if it was matched, null otherwise. (e.g. 36 Craven St)
  --phone: string # The phone of the company or agency that sent the document. (e.g. (123) 456-7890)
  --postal-code: string # The customer postal code if it was matched, null otherwise. (e.g. WC2N 5NF)
  --region: string # The customer region if it was matched, null otherwise. (e.g. London)
  --unique-words: int # The number of unique words in the document. (e.g. 175)
  --word-count: int # The number of words in the document. (e.g. 350)
]: any -> any {
  $in | http-request {
    method: post
    path: "/kyc-documents/{id}/matches"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: containsImage, var: contains_image}, {name: dateOfBirth, var: date_of_birth}, {name: expiryDate, var: expiry_date}, {name: firstName, var: first_name}, {name: isIdentityDocument, var: is_identity_document}, {name: isPublishedOnline, var: is_published_online}, {name: issueDate, var: issue_date}, {name: lastName, var: last_name}, {name: nationality, var: nationality}, {name: city, var: city}, {name: date, var: date}, {name: line1, var: line1}, {name: phone, var: phone}, {name: postalCode, var: postal_code}, {name: region, var: region}, {name: uniqueWords, var: unique_words}, {name: wordCount, var: word_count}]}
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, contains_image: $contains_image, date_of_birth: $date_of_birth, expiry_date: $expiry_date, first_name: $first_name, is_identity_document: $is_identity_document, is_published_online: $is_published_online, issue_date: $issue_date, last_name: $last_name, nationality: $nationality, city: $city, date: $date, line1: $line1, phone: $phone, postal_code: $postal_code, region: $region, unique_words: $unique_words, word_count: $word_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reject a KYC document
#
# POST /kyc-documents/{id}/rejection
# Discriminator (response): documentType = address-proof, funds-proof, identity-proof, purchase-proof
# operationId: PostKycDocumentRejection
export def "post-kyc-document-rejection" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --message: string # The rejection message. (e.g. Provided document is unreadable)
  --type: string@type-completer-6
]: any -> any {
  $in | http-request {
    method: post
    path: "/kyc-documents/{id}/rejection"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, message: $message, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Review a KYC document
#
# POST /kyc-documents/{id}/review
# Discriminator (response): documentType = address-proof, funds-proof, identity-proof, purchase-proof
# operationId: PostKycDocumentReview
export def "post-kyc-document-review" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: post
    path: "/kyc-documents/{id}/review"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of KYC requests
#
# GET /kyc-requests
# Returns: table<createdTime: string, documents: list<record>, expirationTime: string, id: string, redirectUrl: string, updatedTime: string, _links: list<any>, customerId: string, matchLevel: int, reason: string>
# operationId: GetKycRequestCollection
export def "get-kyc-request-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/kyc-requests"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: sort, var: sort, style: csv}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, filter: $filter, sort: $sort, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a KYC Request
#
# POST /kyc-requests
# Returns: record<createdTime: string, documents: table<maxAttempts: int, subtypes: list, type: string>, expirationTime: string, id: string, redirectUrl: string, updatedTime: string, _links: list<any>, customerId: string, matchLevel: int, reason: string>
# operationId: PostKycRequest
export def "post-kyc-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # Creation date/time. (format: date-time)
  documents: list # Documents to be requested from customer. — item shape: {maxAttempts?: int, subtypes?: list<string>, type: "identity-proof"|"address-proof"|"funds-proof"|"purchase-proof"}
  --expiration-time: string # Expiration date/time. (format: date-time)
  --redirect-url: string # The URL to redirect the customer when an upload is completed. (format: uri)
  --updated-time: string # Latest update date/time. (format: date-time)
  customer_id: string # The сustomer's ID.
  --match-level: int # The level of strictness for the document matches. (e.g. 2)
  --reason: string # Reason for uploading.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/kyc-requests"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: documents, var: documents}, {name: expirationTime, var: expiration_time}, {name: redirectUrl, var: redirect_url}, {name: updatedTime, var: updated_time}, {name: customerId, var: customer_id}, {name: matchLevel, var: match_level}, {name: reason, var: reason}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, created_time: $created_time, documents: $documents, expiration_time: $expiration_time, redirect_url: $redirect_url, updated_time: $updated_time, customer_id: $customer_id, match_level: $match_level, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the KYC request
#
# DELETE /kyc-requests/{id}
# operationId: DeleteKycRequest
export def "delete-kyc-request" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/kyc-requests/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a KYC request
#
# GET /kyc-requests/{id}
# Returns: record<createdTime: string, documents: table<maxAttempts: int, subtypes: list, type: string>, expirationTime: string, id: string, redirectUrl: string, updatedTime: string, _links: list<any>, customerId: string, matchLevel: int, reason: string>
# operationId: GetKycRequest
export def "get-kyc-request" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/kyc-requests/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a KYC request
#
# PATCH /kyc-requests/{id}
# Returns: record<createdTime: string, documents: table<maxAttempts: int, subtypes: list, type: string>, expirationTime: string, id: string, redirectUrl: string, updatedTime: string, _links: list<any>, customerId: string, matchLevel: int, reason: string>
# operationId: PatchKycRequest
export def "patch-kyc-request" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  customer_id: string # The сustomer's ID.
  --created-time: string # Creation date/time. (format: date-time)
  documents: list # Documents to be requested from customer. — item shape: {maxAttempts?: int, subtypes?: list<string>, type: "identity-proof"|"address-proof"|"funds-proof"|"purchase-proof"}
  --expiration-time: string # Expiration date/time. (format: date-time)
  --redirect-url: string # The URL to redirect the customer when an upload is completed. (format: uri)
  --updated-time: string # Latest update date/time. (format: date-time)
  --match-level: int # The level of strictness for the document matches. (e.g. 2)
  --reason: string # Reason for uploading.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/kyc-requests/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customerId, var: customer_id}, {name: createdTime, var: created_time}, {name: documents, var: documents}, {name: expirationTime, var: expiration_time}, {name: redirectUrl, var: redirect_url}, {name: updatedTime, var: updated_time}, {name: matchLevel, var: match_level}, {name: reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, customer_id: $customer_id, created_time: $created_time, documents: $documents, expiration_time: $expiration_time, redirect_url: $redirect_url, updated_time: $updated_time, match_level: $match_level, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of tokens
#
# GET /password-tokens
# Returns: table<_links: list<record>, credentialId: string, expiredTime: string, token: string, username: string>
# operationId: GetPasswordTokenCollection
export def "get-password-token-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/password-tokens"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Reset Password Token
#
# POST /password-tokens
# Returns: record<_links: table<rel: string, href: string>, credentialId: string, expiredTime: string, token: string, username: string>
# operationId: PostPasswordToken
export def "post-password-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --expired-time: string # Password expired time. (format: date-time)
  username: string # The token's username.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/password-tokens"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: expiredTime, var: expired_time}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, expired_time: $expired_time, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Reset Password Token
#
# DELETE /password-tokens/{id}
# operationId: DeletePasswordToken
export def "delete-password-token" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/password-tokens/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Reset Password Token
#
# GET /password-tokens/{id}
# Returns: record<_links: table<rel: string, href: string>, credentialId: string, expiredTime: string, token: string, username: string>
# operationId: GetPasswordToken
export def "get-password-token" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/password-tokens/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of Payment Cards
#
# GET /payment-cards
# Returns: table<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, bin: string, brand: string, createdTime: string, customFields: record, customerId: string, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: string, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: string, stickyGatewayAccountId: string>
# operationId: GetPaymentCardCollection
export def "get-payment-card-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/payment-cards"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: sort, var: sort, style: csv}, {name: q, var: q}, {name: expand, var: expand}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, filter: $filter, sort: $sort, q: $q, expand: $expand, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Payment Card
#
# POST /payment-cards
# Returns: record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: string, createdTime: string, customFields: record, customerId: string, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: string, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: string, stickyGatewayAccountId: string>
# operationId: PostPaymentCard
export def "post-payment-card" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  customer_id: string # The Customer's ID.
  --body-token: string # PaymentCardToken ID. (spec name: token)
  --billing-address: record # The billing address. — shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  --cvv: string # Card's cvv (card verification value).
  --exp-month: int # Card's expiration month.
  --exp-year: int # Card's expiration year.
  --method: string@method-completer # The method of payment instrument.
  --pan: string # The card PAN (Primary Account Number).
  --risk-metadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/payment-cards"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: token, var: body_token}, {name: billingAddress, var: billing_address}, {name: cvv, var: cvv}, {name: expMonth, var: exp_month}, {name: expYear, var: exp_year}, {name: method, var: method}, {name: pan, var: pan}, {name: riskMetadata, var: risk_metadata}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, custom_fields: $custom_fields, customer_id: $customer_id, body_token: $body_token, billing_address: $billing_address, cvv: $cvv, exp_month: $exp_month, exp_year: $exp_year, method: $method, pan: $pan, risk_metadata: $risk_metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Payment Card
#
# GET /payment-cards/{id}
# Returns: record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: string, createdTime: string, customFields: record, customerId: string, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: string, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: string, stickyGatewayAccountId: string>
# operationId: GetPaymentCard
export def "get-payment-card" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/payment-cards/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a payment card's values
#
# PATCH /payment-cards/{id}
# Returns: record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: string, createdTime: string, customFields: record, customerId: string, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: string, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: string, stickyGatewayAccountId: string>
# operationId: PatchPaymentCard
export def "patch-payment-card" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --billing-address: record # The billing address. — shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --cvv: string # Card's cvv (card verification value).
  --exp-month: int # Card's expiration month.
  --exp-year: int # Card's expiration year.
  --sticky-gateway-account-id: string # Sticky gateway account ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/payment-cards/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingAddress, var: billing_address}, {name: customFields, var: custom_fields}, {name: cvv, var: cvv}, {name: expMonth, var: exp_month}, {name: expYear, var: exp_year}, {name: stickyGatewayAccountId, var: sticky_gateway_account_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, billing_address: $billing_address, custom_fields: $custom_fields, cvv: $cvv, exp_month: $exp_month, exp_year: $exp_year, sticky_gateway_account_id: $sticky_gateway_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a payment card with predefined ID
#
# PUT /payment-cards/{id}
# Returns: record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: string, createdTime: string, customFields: record, customerId: string, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: string, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: string, stickyGatewayAccountId: string>
# operationId: PutPaymentCard
export def "put-payment-card" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  customer_id: string # The Customer's ID.
  --body-token: string # PaymentCardToken ID. (spec name: token)
  --billing-address: record # The billing address. — shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  --cvv: string # Card's cvv (card verification value).
  --exp-month: int # Card's expiration month.
  --exp-year: int # Card's expiration year.
  --method: string@method-completer # The method of payment instrument.
  --pan: string # The card PAN (Primary Account Number).
  --risk-metadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/payment-cards/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: token, var: body_token}, {name: billingAddress, var: billing_address}, {name: cvv, var: cvv}, {name: expMonth, var: exp_month}, {name: expYear, var: exp_year}, {name: method, var: method}, {name: pan, var: pan}, {name: riskMetadata, var: risk_metadata}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, custom_fields: $custom_fields, customer_id: $customer_id, body_token: $body_token, billing_address: $billing_address, cvv: $cvv, exp_month: $exp_month, exp_year: $exp_year, method: $method, pan: $pan, risk_metadata: $risk_metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate a Payment Card
#
# POST /payment-cards/{id}/deactivation
# Returns: record<bankCountry: string, bankName: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, bin: string, brand: string, createdTime: string, customFields: record, customerId: string, cvv: string, expMonth: int, expYear: int, fingerprint: string, id: string, last4: string, method: string, pan: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, _embedded: list<any>, _links: list<any>, expirationReminderNumber: int, expirationReminderTime: string, stickyGatewayAccountId: string>
# operationId: PostPaymentCardDeactivation
export def "post-payment-card-deactivation" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/payment-cards/{id}/deactivation"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of payment instruments
#
# GET /payment-instruments
# Returns: list<any>
# operationId: GetPaymentInstrumentCollection
export def "get-payment-instrument-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/payment-instruments"
    query: [{name: filter, var: filter}, {name: sort, var: sort, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: q, var: q}, {name: expand, var: expand}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    filter: $filter, sort: $sort, limit: $limit, offset: $offset, q: $q, expand: $expand, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Payment Instrument
#
# POST /payment-instruments
# operationId: PostPaymentInstrument
export def "post-payment-instrument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --customer-id: string # The customer's ID.
  --body-token: string # Payment token ID. (spec name: token)
  --billing-address: record # The billing address. — shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  --cvv: string # Card's cvv (card verification value).
  --exp-month: int # Card's expiration month.
  --exp-year: int # Card's expiration year.
  --method: string@method-completer # The method of payment instrument.
  --pan: string # The card PAN (Primary Account Number).
  --risk-metadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
  --created-time: string # PayPal account created time. (format: date-time)
  --updated-time: string # PayPal account updated time. (format: date-time)
]: any -> any {
  $in | http-request {
    method: post
    path: "/payment-instruments"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: token, var: body_token}, {name: billingAddress, var: billing_address}, {name: cvv, var: cvv}, {name: expMonth, var: exp_month}, {name: expYear, var: exp_year}, {name: method, var: method}, {name: pan, var: pan}, {name: riskMetadata, var: risk_metadata}, {name: createdTime, var: created_time}, {name: updatedTime, var: updated_time}]}
    accept: ["application/json"]
    ok: [201, 303]
    auth: reb-apikey
  } {
    organization_id: $organization_id, custom_fields: $custom_fields, customer_id: $customer_id, body_token: $body_token, billing_address: $billing_address, cvv: $cvv, exp_month: $exp_month, exp_year: $exp_year, method: $method, pan: $pan, risk_metadata: $risk_metadata, created_time: $created_time, updated_time: $updated_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Payment Instrument
#
# GET /payment-instruments/{id}
# operationId: GetPaymentInstrument
export def "get-payment-instrument" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: get
    path: "/payment-instruments/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Payment Instrument's values
#
# PATCH /payment-instruments/{id}
# operationId: PatchPaymentInstrument
export def "patch-payment-instrument" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --billing-address: record # The billing address (if supplied – overrides billing address from token). — shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --body-token: string # Payment token ID. (spec name: token)
  --cvv: string # Card's cvv (card verification value).
  --exp-month: int # Card's expiration month.
  --exp-year: int # Card's expiration year.
  --sticky-gateway-account-id: string # Sticky gateway account ID.
  --account-type: string@account-type-completer # Bank's account type.
  --bank-name: string # Bank's name.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/payment-instruments/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingAddress, var: billing_address}, {name: customFields, var: custom_fields}, {name: token, var: body_token}, {name: cvv, var: cvv}, {name: expMonth, var: exp_month}, {name: expYear, var: exp_year}, {name: stickyGatewayAccountId, var: sticky_gateway_account_id}, {name: accountType, var: account_type}, {name: bankName, var: bank_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, billing_address: $billing_address, custom_fields: $custom_fields, body_token: $body_token, cvv: $cvv, exp_month: $exp_month, exp_year: $exp_year, sticky_gateway_account_id: $sticky_gateway_account_id, account_type: $account_type, bank_name: $bank_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate a payment instrument
#
# POST /payment-instruments/{id}/deactivation
# operationId: PostPaymentInstrumentDeactivation
export def "post-payment-instrument-deactivation" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: post
    path: "/payment-instruments/{id}/deactivation"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a credit transaction
#
# POST /payouts
# Returns: record<"3ds": record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list<string>, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, acquirerName: string, arn: string, bin: string, bumpOffer: record<language: string, order: record<amount: float, currency: string>, outcome: string, presentedOffers: list<record>, selectedOffer: record<bumpAmount: float, bumpAmountInUsd: float, customFields: record, offerId: string, offerType: string>, version: string>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: float>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>
# operationId: PostPayout
@deprecated --flag payment-instrument
export def "post-payout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  amount: float # The transaction amount. (format: double, e.g. 97.97)
  --billing-address: record # Billing address. If not supplied, we use the billing address associated with the payment instrument, and then customer. (nullable) — shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  currency: string # ISO 4217 alphabetic currency code.
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  customer_id: string # The customer identifier string.
  --description: string # The payment description. (nullable)
  --gateway-account-id: string # Rebilly will select the appropriate payment gateway account for the transaction based on the properties of the transaction and the `gateway-account-requested` event rules configurations. If you wish to prevent Rebilly from making the gateway account selection, you may supply a gateway account id here, and it will be used instead. Only use this field if you intend to override the settings. (nullable)
  --invoice-ids: list<string> # The array of invoice identifiers. (nullable)
  --is-merchant-initiated: oneof<nothing, bool> # True if the transaction was initiated by the merchant. (default: false)
  --is-processed-outside: oneof<nothing, bool> # True if transaction was processed outside Rebilly. (default: false)
  --notification-url: string # The URL where a server-to-server notification request type `POST` with a transaction payload will be sent when the transaction's result is finalized. Do not trust the notification; follow with a `GET` request to confirm the result of the transaction. Please respond with a `2xx` HTTP status code, or we will reattempt the request again. You may use `{id}` or `{result}` as placeholders in the URL and we will replace them with the transaction's id and result accordingly. (nullable, format: uri)
  --payment-instruction: any # Payment instruction. If not supplied, customer's default payment instrument will be used.
  --payment-instrument: record # DEPRECATED
  --processed-time: string # The time the transaction was processed. Can be specified only if transaction was processed outside Rebilly. (format: date-time)
  --redirect-url: string # The URL to redirect the end-user when an offsite transaction is completed. Defaults to the website's configured URL. You may use `{id}` or `{result}` as placeholders in the URL and we will replace them with the transaction's id and result accordingly. (nullable, format: uri)
  --request-id: string # The request id is **recommended**. It prevents duplicate transaction requests within a short period of time. If a duplicate request is sent with the same `requestId` it will be ignored to prevent double-billing anyone. It must be unique within a 24-hour period. We recommend generating a UUID v4 as its value. (nullable, e.g. 44433322-2c4y-483z-a0a9-158621f77a21)
  --risk-metadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
  website_id: string # The website identifier string.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/payouts"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: billingAddress, var: billing_address}, {name: currency, var: currency}, {name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: description, var: description}, {name: gatewayAccountId, var: gateway_account_id}, {name: invoiceIds, var: invoice_ids}, {name: isMerchantInitiated, var: is_merchant_initiated}, {name: isProcessedOutside, var: is_processed_outside}, {name: notificationUrl, var: notification_url}, {name: paymentInstruction, var: payment_instruction}, {name: paymentInstrument, var: payment_instrument}, {name: processedTime, var: processed_time}, {name: redirectUrl, var: redirect_url}, {name: requestId, var: request_id}, {name: riskMetadata, var: risk_metadata}, {name: websiteId, var: website_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, amount: $amount, billing_address: $billing_address, currency: $currency, custom_fields: $custom_fields, customer_id: $customer_id, description: $description, gateway_account_id: $gateway_account_id, invoice_ids: $invoice_ids, is_merchant_initiated: $is_merchant_initiated, is_processed_outside: $is_processed_outside, notification_url: $notification_url, payment_instruction: $payment_instruction, payment_instrument: $payment_instrument, processed_time: $processed_time, redirect_url: $redirect_url, request_id: $request_id, risk_metadata: $risk_metadata, website_id: $website_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of PayPal accounts
#
# GET /paypal-accounts
# Returns: table<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, id: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, username: string, _embedded: list<any>, _links: list<any>>
# operationId: GetPayPalAccountCollection
export def "get-pay-pal-account-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/paypal-accounts"
    query: [{name: filter, var: filter}, {name: sort, var: sort, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: q, var: q}, {name: expand, var: expand}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    filter: $filter, sort: $sort, limit: $limit, offset: $offset, q: $q, expand: $expand, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a PayPal Account
#
# POST /paypal-accounts
# Returns: record<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, id: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, username: string, _embedded: list<any>, _links: list<any>>
# operationId: PostPayPalAccount
export def "post-pay-pal-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  billing_address: record # The billing address. — shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  --created-time: string # PayPal account created time. (format: date-time)
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  customer_id: string # The customer's ID.
  method: string@method-completer-1 # The method of payment instrument.
  --risk-metadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
  --updated-time: string # PayPal account updated time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/paypal-accounts"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingAddress, var: billing_address}, {name: createdTime, var: created_time}, {name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: method, var: method}, {name: riskMetadata, var: risk_metadata}, {name: updatedTime, var: updated_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, billing_address: $billing_address, created_time: $created_time, custom_fields: $custom_fields, customer_id: $customer_id, method: $method, risk_metadata: $risk_metadata, updated_time: $updated_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a PayPal Account
#
# GET /paypal-accounts/{id}
# Returns: record<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, id: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, username: string, _embedded: list<any>, _links: list<any>>
# operationId: GetPayPalAccount
export def "get-pay-pal-account" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/paypal-accounts/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a PayPal account with predefined ID
#
# PUT /paypal-accounts/{id}
# Returns: record<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, id: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, username: string, _embedded: list<any>, _links: list<any>>
# operationId: PutPayPalAccount
export def "put-pay-pal-account" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  billing_address: record # The billing address. — shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  --created-time: string # PayPal account created time. (format: date-time)
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  customer_id: string # The customer's ID.
  method: string@method-completer-1 # The method of payment instrument.
  --risk-metadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
  --updated-time: string # PayPal account updated time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/paypal-accounts/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingAddress, var: billing_address}, {name: createdTime, var: created_time}, {name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: method, var: method}, {name: riskMetadata, var: risk_metadata}, {name: updatedTime, var: updated_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, billing_address: $billing_address, created_time: $created_time, custom_fields: $custom_fields, customer_id: $customer_id, method: $method, risk_metadata: $risk_metadata, updated_time: $updated_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate a PayPal Account
#
# POST /paypal-accounts/{id}/deactivation
# Returns: record<billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, createdTime: string, customFields: record, customerId: string, id: string, method: string, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, status: string, updatedTime: string, username: string, _embedded: list<any>, _links: list<any>>
# operationId: PostPayPalAccountDeactivation
export def "post-pay-pal-account-deactivation" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/paypal-accounts/{id}/deactivation"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of plans
#
# GET /plans
# Returns: table<createdTime: string, currency: string, currencySign: string, customFields: record, id: string, isTrialOnly: bool, name: string, pricing: record<formula: string>, productId: string, productOptions: record, recurringInterval: record<length: int, unit: string, billingTiming: string, limit: int>, revision: int, setup: record<price: float>, trial: record<period: record, price: float>, updatedTime: string, _links: list<record>, invoiceTimeShift: record<dueTimeShift: record, issueTimeShift: record>>
# operationId: GetPlanCollection
export def "get-plan-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The partial search of the text fields.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/plans"
    query: [{name: filter, var: filter}, {name: sort, var: sort, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: q, var: q}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    filter: $filter, sort: $sort, limit: $limit, offset: $offset, q: $q, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a plan
#
# POST /plans
# Returns: record<createdTime: string, currency: string, currencySign: string, customFields: record, id: string, isTrialOnly: bool, name: string, pricing: record<formula: string>, productId: string, productOptions: record, recurringInterval: record<length: int, unit: string, billingTiming: string, limit: int>, revision: int, setup: record<price: float>, trial: record<period: record<length: int, unit: string>, price: float>, updatedTime: string, _links: table<rel: string, href: string>, invoiceTimeShift: record<dueTimeShift: record<duration: int, unit: any>, issueTimeShift: record<chronology: string, duration: int, unit: any>>>
# operationId: PostPlan
export def "post-plan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # Plan created time. (format: date-time)
  currency: string # ISO 4217 alphabetic currency code.
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  name: string # The plan name, displayed on invoices and receipts.
  pricing: record # shape: {formula: "fixed-fee"|"flat-rate"|"stairstep"|"tiered"|"volume"}
  product_id: string # The related product ID.
  --product-options: record # Name-value pairs to specify the product options. (e.g. {color: red, size: xxl})
  --recurring-interval: record # The service interval. For a one-time item, use `null`. — shape: {length: int, unit: "day"|"week"|"month"|"year", billingTiming?: "prepaid"|"postpaid", limit?: int}
  --setup: record # The setup. Set `null` if no setup. — shape: {price: float}
  --trial: record # The trial. Set `null` if no trial. — shape: {period: record, price: float}
  --updated-time: string # Plan updated time. (format: date-time)
  --invoice-time-shift: record # You can shift issue time and due time of invoices for this plan. — shape: {dueTimeShift?: record, issueTimeShift?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/plans"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: currency, var: currency}, {name: customFields, var: custom_fields}, {name: name, var: name}, {name: pricing, var: pricing}, {name: productId, var: product_id}, {name: productOptions, var: product_options}, {name: recurringInterval, var: recurring_interval}, {name: setup, var: setup}, {name: trial, var: trial}, {name: updatedTime, var: updated_time}, {name: invoiceTimeShift, var: invoice_time_shift}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, created_time: $created_time, currency: $currency, custom_fields: $custom_fields, name: $name, pricing: $pricing, product_id: $product_id, product_options: $product_options, recurring_interval: $recurring_interval, setup: $setup, trial: $trial, updated_time: $updated_time, invoice_time_shift: $invoice_time_shift
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Plan
#
# DELETE /plans/{id}
# operationId: DeletePlan
export def "delete-plan" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/plans/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a plan
#
# GET /plans/{id}
# Returns: record<createdTime: string, currency: string, currencySign: string, customFields: record, id: string, isTrialOnly: bool, name: string, pricing: record<formula: string>, productId: string, productOptions: record, recurringInterval: record<length: int, unit: string, billingTiming: string, limit: int>, revision: int, setup: record<price: float>, trial: record<period: record<length: int, unit: string>, price: float>, updatedTime: string, _links: table<rel: string, href: string>, invoiceTimeShift: record<dueTimeShift: record<duration: int, unit: any>, issueTimeShift: record<chronology: string, duration: int, unit: any>>>
# operationId: GetPlan
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/plans/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update a Plan with predefined ID
#
# PUT /plans/{id}
# Returns: record<createdTime: string, currency: string, currencySign: string, customFields: record, id: string, isTrialOnly: bool, name: string, pricing: record<formula: string>, productId: string, productOptions: record, recurringInterval: record<length: int, unit: string, billingTiming: string, limit: int>, revision: int, setup: record<price: float>, trial: record<period: record<length: int, unit: string>, price: float>, updatedTime: string, _links: table<rel: string, href: string>, invoiceTimeShift: record<dueTimeShift: record<duration: int, unit: any>, issueTimeShift: record<chronology: string, duration: int, unit: any>>>
# operationId: PutPlan
export def "put-plan" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # Plan created time. (format: date-time)
  currency: string # ISO 4217 alphabetic currency code.
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  name: string # The plan name, displayed on invoices and receipts.
  pricing: record # shape: {formula: "fixed-fee"|"flat-rate"|"stairstep"|"tiered"|"volume"}
  product_id: string # The related product ID.
  --product-options: record # Name-value pairs to specify the product options. (e.g. {color: red, size: xxl})
  --recurring-interval: record # The service interval. For a one-time item, use `null`. — shape: {length: int, unit: "day"|"week"|"month"|"year", billingTiming?: "prepaid"|"postpaid", limit?: int}
  --setup: record # The setup. Set `null` if no setup. — shape: {price: float}
  --trial: record # The trial. Set `null` if no trial. — shape: {period: record, price: float}
  --updated-time: string # Plan updated time. (format: date-time)
  --invoice-time-shift: record # You can shift issue time and due time of invoices for this plan. — shape: {dueTimeShift?: record, issueTimeShift?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/plans/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: currency, var: currency}, {name: customFields, var: custom_fields}, {name: name, var: name}, {name: pricing, var: pricing}, {name: productId, var: product_id}, {name: productOptions, var: product_options}, {name: recurringInterval, var: recurring_interval}, {name: setup, var: setup}, {name: trial, var: trial}, {name: updatedTime, var: updated_time}, {name: invoiceTimeShift, var: invoice_time_shift}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, created_time: $created_time, currency: $currency, custom_fields: $custom_fields, name: $name, pricing: $pricing, product_id: $product_id, product_options: $product_options, recurring_interval: $recurring_interval, setup: $setup, trial: $trial, updated_time: $updated_time, invoice_time_shift: $invoice_time_shift
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of products
#
# GET /products
# Returns: table<createdTime: string, customFields: record, description: string, id: string, name: string, options: list<string>, requiresShipping: bool, unitLabel: string, updatedTime: string, _links: list<record>, accountingCode: string, taxCategoryId: string>
# operationId: GetProductCollection
export def "get-product-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The partial search of the text fields.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/products"
    query: [{name: filter, var: filter}, {name: sort, var: sort, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: q, var: q}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    filter: $filter, sort: $sort, limit: $limit, offset: $offset, q: $q, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Product
#
# POST /products
# Returns: record<createdTime: string, customFields: record, description: string, id: string, name: string, options: list<string>, requiresShipping: bool, unitLabel: string, updatedTime: string, _links: table<rel: string, href: string>, accountingCode: string, taxCategoryId: string>
# operationId: PostProduct
export def "post-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # The product created time. (format: date-time)
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --description: string # The product description.
  name: string # The product name. (e.g. Premium membership)
  --options: list<string> # The product options such as color, size, etc. The product options definition does not include option values. Those are defined within the plans.
  --requires-shipping: oneof<nothing, bool> # If the product requires shipping, shipping calculations will be applied. (e.g. false)
  --unit-label: string # The unit label, such as per `seat` or per `unit`. (default: unit, e.g. seat)
  --updated-time: string # The product updated time. (format: date-time)
  --accounting-code: string # The product accounting code. (e.g. 4010)
  --tax-category-id: string@tax-category-id-completer # The product's tax category identifier string.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/products"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: customFields, var: custom_fields}, {name: description, var: description}, {name: name, var: name}, {name: options, var: options}, {name: requiresShipping, var: requires_shipping}, {name: unitLabel, var: unit_label}, {name: updatedTime, var: updated_time}, {name: accountingCode, var: accounting_code}, {name: taxCategoryId, var: tax_category_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, created_time: $created_time, custom_fields: $custom_fields, description: $description, name: $name, options: $options, requires_shipping: $requires_shipping, unit_label: $unit_label, updated_time: $updated_time, accounting_code: $accounting_code, tax_category_id: $tax_category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a product
#
# DELETE /products/{id}
# operationId: DeleteProduct
export def "delete-product" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/products/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a product
#
# GET /products/{id}
# Returns: record<createdTime: string, customFields: record, description: string, id: string, name: string, options: list<string>, requiresShipping: bool, unitLabel: string, updatedTime: string, _links: table<rel: string, href: string>, accountingCode: string, taxCategoryId: string>
# operationId: GetProduct
export def "get-product" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a product with predefined ID
#
# PUT /products/{id}
# Returns: record<createdTime: string, customFields: record, description: string, id: string, name: string, options: list<string>, requiresShipping: bool, unitLabel: string, updatedTime: string, _links: table<rel: string, href: string>, accountingCode: string, taxCategoryId: string>
# operationId: PutProduct
export def "put-product" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # The product created time. (format: date-time)
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  --description: string # The product description.
  name: string # The product name. (e.g. Premium membership)
  --options: list<string> # The product options such as color, size, etc. The product options definition does not include option values. Those are defined within the plans.
  --requires-shipping: oneof<nothing, bool> # If the product requires shipping, shipping calculations will be applied. (e.g. false)
  --unit-label: string # The unit label, such as per `seat` or per `unit`. (default: unit, e.g. seat)
  --updated-time: string # The product updated time. (format: date-time)
  --accounting-code: string # The product accounting code. (e.g. 4010)
  --tax-category-id: string@tax-category-id-completer # The product's tax category identifier string.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/products/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: customFields, var: custom_fields}, {name: description, var: description}, {name: name, var: name}, {name: options, var: options}, {name: requiresShipping, var: requires_shipping}, {name: unitLabel, var: unit_label}, {name: updatedTime, var: updated_time}, {name: accountingCode, var: accounting_code}, {name: taxCategoryId, var: tax_category_id}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, created_time: $created_time, custom_fields: $custom_fields, description: $description, name: $name, options: $options, requires_shipping: $requires_shipping, unit_label: $unit_label, updated_time: $updated_time, accounting_code: $accounting_code, tax_category_id: $tax_category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ready to Pay
#
# POST /ready-to-pay
# Returns: list<any>
# operationId: PostReadyToPay
export def "post-ready-to-pay" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --customer-id: string # The customer identifier string.
  --billing-address: record # The billing address. — shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  risk_metadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
  website_id: string # The website identifier string.
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ready-to-pay"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customerId, var: customer_id}, {name: billingAddress, var: billing_address}, {name: riskMetadata, var: risk_metadata}, {name: websiteId, var: website_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    organization_id: $organization_id, customer_id: $customer_id, billing_address: $billing_address, risk_metadata: $risk_metadata, website_id: $website_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search merchant data
#
# GET /search
# Returns: table<customers: list<record>, invoices: list<record>, orders: list<record>, searched: list<string>, transactions: list<record>>
# operationId: GetSearch
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
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The default search. It will search across resources and many fields.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/search"
    query: [{name: sort, var: sort, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: q, var: q}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    sort: $sort, limit: $limit, offset: $offset, q: $q, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of shipping zones
#
# GET /shipping-zones
# Returns: table<_links: list<record>, countries: list<string>, createdTime: string, id: string, isDefault: any, name: string, rates: list<record>, updatedTime: string>
# operationId: GetShippingZoneCollection
export def "get-shipping-zone-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --q: string # The partial search of the text fields.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/shipping-zones"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: sort, var: sort, style: csv}, {name: q, var: q}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, filter: $filter, sort: $sort, q: $q, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Shipping Zone
#
# POST /shipping-zones
# Returns: record<_links: table<rel: string, href: string>, countries: list<string>, createdTime: string, id: string, isDefault: any, name: string, rates: table<_links: list, currency: string, maxOrderSubtotal: float, minOrderSubtotal: float, name: string, price: float>, updatedTime: string>
# operationId: PostShippingZone
export def "post-shipping-zone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --countries: list<string> # Countries covered by the shipping zone. A country can only belong to one shipping zone (no overlapping). This property can be empty or null to create a default shipping zone for countries that were not specified in other zones.
  --created-time: string # The shipping zone created time. (format: date-time)
  name: string # The shipping zone name.
  --rates: list # Price-based shipping rate instructions. — item shape: {currency: string, maxOrderSubtotal?: float, minOrderSubtotal?: float, name: string, price: float}
  --updated-time: string # The shipping zone updated time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shipping-zones"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: countries, var: countries}, {name: createdTime, var: created_time}, {name: name, var: name}, {name: rates, var: rates}, {name: updatedTime, var: updated_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, countries: $countries, created_time: $created_time, name: $name, rates: $rates, updated_time: $updated_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a shipping zone
#
# DELETE /shipping-zones/{id}
# operationId: DeleteShippingZone
export def "delete-shipping-zone" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/shipping-zones/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a shipping zone
#
# GET /shipping-zones/{id}
# Returns: record<_links: table<rel: string, href: string>, countries: list<string>, createdTime: string, id: string, isDefault: any, name: string, rates: table<_links: list, currency: string, maxOrderSubtotal: float, minOrderSubtotal: float, name: string, price: float>, updatedTime: string>
# operationId: GetShippingZone
export def "get-shipping-zone" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shipping-zones/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a shipping zone with predefined ID
#
# PUT /shipping-zones/{id}
# Returns: record<_links: table<rel: string, href: string>, countries: list<string>, createdTime: string, id: string, isDefault: any, name: string, rates: table<_links: list, currency: string, maxOrderSubtotal: float, minOrderSubtotal: float, name: string, price: float>, updatedTime: string>
# operationId: PutShippingZone
export def "put-shipping-zone" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --countries: list<string> # Countries covered by the shipping zone. A country can only belong to one shipping zone (no overlapping). This property can be empty or null to create a default shipping zone for countries that were not specified in other zones.
  --created-time: string # The shipping zone created time. (format: date-time)
  name: string # The shipping zone name.
  --rates: list # Price-based shipping rate instructions. — item shape: {currency: string, maxOrderSubtotal?: float, minOrderSubtotal?: float, name: string, price: float}
  --updated-time: string # The shipping zone updated time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/shipping-zones/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: countries, var: countries}, {name: createdTime, var: created_time}, {name: name, var: name}, {name: rates, var: rates}, {name: updatedTime, var: updated_time}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, countries: $countries, created_time: $created_time, name: $name, rates: $rates, updated_time: $updated_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of cancellations
#
# GET /subscription-cancellations
# Returns: table<_links: list<record>, appliedInvoiceId: string, canceledBy: string, canceledTime: string, churnTime: string, createdTime: string, description: string, id: string, lineItemSubtotal: float, lineItems: list<record>, prorated: bool, proratedInvoiceId: string, reason: string, status: string, subscriptionId: string>
# operationId: GetSubscriptionCancellationCollection
export def "get-subscription-cancellation-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscription-cancellations"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: sort, var: sort, style: csv}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, filter: $filter, sort: $sort, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel an order
#
# POST /subscription-cancellations
# Returns: record<_links: table<rel: string, href: string>, appliedInvoiceId: string, canceledBy: string, canceledTime: string, churnTime: string, createdTime: string, description: string, id: string, lineItemSubtotal: float, lineItems: table<createdTime: string, description: string, periodEndTime: string, periodStartTime: string, quantity: int, type: string, unitPriceAmount: float, unitPriceCurrency: string>, prorated: bool, proratedInvoiceId: string, reason: string, status: string, subscriptionId: string>
# operationId: PostSubscriptionCancellation
export def "post-subscription-cancellation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --canceled-by: string@canceled-by-completer # Who did the cancellation. (default: customer)
  churn_time: string # The time when the subscription will be deactivated. (format: date-time)
  --created-time: string # The time of resource creation (when it is posted). (format: date-time)
  --description: string # Cancel reason description in free form.
  --line-items: list # Items to be added to the new invoice. Proration item is generated and added automatically. — item shape: {createdTime?: string, description?: string, periodEndTime?: string, periodStartTime?: string, quantity: int, type: "debit"|"credit", unitPriceAmount: float, unitPriceCurrency: string}
  --prorated: oneof<nothing, bool> # Defines if the customer gets a pro-rata credit for the time remaining between `churnTime` and subscription's next renewal time. (default: false)
  --reason: string@reason-completer # Cancellation reason. (default: other)
  --status: string@status-completer-1 # "draft" defines that the cancellation isn't applied on an invoice and subscription but can be inspected to see the charge. "confirmed" will set a subscription to be canceled when the `churnTime` is reached. "completed" is a read-only status which is set by the system when the churnTime is reached. The cancellation may not be changed or deleted when the status is "completed". (default: confirmed)
  subscription_id: string # Identifier of the canceled subscription order.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscription-cancellations"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: canceledBy, var: canceled_by}, {name: churnTime, var: churn_time}, {name: createdTime, var: created_time}, {name: description, var: description}, {name: lineItems, var: line_items}, {name: prorated, var: prorated}, {name: reason, var: reason}, {name: status, var: status}, {name: subscriptionId, var: subscription_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, canceled_by: $canceled_by, churn_time: $churn_time, created_time: $created_time, description: $description, line_items: $line_items, prorated: $prorated, reason: $reason, status: $status, subscription_id: $subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a cancellation
#
# DELETE /subscription-cancellations/{id}
# operationId: DeleteSubscriptionCancellation
export def "delete-subscription-cancellation" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscription-cancellations/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an order сancellation
#
# GET /subscription-cancellations/{id}
# Returns: record<_links: table<rel: string, href: string>, appliedInvoiceId: string, canceledBy: string, canceledTime: string, churnTime: string, createdTime: string, description: string, id: string, lineItemSubtotal: float, lineItems: table<createdTime: string, description: string, periodEndTime: string, periodStartTime: string, quantity: int, type: string, unitPriceAmount: float, unitPriceCurrency: string>, prorated: bool, proratedInvoiceId: string, reason: string, status: string, subscriptionId: string>
# operationId: GetSubscriptionCancellation
export def "get-subscription-cancellation" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscription-cancellations/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel an order
#
# PUT /subscription-cancellations/{id}
# Returns: record<_links: table<rel: string, href: string>, appliedInvoiceId: string, canceledBy: string, canceledTime: string, churnTime: string, createdTime: string, description: string, id: string, lineItemSubtotal: float, lineItems: table<createdTime: string, description: string, periodEndTime: string, periodStartTime: string, quantity: int, type: string, unitPriceAmount: float, unitPriceCurrency: string>, prorated: bool, proratedInvoiceId: string, reason: string, status: string, subscriptionId: string>
# operationId: PutSubscriptionCancellation
export def "put-subscription-cancellation" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --canceled-by: string@canceled-by-completer # Who did the cancellation. (default: customer)
  churn_time: string # The time when the subscription will be deactivated. (format: date-time)
  --created-time: string # The time of resource creation (when it is posted). (format: date-time)
  --description: string # Cancel reason description in free form.
  --line-items: list # Items to be added to the new invoice. Proration item is generated and added automatically. — item shape: {createdTime?: string, description?: string, periodEndTime?: string, periodStartTime?: string, quantity: int, type: "debit"|"credit", unitPriceAmount: float, unitPriceCurrency: string}
  --prorated: oneof<nothing, bool> # Defines if the customer gets a pro-rata credit for the time remaining between `churnTime` and subscription's next renewal time. (default: false)
  --reason: string@reason-completer # Cancellation reason. (default: other)
  --status: string@status-completer-1 # "draft" defines that the cancellation isn't applied on an invoice and subscription but can be inspected to see the charge. "confirmed" will set a subscription to be canceled when the `churnTime` is reached. "completed" is a read-only status which is set by the system when the churnTime is reached. The cancellation may not be changed or deleted when the status is "completed". (default: confirmed)
  subscription_id: string # Identifier of the canceled subscription order.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscription-cancellations/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: canceledBy, var: canceled_by}, {name: churnTime, var: churn_time}, {name: createdTime, var: created_time}, {name: description, var: description}, {name: lineItems, var: line_items}, {name: prorated, var: prorated}, {name: reason, var: reason}, {name: status, var: status}, {name: subscriptionId, var: subscription_id}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, canceled_by: $canceled_by, churn_time: $churn_time, created_time: $created_time, description: $description, line_items: $line_items, prorated: $prorated, reason: $reason, status: $status, subscription_id: $subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of reactivations
#
# GET /subscription-reactivations
# Returns: table<_links: list<record>, cancellationId: string, createdTime: string, description: string, effectiveTime: string, id: string, renewalTime: string, subscriptionId: string>
# operationId: GetSubscriptionReactivationCollection
export def "get-subscription-reactivation-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscription-reactivations"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: sort, var: sort, style: csv}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, filter: $filter, sort: $sort, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reactivate an order
#
# POST /subscription-reactivations
# Returns: record<_links: table<rel: string, href: string>, cancellationId: string, createdTime: string, description: string, effectiveTime: string, id: string, renewalTime: string, subscriptionId: string>
# operationId: PostSubscriptionReactivation
export def "post-subscription-reactivation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --description: string # Reactivation reason description in free form.
  --effective-time: string # The date from which the service period would start, unless the subscription is canceled but still active. In case the susbcription is still active, the subscription will continue the current service period. If omitted, it will default to the current time. (format: date-time)
  --renewal-time: string # The time of the next subscription renewal. If omitted then it is computed from the effective time. If the subscription is canceled but active it is ignored, so the next renewal will happen as scheduled. (format: date-time)
  subscription_id: string # Identifier of the reactivated subscription.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscription-reactivations"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: effectiveTime, var: effective_time}, {name: renewalTime, var: renewal_time}, {name: subscriptionId, var: subscription_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, description: $description, effective_time: $effective_time, renewal_time: $renewal_time, subscription_id: $subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an order reactivation
#
# GET /subscription-reactivations/{id}
# Returns: record<_links: table<rel: string, href: string>, cancellationId: string, createdTime: string, description: string, effectiveTime: string, id: string, renewalTime: string, subscriptionId: string>
# operationId: GetSubscriptionReactivation
export def "get-subscription-reactivation" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscription-reactivations/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of orders
#
# GET /subscriptions
# Returns: table<orderType: string>
# operationId: GetSubscriptionCollection
export def "get-subscription-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --q: string # The partial search of the text fields.
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. To expand multiple objects, it accepts a comma-separated list of objects (example: `expand=recentInvoice,initialInvoice`). Available arguments are: - recentInvoice - initialInvoice - customer - website See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions"
    query: [{name: filter, var: filter}, {name: sort, var: sort, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: q, var: q}, {name: expand, var: expand}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    filter: $filter, sort: $sort, limit: $limit, offset: $offset, q: $q, expand: $expand, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an order
#
# POST /subscriptions
# Discriminator (request): orderType = one-time-order, subscription-order
# Returns: record<orderType: string>
# operationId: PostSubscription
export def "post-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. To expand multiple objects, it accepts a comma-separated list of objects (example: `expand=recentInvoice,initialInvoice`). Available arguments are: - recentInvoice - initialInvoice - customer - website See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  order_type: string@order-type-completer # Specifies the type of order, a subscription or a one-time purchase.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions"
    query: [{name: expand, var: expand}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: orderType, var: order_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    expand: $expand, organization_id: $organization_id, order_type: $order_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an order
#
# GET /subscriptions/{id}
# Discriminator (response): orderType = one-time-order, subscription-order
# Returns: record<orderType: string>
# operationId: GetSubscription
export def "get-subscription" [
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
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. To expand multiple objects, it accepts a comma-separated list of objects (example: `expand=recentInvoice,initialInvoice`). Available arguments are: - recentInvoice - initialInvoice - customer - website See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: expand, var: expand}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, expand: $expand, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upsert an order with predefined ID
#
# PUT /subscriptions/{id}
# Discriminator (request): orderType = one-time-order, subscription-order
# Returns: record<orderType: string>
# operationId: PutSubscription
export def "put-subscription" [
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
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. To expand multiple objects, it accepts a comma-separated list of objects (example: `expand=recentInvoice,initialInvoice`). Available arguments are: - recentInvoice - initialInvoice - customer - website See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  order_type: string@order-type-completer # Specifies the type of order, a subscription or a one-time purchase.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: expand, var: expand}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: orderType, var: order_type}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: reb-apikey
  } {
    id: $id, expand: $expand, organization_id: $organization_id, order_type: $order_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change an order's items
#
# POST /subscriptions/{id}/change-items
# Discriminator (response): orderType = one-time-order, subscription-order
# Returns: record<orderType: string>
# operationId: PostSubscriptionItemsChange
export def "post-subscription-items-change" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --effective-time: string # The date from which the renewal time (for `reset` operations) and proration calculations are made. If omitted, it will default to the current time. (format: date-time)
  items: list # item shape: {plan: record, quantity: int}
  --keep-trial: oneof<nothing, bool> # If set to true and the subscription order has an active trial, it will use that trial further. Works with 'retain' renewalPolicy only. (default: false)
  --preview: oneof<nothing, bool> # If set to true, it will not change the subscription. It allows for a way to preview the changes that would be made to a subscription. (default: false)
  --prorated: oneof<nothing, bool> # Whether or not to give a pro rata credit for the amount of time remaining between the `effectiveTime` and the end of the current period. In addition, if the `renewalTime` is retained (by setting the `renewalPolicy` to `retain`), then a pro rata debit will occur as well, for the amount between the `effectiveTime` and the `renewalTime` as a percentage of the normal period size.
  renewal_policy: string@renewal-policy-completer # The value determines whether the subscription retains its current `renewalTime` or resets it to a newly calculated `renewalTime`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{id}/change-items"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: effectiveTime, var: effective_time}, {name: items, var: items}, {name: keepTrial, var: keep_trial}, {name: preview, var: preview}, {name: prorated, var: prorated, required: true}, {name: renewalPolicy, var: renewal_policy}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, effective_time: $effective_time, items: $items, keep_trial: $keep_trial, preview: $preview, prorated: $prorated, renewal_policy: $renewal_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Issue an interim invoice for a subscription order
#
# POST /subscriptions/{id}/interim-invoice
# Returns: record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<"3ds": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>
# operationId: PostSubscriptionInterimInvoice
export def "post-subscription-interim-invoice" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --transaction-id: string # If present, applies a payment to the invoice created. If the payment is for the invoice total, it would be marked as paid.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{id}/interim-invoice"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: transactionId, var: transaction_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, transaction_id: $transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of order timeline messages
#
# GET /subscriptions/{id}/timeline
# Returns: table<_links: list<record>, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>
# operationId: GetSubscriptionTimelineCollection
export def "get-subscription-timeline-collection" [
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
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --q: string # The partial search of the text fields.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{id}/timeline"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: sort, var: sort, style: csv}, {name: q, var: q}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, limit: $limit, offset: $offset, filter: $filter, sort: $sort, q: $q, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an order Timeline comment
#
# POST /subscriptions/{id}/timeline
# Returns: record<_links: table<rel: string, href: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>
# operationId: PostSubscriptionTimeline
export def "post-subscription-timeline" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --message: string # The message that describes the message details.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{id}/timeline"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Order Timeline message
#
# DELETE /subscriptions/{id}/timeline/{messageId}
# operationId: DeleteSubscriptionTimeline
export def "delete-subscription-timeline" [
  id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{id}/timeline/{messageId}"
    path_params: [{name: id, var: id}, {name: messageId, var: message_id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    id: $id, message_id: $message_id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an Order Timeline message
#
# GET /subscriptions/{id}/timeline/{messageId}
# Returns: record<_links: table<rel: string, href: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>
# operationId: GetSubscriptionTimeline
export def "get-subscription-timeline" [
  id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{id}/timeline/{messageId}"
    path_params: [{name: id, var: id}, {name: messageId, var: message_id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, message_id: $message_id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve subscription order's upcoming invoice
#
# GET /subscriptions/{id}/upcoming-invoices
# Returns: table<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, discountAmount: float, discounts: list<record>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: list<record>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list, afterRetryEndPolicies: list, attempts: list>, revision: int, transactions: list<record>, type: string>
# operationId: GetSubscriptionUpcomingInvoiceCollection
export def "get-subscription-upcoming-invoice-collection" [
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
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{id}/upcoming-invoices"
    path_params: [{name: id, var: id}]
    query: [{name: expand, var: expand}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, expand: $expand, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Issue an upcoming invoice for early pay
#
# POST /subscriptions/{id}/upcoming-invoices/{invoiceId}/issue
# Returns: record<abandonedTime: string, amount: float, amountDue: float, autopayRetryNumber: int, autopayScheduledTime: string, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, collectionPeriod: int, createdTime: string, currency: string, delinquentCollectionPeriod: int, deliveryAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, discountAmount: float, discounts: table<amount: float, couponId: string, description: string, redemptionId: string>, dueTime: string, id: string, invoiceNumber: int, issuedTime: string, items: table<_embedded: list, _links: list, createdTime: string, description: string, discountAmount: float, id: string, periodEndTime: string, periodNumber: int, periodStartTime: string, price: float, productId: string, quantity: int, type: string, unitPrice: float, updatedTime: string>, notes: string, paidTime: string, paymentFormUrl: string, poNumber: string, shipping: record<calculator: string>, status: string, subscriptionId: string, subtotalAmount: float, tax: record<amount: int, calculator: string>, updatedTime: string, voidedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, customerId: string, dueReminderNumber: int, dueReminderTime: string, retryInstruction: record<afterAttemptPolicies: list<string>, afterRetryEndPolicies: list<string>, attempts: list<record>>, revision: int, transactions: table<"3ds": record, amount: float, billingAddress: record, billingDescriptor: string, childTransactions: list, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list, type: string, updatedTime: string, websiteId: string, _embedded: list, _links: list, acquirerName: string, arn: string, bin: string, bumpOffer: record, dcc: record, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record, revision: int, riskMetadata: record, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>, type: string>
# operationId: PostUpcomingInvoiceIssuance
export def "post-upcoming-invoice-issuance" [
  id: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --due-time: string # Invoice due time. Will be set same as `issuedTime` if `null` or omitted. (nullable, format: date-time)
  --issued-time: string # Invoice issued time. Will be issued immediately if `null` or omitted. (nullable, format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{id}/upcoming-invoices/{invoiceId}/issue"
    path_params: [{name: id, var: id}, {name: invoiceId, var: invoice_id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: dueTime, var: due_time}, {name: issuedTime, var: issued_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, invoice_id: $invoice_id, organization_id: $organization_id, due_time: $due_time, issued_time: $issued_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of tags
#
# GET /tags
# Returns: table<_links: list<any>, createdTime: string, id: string, name: string, updatedTime: string>
# operationId: GetTagCollection
export def "get-tag-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tags"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: q, var: q}, {name: sort, var: sort, style: csv}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, filter: $filter, q: $q, sort: $sort, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a tag
#
# POST /tags
# Returns: record<_links: list<any>, createdTime: string, id: string, name: string, updatedTime: string>
# operationId: PostTag
export def "post-tag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # The tag's created time. (format: date-time)
  name: string # The tag is unique name, which is case-insensitive. (e.g. New)
  --updated-time: string # The tag's updated time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: name, var: name}, {name: updatedTime, var: updated_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    organization_id: $organization_id, created_time: $created_time, name: $name, updated_time: $updated_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a tag
#
# DELETE /tags/{tag}
# operationId: DeleteTag
export def "delete-tag" [
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/tags/{tag}"
    path_params: [{name: tag, var: tag}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    tag: $tag, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a tag
#
# GET /tags/{tag}
# Returns: record<_links: list<any>, createdTime: string, id: string, name: string, updatedTime: string>
# operationId: GetTag
export def "get-tag" [
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tags/{tag}"
    path_params: [{name: tag, var: tag}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    tag: $tag, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a tag
#
# PATCH /tags/{tag}
# Returns: record<_links: list<any>, createdTime: string, id: string, name: string, updatedTime: string>
# operationId: PatchTag
export def "patch-tag" [
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --created-time: string # The tag's created time. (format: date-time)
  name: string # The tag is unique name, which is case-insensitive. (e.g. New)
  --updated-time: string # The tag's updated time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/tags/{tag}"
    path_params: [{name: tag, var: tag}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdTime, var: created_time}, {name: name, var: name}, {name: updatedTime, var: updated_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    tag: $tag, organization_id: $organization_id, created_time: $created_time, name: $name, updated_time: $updated_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Untag a list of customers
#
# DELETE /tags/{tag}/customers
# operationId: DeleteTagCustomerCollection
export def "delete-tag-customer-collection" [
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  customer_ids: list<string> # The list of customer IDs.
]: any -> any {
  $in | http-request {
    method: delete
    path: "/tags/{tag}/customers"
    path_params: [{name: tag, var: tag}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customerIds, var: customer_ids}]}
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    tag: $tag, organization_id: $organization_id, customer_ids: $customer_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tag a list of customers
#
# POST /tags/{tag}/customers
# operationId: PostTagCustomerCollection
export def "post-tag-customer-collection" [
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  customer_ids: list<string> # The list of customer IDs.
]: any -> any {
  $in | http-request {
    method: post
    path: "/tags/{tag}/customers"
    path_params: [{name: tag, var: tag}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customerIds, var: customer_ids}]}
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    tag: $tag, organization_id: $organization_id, customer_ids: $customer_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Untag a customer
#
# DELETE /tags/{tag}/customers/{customerId}
# operationId: DeleteTagCustomer
export def "delete-tag-customer" [
  tag: string
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/tags/{tag}/customers/{customerId}"
    path_params: [{name: tag, var: tag}, {name: customerId, var: customer_id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    tag: $tag, customer_id: $customer_id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tag a customer
#
# POST /tags/{tag}/customers/{customerId}
# operationId: PostTagCustomer
export def "post-tag-customer" [
  tag: string
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: post
    path: "/tags/{tag}/customers/{customerId}"
    path_params: [{name: tag, var: tag}, {name: customerId, var: customer_id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    tag: $tag, customer_id: $customer_id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of tokens
#
# GET /tokens
# Returns: list<any>
# operationId: GetTokenCollection
export def "get-token-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tokens"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a payment token
#
# POST /tokens
# operationId: PostToken
export def "post-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --billing-address: record # The billing address object. — shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  method: string
  --payment-instrument: record # The payment card instrument details. — shape: {cvv?: string, expMonth?: int, expYear?: int, pan?: string}
  --created-time: string # Token created time. (format: date-time)
  --expiration-time: string # Token expiration time. (format: date-time)
  --lead-source: record # shape: {affiliate?: string, campaign?: string, clickId?: string, content?: string, createdTime?: string, medium?: string, path?: string, referrer?: string, salesAgent?: string, source?: string, subAffiliate?: string, term?: string}
  --risk-metadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
  --updated-time: string # Token updated time. (format: date-time)
  --usage-time: string # Token usage time. (format: date-time)
]: any -> any {
  $in | http-request {
    method: post
    path: "/tokens"
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingAddress, var: billing_address}, {name: method, var: method}, {name: paymentInstrument, var: payment_instrument}, {name: createdTime, var: created_time}, {name: expirationTime, var: expiration_time}, {name: leadSource, var: lead_source}, {name: riskMetadata, var: risk_metadata}, {name: updatedTime, var: updated_time}, {name: usageTime, var: usage_time}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    organization_id: $organization_id, billing_address: $billing_address, method: $method, payment_instrument: $payment_instrument, created_time: $created_time, expiration_time: $expiration_time, lead_source: $lead_source, risk_metadata: $risk_metadata, updated_time: $updated_time, usage_time: $usage_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a token
#
# GET /tokens/{token}
# operationId: GetToken
export def "get-token" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: get
    path: "/tokens/{token}"
    path_params: [{name: token, var: token_arg}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_arg: $token_arg, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of transactions
#
# GET /transactions
# Returns: table<"3ds": record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list<string>, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, acquirerName: string, arn: string, bin: string, bumpOffer: record<language: string, order: record, outcome: string, presentedOffers: list, selectedOffer: record, version: string>, dcc: record<base: record, outcome: string, quote: record, usdMarkup: float>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record, cvvResponse: record, response: record>, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>
# operationId: GetTransactionCollection
export def "get-transaction-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --q: string # The partial search of the text fields.
  --sort: list<string> # The collection items sort field and order (prefix with "-" for descending sort).
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/transactions"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: q, var: q}, {name: sort, var: sort, style: csv}, {name: expand, var: expand}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    limit: $limit, offset: $offset, filter: $filter, q: $q, sort: $sort, expand: $expand, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a transaction
#
# POST /transactions
# Returns: record<"3ds": record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list<string>, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, acquirerName: string, arn: string, bin: string, bumpOffer: record<language: string, order: record<amount: float, currency: string>, outcome: string, presentedOffers: list<record>, selectedOffer: record<bumpAmount: float, bumpAmountInUsd: float, customFields: record, offerId: string, offerType: string>, version: string>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: float>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>
# operationId: PostTransaction
@deprecated --flag payment-instrument
export def "post-transaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  amount: float # The transaction amount. (format: double, e.g. 97.97)
  --billing-address: record # Billing address. If not supplied, we use the billing address associated with the payment instrument, and then customer. (nullable) — shape: {address?: string, address2?: string, city?: string, country?: string, emails?: list, firstName?: string, lastName?: string, organization?: string, phoneNumbers?: list, postalCode?: string, region?: string}
  currency: string # ISO 4217 alphabetic currency code.
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
  customer_id: string # The customer identifier string.
  --description: string # The payment description. (nullable)
  --gateway-account-id: string # Rebilly will select the appropriate payment gateway account for the transaction based on the properties of the transaction and the `gateway-account-requested` event rules configurations. If you wish to prevent Rebilly from making the gateway account selection, you may supply a gateway account id here, and it will be used instead. Only use this field if you intend to override the settings. (nullable)
  --invoice-ids: list<string> # The array of invoice identifiers. (nullable)
  --is-merchant-initiated: oneof<nothing, bool> # True if the transaction was initiated by the merchant. (default: false)
  --is-processed-outside: oneof<nothing, bool> # True if transaction was processed outside Rebilly. (default: false)
  --notification-url: string # The URL where a server-to-server notification request type `POST` with a transaction payload will be sent when the transaction's result is finalized. Do not trust the notification; follow with a `GET` request to confirm the result of the transaction. Please respond with a `2xx` HTTP status code, or we will reattempt the request again. You may use `{id}` or `{result}` as placeholders in the URL and we will replace them with the transaction's id and result accordingly. (nullable, format: uri)
  --payment-instruction: any # Payment instruction. If not supplied, customer's default payment instrument will be used.
  --payment-instrument: record # DEPRECATED
  --processed-time: string # The time the transaction was processed. Can be specified only if transaction was processed outside Rebilly. (format: date-time)
  --redirect-url: string # The URL to redirect the end-user when an offsite transaction is completed. Defaults to the website's configured URL. You may use `{id}` or `{result}` as placeholders in the URL and we will replace them with the transaction's id and result accordingly. (nullable, format: uri)
  --request-id: string # The request id is **recommended**. It prevents duplicate transaction requests within a short period of time. If a duplicate request is sent with the same `requestId` it will be ignored to prevent double-billing anyone. It must be unique within a 24-hour period. We recommend generating a UUID v4 as its value. (nullable, e.g. 44433322-2c4y-483z-a0a9-158621f77a21)
  --risk-metadata: record # Risk metadata used for 3DS and risk scoring. — shape: {browserData?: record, fingerprint?: string, httpHeaders?: record, ipAddress?: string}
  website_id: string # The website identifier string.
  type: string@type-completer-7 # The type of transaction requested. You should always include the type within your API request. This supports a limited subset of Transaction types. To refund or void, use the refund endpoint. To `capture` use the `sale` type. If any existing `authorize` transactions are eligible, then they will be captured and the `sale` will be converted to a `capture` type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transactions"
    query: [{name: expand, var: expand}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: billingAddress, var: billing_address}, {name: currency, var: currency}, {name: customFields, var: custom_fields}, {name: customerId, var: customer_id}, {name: description, var: description}, {name: gatewayAccountId, var: gateway_account_id}, {name: invoiceIds, var: invoice_ids}, {name: isMerchantInitiated, var: is_merchant_initiated}, {name: isProcessedOutside, var: is_processed_outside}, {name: notificationUrl, var: notification_url}, {name: paymentInstruction, var: payment_instruction}, {name: paymentInstrument, var: payment_instrument}, {name: processedTime, var: processed_time}, {name: redirectUrl, var: redirect_url}, {name: requestId, var: request_id}, {name: riskMetadata, var: risk_metadata}, {name: websiteId, var: website_id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    expand: $expand, organization_id: $organization_id, amount: $amount, billing_address: $billing_address, currency: $currency, custom_fields: $custom_fields, customer_id: $customer_id, description: $description, gateway_account_id: $gateway_account_id, invoice_ids: $invoice_ids, is_merchant_initiated: $is_merchant_initiated, is_processed_outside: $is_processed_outside, notification_url: $notification_url, payment_instruction: $payment_instruction, payment_instrument: $payment_instrument, processed_time: $processed_time, redirect_url: $redirect_url, request_id: $request_id, risk_metadata: $risk_metadata, website_id: $website_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Transaction
#
# GET /transactions/{id}
# Returns: record<"3ds": record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list<string>, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, acquirerName: string, arn: string, bin: string, bumpOffer: record<language: string, order: record<amount: float, currency: string>, outcome: string, presentedOffers: list<record>, selectedOffer: record<bumpAmount: float, bumpAmountInUsd: float, customFields: record, offerId: string, offerType: string>, version: string>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: float>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>
# operationId: GetTransaction
export def "get-transaction" [
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
  --expand: string # Expand a response to get a full related object included inside of the `_embedded` path in the response. It accepts a comma-separated list of objects to expand. See the [expand guide](https://api-reference.rebilly.com/#section/Expand-to-include-embedded-objects) for more info.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transactions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: expand, var: expand}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, expand: $expand, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a transaction
#
# PATCH /transactions/{id}
# Returns: record<"3ds": record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list<string>, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, acquirerName: string, arn: string, bin: string, bumpOffer: record<language: string, order: record<amount: float, currency: string>, outcome: string, presentedOffers: list<record>, selectedOffer: record<bumpAmount: float, bumpAmountInUsd: float, customFields: record, offerId: string, offerType: string>, version: string>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: float>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>
# operationId: PatchTransaction
export def "patch-transaction" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --custom-fields: record # Custom Fields list as a map `{"custom field name": "custom field value", ...}`. The format must follow the saved format (see Custom Fields section for the formats). (default: {}, e.g. {foo: bar})
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/transactions/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customFields, var: custom_fields}]}
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, custom_fields: $custom_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query a Transaction
#
# POST /transactions/{id}/query
# Returns: record<amount: float, currency: string, result: string, status: string>
# operationId: PostTransactionQuery
export def "post-transaction-query" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/transactions/{id}/query"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refund a Transaction
#
# POST /transactions/{id}/refund
# Returns: record<"3ds": record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list<string>, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, acquirerName: string, arn: string, bin: string, bumpOffer: record<language: string, order: record<amount: float, currency: string>, outcome: string, presentedOffers: list<record>, selectedOffer: record<bumpAmount: float, bumpAmountInUsd: float, customFields: record, offerId: string, offerType: string>, version: string>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: float>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>
# operationId: PostTransactionRefund
export def "post-transaction-refund" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  amount: float # Refund amount. (format: double)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transactions/{id}/refund"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, amount: $amount
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of transaction timeline messages
#
# GET /transactions/{id}/timeline
# Returns: table<_links: list<record>, extraData: record<actions: list, author: record, links: list, mentions: record, tables: list>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>
# operationId: GetTransactionTimelineCollection
export def "get-transaction-timeline-collection" [
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
  --limit: int # The collection items limit.
  --offset: int # The collection items offset.
  --filter: string # The collection items filter requires a special format. Use "," for multiple allowed values. Use ";" for multiple fields. See the [filter guide](https://api-reference.rebilly.com/#section/Using-filter-with-collections) for more options and examples about this format.
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/transactions/{id}/timeline"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, limit: $limit, offset: $offset, filter: $filter, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a transaction Timeline comment
#
# POST /transactions/{id}/timeline
# Returns: record<_links: table<rel: string, href: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>
# operationId: PostTransactionTimeline
export def "post-transaction-timeline" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --message: string # The message that describes the message details.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transactions/{id}/timeline"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}]}
    accept: ["application/json"]
    ok: [201]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Transaction Timeline message
#
# DELETE /transactions/{id}/timeline/{messageId}
# operationId: DeleteTransactionTimeline
export def "delete-transaction-timeline" [
  id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> any {
  http-request {
    method: delete
    path: "/transactions/{id}/timeline/{messageId}"
    path_params: [{name: id, var: id}, {name: messageId, var: message_id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [204]
    auth: reb-apikey
  } {
    id: $id, message_id: $message_id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a transaction Timeline message
#
# GET /transactions/{id}/timeline/{messageId}
# Returns: record<_links: table<rel: string, href: string>, extraData: record<actions: list<record>, author: record<userFullName: string, userId: string>, links: list<record>, mentions: record, tables: list<record>>, id: string, message: string, occurredTime: string, triggeredBy: string, type: string>
# operationId: GetTransactionTimeline
export def "get-transaction-timeline" [
  id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transactions/{id}/timeline/{messageId}"
    path_params: [{name: id, var: id}, {name: messageId, var: message_id}]
    header: [{name: Organization-Id, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, message_id: $message_id, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Transaction status
#
# POST /transactions/{id}/update
# Returns: record<"3ds": record<authenticated: string, enrolled: string, flow: string, isDowngraded: bool, liability: string, version: string>, amount: float, billingAddress: record<address: string, address2: string, city: string, country: string, emails: list<record>, firstName: string, hash: string, lastName: string, organization: string, phoneNumbers: list<record>, postalCode: string, region: string>, billingDescriptor: string, childTransactions: list<string>, createdTime: string, currency: string, customFields: record, customerId: string, description: string, gatewayName: string, has3ds: bool, hasAmountAdjustment: bool, id: string, invoiceIds: list<string>, isRebill: bool, isRetry: bool, parentTransactionId: string, paymentInstrument: record, planIds: list<string>, processedTime: string, purchaseAmount: float, purchaseCurrency: string, rebillNumber: int, redirectUrl: string, requestAmount: float, requestCurrency: string, requestId: string, result: string, retryNumber: int, status: string, subscriptionIds: list<string>, type: string, updatedTime: string, websiteId: string, _embedded: list<any>, _links: list<any>, acquirerName: string, arn: string, bin: string, bumpOffer: record<language: string, order: record<amount: float, currency: string>, outcome: string, presentedOffers: list<record>, selectedOffer: record<bumpAmount: float, bumpAmountInUsd: float, customFields: record, offerId: string, offerType: string>, version: string>, dcc: record<base: record<amount: float, currency: string>, outcome: string, quote: record<amount: float, currency: string>, usdMarkup: float>, discrepancyTime: string, disputeStatus: string, disputeTime: string, gateway: record<avsResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, cvvResponse: record<code: string, message: string, originalCode: string, originalMessage: string>, response: record<code: string, message: string, originalCode: string, originalMessage: string, type: string>>, gatewayAccountId: string, gatewayTransactionId: string, hadDiscrepancy: bool, hasBumpOffer: bool, hasDcc: bool, isDisputed: bool, isMerchantInitiated: bool, isProcessedOutside: bool, isReconciled: bool, method: string, notificationUrl: string, orderId: string, referenceData: record, reportAmount: float, reportCurrency: string, retriedTransactionId: string, retriesResult: string, retryInstruction: record<afterAttemptPolicy: string, afterRetryEndPolicy: string, attempts: list<record>>, revision: int, riskMetadata: record<accuracyRadius: int, browserData: record<colorDepth: int, isJavaEnabled: bool, language: string, screenHeight: int, screenWidth: int, timeZoneOffset: int>, city: string, country: string, deviceVelocity: int, distance: int, fingerprint: string, hasMismatchedBankCountry: bool, hasMismatchedBillingAddressCountry: bool, hasMismatchedHolderName: bool, hasMismatchedTimeZone: bool, httpHeaders: record, ipAddress: string, isHosting: bool, isProxy: bool, isTor: bool, isVpn: bool, isp: string, latitude: float, longitude: float, paymentInstrumentVelocity: int, postalCode: string, region: string, score: int, timeZone: string, vpnServiceName: string>, riskScore: int, scheduledTime: string, settlementTime: string, velocity: int>
# operationId: PostTransactionUpdate
export def "post-transaction-update" [
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
  --organization-id: string # Organization identifier in scope of which need to perform request (if not specified, the default organization will be used). (e.g. 4f6cf35x-2c4y-483z-a0a9-158621f77a21)
  --amount: float # The transaction amount. (format: double)
  --currency: string # The transaction currency.
  result: string@result-completer # Transaction result.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transactions/{id}/update"
    path_params: [{name: id, var: id}]
    header: [{name: Organization-Id, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: currency, var: currency}, {name: result, var: result}]}
    accept: ["application/json"]
    ok: [200]
    auth: reb-apikey
  } {
    id: $id, organization_id: $organization_id, amount: $amount, currency: $currency, result: $result
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
