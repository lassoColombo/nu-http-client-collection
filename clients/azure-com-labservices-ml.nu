# Auto-generated client for ManagedLabsClient v2018-10-15
# Source: https://api.apis.guru/v2/specs/azure.com/labservices-ML/2018-10-15/swagger.json
# Auth: --token flag or $env.MANAGEDLABSCLIENT_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "MANAGEDLABSCLIENT_TOKEN"
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def add-remove-completer [] { ["Add" "Remove"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    provider-operations-list: "record<nextLink: string, value: table<display: record, name: string>>"
    global-users-get-environment: "record<environment: record<description: string, environmentState: string, id: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, name: string, passwordLastReset: string, provisioningState: string, totalUsage: string, virtualMachineDetails: record<lastKnownPowerState: string, privateIpAddress: string, provisioningState: string, rdpAuthority: string, sshAuthority: string, userName: string>>>"
    global-users-get-operation-batch-status: "record<items: table<operationUrl: string, status: string>>"
    global-users-get-operation-status: "record<status: string>"
    global-users-get-personal-preferences: "record<favoriteLabResourceIds: list<string>, id: string>"
    global-users-list-environments: "record<environments: table<description: string, environmentState: string, id: string, latestOperationResult: record, name: string, passwordLastReset: string, provisioningState: string, totalUsage: string, virtualMachineDetails: record>>"
    global-users-list-labs: "record<labs: table<id: string, name: string, provisioningState: string, usageQuota: string>>"
    lab-accounts-list-by-subscription: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    operations-get: "record<error: record<code: string, message: string>, status: string>"
    lab-accounts-list-by-resource-group: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    lab-accounts-get: "record<properties: record<enabledRegionSelection: bool, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, sizeConfiguration: record<environmentSizes: list>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    lab-accounts-update: "record<properties: record<enabledRegionSelection: bool, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, sizeConfiguration: record<environmentSizes: list>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    lab-accounts-create-or-update: "record<properties: record<enabledRegionSelection: bool, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, sizeConfiguration: record<environmentSizes: list>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    gallery-images-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    gallery-images-get: "record<properties: record<author: string, createdDate: string, description: string, icon: string, imageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isEnabled: bool, isOverride: bool, isPlanAuthorized: bool, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, planId: string, provisioningState: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    gallery-images-update: "record<properties: record<author: string, createdDate: string, description: string, icon: string, imageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isEnabled: bool, isOverride: bool, isPlanAuthorized: bool, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, planId: string, provisioningState: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    gallery-images-create-or-update: "record<properties: record<author: string, createdDate: string, description: string, icon: string, imageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isEnabled: bool, isOverride: bool, isPlanAuthorized: bool, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, planId: string, provisioningState: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    lab-accounts-get-regional-availability: "record<regionalAvailability: table<region: string, sizeAvailabilities: list>>"
    labs-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    labs-get: "record<properties: record<createdByObjectId: string, createdByUserPrincipalName: string, createdDate: string, invitationCode: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, maxUsersInLab: int, provisioningState: string, uniqueIdentifier: string, usageQuota: string, userAccessMode: string, userQuota: int>, id: string, location: string, name: string, tags: record, type: string>"
    labs-update: "record<properties: record<createdByObjectId: string, createdByUserPrincipalName: string, createdDate: string, invitationCode: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, maxUsersInLab: int, provisioningState: string, uniqueIdentifier: string, usageQuota: string, userAccessMode: string, userQuota: int>, id: string, location: string, name: string, tags: record, type: string>"
    labs-create-or-update: "record<properties: record<createdByObjectId: string, createdByUserPrincipalName: string, createdDate: string, invitationCode: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, maxUsersInLab: int, provisioningState: string, uniqueIdentifier: string, usageQuota: string, userAccessMode: string, userQuota: int>, id: string, location: string, name: string, tags: record, type: string>"
    environment-settings-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    environment-settings-get: "record<properties: record<configurationState: string, description: string, lastChanged: string, lastPublished: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, publishingState: string, resourceSettings: record<cores: int, galleryImageResourceId: string, id: string, imageName: string, referenceVm: record, size: string>, title: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    environment-settings-update: "record<properties: record<configurationState: string, description: string, lastChanged: string, lastPublished: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, publishingState: string, resourceSettings: record<cores: int, galleryImageResourceId: string, id: string, imageName: string, referenceVm: record, size: string>, title: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    environment-settings-create-or-update: "record<properties: record<configurationState: string, description: string, lastChanged: string, lastPublished: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, publishingState: string, resourceSettings: record<cores: int, galleryImageResourceId: string, id: string, imageName: string, referenceVm: record, size: string>, title: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    environments-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    environments-get: "record<properties: record<claimedByUserName: string, claimedByUserObjectId: string, claimedByUserPrincipalId: string, isClaimed: bool, lastKnownPowerState: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, networkInterface: record<privateIpAddress: string, rdpAuthority: string, sshAuthority: string, username: string>, passwordLastReset: string, provisioningState: string, resourceSets: record<resourceSettingId: string, vmResourceId: string>, totalUsage: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    environments-update: "record<properties: record<claimedByUserName: string, claimedByUserObjectId: string, claimedByUserPrincipalId: string, isClaimed: bool, lastKnownPowerState: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, networkInterface: record<privateIpAddress: string, rdpAuthority: string, sshAuthority: string, username: string>, passwordLastReset: string, provisioningState: string, resourceSets: record<resourceSettingId: string, vmResourceId: string>, totalUsage: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    environments-create-or-update: "record<properties: record<claimedByUserName: string, claimedByUserObjectId: string, claimedByUserPrincipalId: string, isClaimed: bool, lastKnownPowerState: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, networkInterface: record<privateIpAddress: string, rdpAuthority: string, sshAuthority: string, username: string>, passwordLastReset: string, provisioningState: string, resourceSets: record<resourceSettingId: string, vmResourceId: string>, totalUsage: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    users-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    users-get: "record<properties: record<email: string, familyName: string, givenName: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, tenantId: string, totalUsage: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    users-update: "record<properties: record<email: string, familyName: string, givenName: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, tenantId: string, totalUsage: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
    users-create-or-update: "record<properties: record<email: string, familyName: string, givenName: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, tenantId: string, totalUsage: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["provider-operations-list" "global-users-get-environment" "global-users-get-operation-batch-status" "global-users-get-operation-status" "global-users-get-personal-preferences" "global-users-list-environments" "global-users-list-labs" "global-users-register" "global-users-reset-password" "global-users-start-environment" "global-users-stop-environment" "lab-accounts-list-by-subscription" "operations-get" "lab-accounts-list-by-resource-group" "lab-accounts-delete" "lab-accounts-get" "lab-accounts-update" "lab-accounts-create-or-update" "lab-accounts-create-lab" "gallery-images-list" "gallery-images-delete" "gallery-images-get" "gallery-images-update" "gallery-images-create-or-update" "lab-accounts-get-regional-availability" "labs-list" "labs-delete" "labs-get" "labs-update" "labs-create-or-update" "labs-add-users" "environment-settings-list" "environment-settings-delete" "environment-settings-get" "environment-settings-update" "environment-settings-create-or-update" "environment-settings-claim-any" "environments-list" "environments-delete" "environments-get" "environments-update" "environments-create-or-update" "environments-claim" "environments-reset-password" "environments-start" "environments-stop" "environment-settings-publish" "environment-settings-start" "environment-settings-stop" "labs-register" "users-list" "users-delete" "users-get" "users-update" "users-create-or-update" "commands"] | sort) } | get name | first)
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

# Result of the request to list REST API operations
#
# GET /providers/Microsoft.LabServices/operations
# Returns: record<nextLink: string, value: table<display: record, name: string>>
# operationId: ProviderOperations_List
export def "provider-operations-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.LabServices/operations"
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the virtual machine details
#
# POST /providers/Microsoft.LabServices/users/{userName}/getEnvironment
# Returns: record<environment: record<description: string, environmentState: string, id: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, name: string, passwordLastReset: string, provisioningState: string, totalUsage: string, virtualMachineDetails: record<lastKnownPowerState: string, privateIpAddress: string, provisioningState: string, rdpAuthority: string, sshAuthority: string, userName: string>>>
# operationId: GlobalUsers_GetEnvironment
export def "global-users-get-environment" [
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=environment)'
  --api-version: string # Client API version. (required, default: 2018-10-15)
  environment_id: string # The resourceId of the environment
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.LabServices/users/{userName}/getEnvironment"
    path_params: [{name: userName, var: user_name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentId, var: environment_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_name: $user_name, expand: $expand, api_version: $api_version, environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get batch operation status
#
# POST /providers/Microsoft.LabServices/users/{userName}/getOperationBatchStatus
# Returns: record<items: table<operationUrl: string, status: string>>
# operationId: GlobalUsers_GetOperationBatchStatus
export def "global-users-get-operation-batch-status" [
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  urls: list<string> # The operation url of long running operation
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.LabServices/users/{userName}/getOperationBatchStatus"
    path_params: [{name: userName, var: user_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: urls, var: urls}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_name: $user_name, api_version: $api_version, urls: $urls
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the status of long running operation
#
# POST /providers/Microsoft.LabServices/users/{userName}/getOperationStatus
# Returns: record<status: string>
# operationId: GlobalUsers_GetOperationStatus
export def "global-users-get-operation-status" [
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  operation_url: string # The operation url of long running operation
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.LabServices/users/{userName}/getOperationStatus"
    path_params: [{name: userName, var: user_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: operationUrl, var: operation_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_name: $user_name, api_version: $api_version, operation_url: $operation_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get personal preferences for a user
#
# POST /providers/Microsoft.LabServices/users/{userName}/getPersonalPreferences
# Returns: record<favoriteLabResourceIds: list<string>, id: string>
# operationId: GlobalUsers_GetPersonalPreferences
export def "global-users-get-personal-preferences" [
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  --add-remove: string@add-remove-completer # Enum indicating if user is adding or removing a favorite lab
  --lab-account-resource-id: string # Resource Id of the lab account
  --lab-resource-id: string # Resource Id of the lab to add/remove from the favorites list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.LabServices/users/{userName}/getPersonalPreferences"
    path_params: [{name: userName, var: user_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: addRemove, var: add_remove}, {name: labAccountResourceId, var: lab_account_resource_id}, {name: labResourceId, var: lab_resource_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_name: $user_name, api_version: $api_version, add_remove: $add_remove, lab_account_resource_id: $lab_account_resource_id, lab_resource_id: $lab_resource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Environments for the user
#
# POST /providers/Microsoft.LabServices/users/{userName}/listEnvironments
# Returns: record<environments: table<description: string, environmentState: string, id: string, latestOperationResult: record, name: string, passwordLastReset: string, provisioningState: string, totalUsage: string, virtualMachineDetails: record>>
# operationId: GlobalUsers_ListEnvironments
export def "global-users-list-environments" [
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  --lab-id: string # The resource Id of the lab
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.LabServices/users/{userName}/listEnvironments"
    path_params: [{name: userName, var: user_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: labId, var: lab_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_name: $user_name, api_version: $api_version, lab_id: $lab_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List labs for the user.
#
# POST /providers/Microsoft.LabServices/users/{userName}/listLabs
# Returns: record<labs: table<id: string, name: string, provisioningState: string, usageQuota: string>>
# operationId: GlobalUsers_ListLabs
export def "global-users-list-labs" [
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/providers/Microsoft.LabServices/users/{userName}/listLabs"
    path_params: [{name: userName, var: user_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_name: $user_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a user to a managed lab
#
# POST /providers/Microsoft.LabServices/users/{userName}/register
# operationId: GlobalUsers_Register
export def "global-users-register" [
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  --registration-code: string # The registration code of the lab.
]: any -> any {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.LabServices/users/{userName}/register"
    path_params: [{name: userName, var: user_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: registrationCode, var: registration_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_name: $user_name, api_version: $api_version, registration_code: $registration_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resets the user password on an environment This operation can take a while to complete
#
# POST /providers/Microsoft.LabServices/users/{userName}/resetPassword
# operationId: GlobalUsers_ResetPassword
export def "global-users-reset-password" [
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  environment_id: string # The resourceId of the environment
  --password: string # The password to assign to the user specified in
  --username: string # The username for which the password will be reset.
]: any -> any {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.LabServices/users/{userName}/resetPassword"
    path_params: [{name: userName, var: user_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentId, var: environment_id}, {name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    user_name: $user_name, api_version: $api_version, environment_id: $environment_id, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an environment by starting all resources inside the environment. This operation can take a while to complete
#
# POST /providers/Microsoft.LabServices/users/{userName}/startEnvironment
# operationId: GlobalUsers_StartEnvironment
export def "global-users-start-environment" [
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  environment_id: string # The resourceId of the environment
]: any -> any {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.LabServices/users/{userName}/startEnvironment"
    path_params: [{name: userName, var: user_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentId, var: environment_id}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    user_name: $user_name, api_version: $api_version, environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops an environment by stopping all resources inside the environment This operation can take a while to complete
#
# POST /providers/Microsoft.LabServices/users/{userName}/stopEnvironment
# operationId: GlobalUsers_StopEnvironment
export def "global-users-stop-environment" [
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  environment_id: string # The resourceId of the environment
]: any -> any {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.LabServices/users/{userName}/stopEnvironment"
    path_params: [{name: userName, var: user_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentId, var: environment_id}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    user_name: $user_name, api_version: $api_version, environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List lab accounts in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.LabServices/labaccounts
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: LabAccounts_ListBySubscription
export def "lab-accounts-list-by-subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=sizeConfiguration)'
  --filter: string # The filter to apply to the operation.
  --top: int # The maximum number of resources to return from the operation. (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation.
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.LabServices/labaccounts"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get operation
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.LabServices/locations/{locationName}/operations/{operationName}
# Returns: record<error: record<code: string, message: string>, status: string>
# operationId: Operations_Get
export def "operations-get" [
  subscription_id: string
  location_name: string
  operation_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.LabServices/locations/{locationName}/operations/{operationName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: locationName, var: location_name}, {name: operationName, var: operation_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, location_name: $location_name, operation_name: $operation_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List lab accounts in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: LabAccounts_ListByResourceGroup
export def "lab-accounts-list-by-resource-group" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=sizeConfiguration)'
  --filter: string # The filter to apply to the operation.
  --top: int # The maximum number of resources to return from the operation. (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation.
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete lab account. This operation can take a while to complete
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}
# operationId: LabAccounts_Delete
export def "lab-accounts-delete" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get lab account
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}
# Returns: record<properties: record<enabledRegionSelection: bool, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, sizeConfiguration: record<environmentSizes: list>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: LabAccounts_Get
export def "lab-accounts-get" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=sizeConfiguration)'
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify properties of lab accounts.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}
# Returns: record<properties: record<enabledRegionSelection: bool, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, sizeConfiguration: record<environmentSizes: list>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: LabAccounts_Update
export def "lab-accounts-update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  --properties: record # Properties of a Lab Account. — shape: {enabledRegionSelection?: bool, provisioningState?: string, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing Lab Account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}
# Returns: record<properties: record<enabledRegionSelection: bool, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, sizeConfiguration: record<environmentSizes: list>, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: LabAccounts_CreateOrUpdate
export def "lab-accounts-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  --properties: record # Properties of a Lab Account. — shape: {enabledRegionSelection?: bool, latestOperationResult?: record, provisioningState?: string, sizeConfiguration?: record, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a lab in a lab account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/createLab
# operationId: LabAccounts_CreateLab
export def "lab-accounts-create-lab" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  --environment-setting-creation-parameters: record # Settings related to creating an environment setting — shape: {resourceSettingCreationParameters: record}
  lab_creation_parameters: record # Settings related to creating a lab — shape: {maxUsersInLab?: int}
  --location: string # The location of the resource
  name: string # The name of the resource
  --tags: record # The tags of the resource.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/createLab"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentSettingCreationParameters, var: environment_setting_creation_parameters}, {name: labCreationParameters, var: lab_creation_parameters}, {name: location, var: location}, {name: name, var: name}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, api_version: $api_version, environment_setting_creation_parameters: $environment_setting_creation_parameters, lab_creation_parameters: $lab_creation_parameters, location: $location, name: $name, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List gallery images in a given lab account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: GalleryImages_List
export def "gallery-images-list" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=author)'
  --filter: string # The filter to apply to the operation.
  --top: int # The maximum number of resources to return from the operation. (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation.
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete gallery image.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages/{galleryImageName}
# operationId: GalleryImages_Delete
export def "gallery-images-delete" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  gallery_image_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages/{galleryImageName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: galleryImageName, var: gallery_image_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, gallery_image_name: $gallery_image_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get gallery image
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages/{galleryImageName}
# Returns: record<properties: record<author: string, createdDate: string, description: string, icon: string, imageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isEnabled: bool, isOverride: bool, isPlanAuthorized: bool, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, planId: string, provisioningState: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: GalleryImages_Get
export def "gallery-images-get" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  gallery_image_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=author)'
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages/{galleryImageName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: galleryImageName, var: gallery_image_name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, gallery_image_name: $gallery_image_name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify properties of gallery images.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages/{galleryImageName}
# Returns: record<properties: record<author: string, createdDate: string, description: string, icon: string, imageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isEnabled: bool, isOverride: bool, isPlanAuthorized: bool, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, planId: string, provisioningState: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: GalleryImages_Update
export def "gallery-images-update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  gallery_image_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  --properties: record # The gallery image properties — shape: {isEnabled?: bool, isOverride?: bool, isPlanAuthorized?: bool, provisioningState?: string, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages/{galleryImageName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: galleryImageName, var: gallery_image_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, gallery_image_name: $gallery_image_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing Gallery Image.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages/{galleryImageName}
# Returns: record<properties: record<author: string, createdDate: string, description: string, icon: string, imageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isEnabled: bool, isOverride: bool, isPlanAuthorized: bool, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, planId: string, provisioningState: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: GalleryImages_CreateOrUpdate
export def "gallery-images-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  gallery_image_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  --properties: record # The gallery image properties — shape: {imageReference?: record, isEnabled?: bool, isOverride?: bool, isPlanAuthorized?: bool, latestOperationResult?: record, provisioningState?: string, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/galleryimages/{galleryImageName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: galleryImageName, var: gallery_image_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, gallery_image_name: $gallery_image_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get regional availability information for each size category configured under a lab account
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/getRegionalAvailability
# Returns: record<regionalAvailability: table<region: string, sizeAvailabilities: list>>
# operationId: LabAccounts_GetRegionalAvailability
export def "lab-accounts-get-regional-availability" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/getRegionalAvailability"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List labs in a given lab account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Labs_List
export def "labs-list" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=maxUsersInLab)'
  --filter: string # The filter to apply to the operation.
  --top: int # The maximum number of resources to return from the operation. (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation.
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete lab. This operation can take a while to complete
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}
# operationId: Labs_Delete
export def "labs-delete" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get lab
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}
# Returns: record<properties: record<createdByObjectId: string, createdByUserPrincipalName: string, createdDate: string, invitationCode: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, maxUsersInLab: int, provisioningState: string, uniqueIdentifier: string, usageQuota: string, userAccessMode: string, userQuota: int>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Labs_Get
export def "labs-get" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=maxUsersInLab)'
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify properties of labs.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}
# Returns: record<properties: record<createdByObjectId: string, createdByUserPrincipalName: string, createdDate: string, invitationCode: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, maxUsersInLab: int, provisioningState: string, uniqueIdentifier: string, usageQuota: string, userAccessMode: string, userQuota: int>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Labs_Update
export def "labs-update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  --properties: record # Properties of a Lab. — shape: {maxUsersInLab?: int, provisioningState?: string, uniqueIdentifier?: string, usageQuota?: string, userAccessMode?: "Restricted"|"Open"}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing Lab.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}
# Returns: record<properties: record<createdByObjectId: string, createdByUserPrincipalName: string, createdDate: string, invitationCode: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, maxUsersInLab: int, provisioningState: string, uniqueIdentifier: string, usageQuota: string, userAccessMode: string, userQuota: int>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Labs_CreateOrUpdate
export def "labs-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  --properties: record # Properties of a Lab. — shape: {latestOperationResult?: record, maxUsersInLab?: int, provisioningState?: string, uniqueIdentifier?: string, usageQuota?: string, userAccessMode?: "Restricted"|"Open"}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add users to a lab
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/addUsers
# operationId: Labs_AddUsers
export def "labs-add-users" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  email_addresses: list<string> # List of user emails addresses to add to the lab.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/addUsers"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: emailAddresses, var: email_addresses}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, api_version: $api_version, email_addresses: $email_addresses
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List environment setting in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: EnvironmentSettings_List
export def "environment-settings-list" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=publishingState)'
  --filter: string # The filter to apply to the operation.
  --top: int # The maximum number of resources to return from the operation. (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation.
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete environment setting. This operation can take a while to complete
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}
# operationId: EnvironmentSettings_Delete
export def "environment-settings-delete" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: environmentSettingName, var: environment_setting_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, environment_setting_name: $environment_setting_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get environment setting
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}
# Returns: record<properties: record<configurationState: string, description: string, lastChanged: string, lastPublished: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, publishingState: string, resourceSettings: record<cores: int, galleryImageResourceId: string, id: string, imageName: string, referenceVm: record, size: string>, title: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: EnvironmentSettings_Get
export def "environment-settings-get" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=publishingState)'
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: environmentSettingName, var: environment_setting_name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, environment_setting_name: $environment_setting_name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify properties of environment setting.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}
# Returns: record<properties: record<configurationState: string, description: string, lastChanged: string, lastPublished: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, publishingState: string, resourceSettings: record<cores: int, galleryImageResourceId: string, id: string, imageName: string, referenceVm: record, size: string>, title: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: EnvironmentSettings_Update
export def "environment-settings-update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  --properties: record # Properties of an environment setting — shape: {configurationState?: "NotApplicable"|"Completed", description?: string, provisioningState?: string, resourceSettings?: record, title?: string, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: environmentSettingName, var: environment_setting_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, environment_setting_name: $environment_setting_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing Environment Setting. This operation can take a while to complete
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}
# Returns: record<properties: record<configurationState: string, description: string, lastChanged: string, lastPublished: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, publishingState: string, resourceSettings: record<cores: int, galleryImageResourceId: string, id: string, imageName: string, referenceVm: record, size: string>, title: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: EnvironmentSettings_CreateOrUpdate
export def "environment-settings-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  --properties: record # Properties of an environment setting — shape: {configurationState?: "NotApplicable"|"Completed", description?: string, latestOperationResult?: record, provisioningState?: string, resourceSettings: record, title?: string, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: environmentSettingName, var: environment_setting_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, environment_setting_name: $environment_setting_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Claims a random environment for a user in an environment settings
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/claimAny
# operationId: EnvironmentSettings_ClaimAny
export def "environment-settings-claim-any" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/claimAny"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: environmentSettingName, var: environment_setting_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, environment_setting_name: $environment_setting_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List environments in a given environment setting.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Environments_List
export def "environments-list" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=networkInterface)'
  --filter: string # The filter to apply to the operation.
  --top: int # The maximum number of resources to return from the operation. (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation.
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: environmentSettingName, var: environment_setting_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, environment_setting_name: $environment_setting_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete environment. This operation can take a while to complete
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}
# operationId: Environments_Delete
export def "environments-delete" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: environmentSettingName, var: environment_setting_name}, {name: environmentName, var: environment_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, environment_setting_name: $environment_setting_name, environment_name: $environment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get environment
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}
# Returns: record<properties: record<claimedByUserName: string, claimedByUserObjectId: string, claimedByUserPrincipalId: string, isClaimed: bool, lastKnownPowerState: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, networkInterface: record<privateIpAddress: string, rdpAuthority: string, sshAuthority: string, username: string>, passwordLastReset: string, provisioningState: string, resourceSets: record<resourceSettingId: string, vmResourceId: string>, totalUsage: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Environments_Get
export def "environments-get" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=networkInterface)'
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: environmentSettingName, var: environment_setting_name}, {name: environmentName, var: environment_name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, environment_setting_name: $environment_setting_name, environment_name: $environment_name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify properties of environments.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}
# Returns: record<properties: record<claimedByUserName: string, claimedByUserObjectId: string, claimedByUserPrincipalId: string, isClaimed: bool, lastKnownPowerState: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, networkInterface: record<privateIpAddress: string, rdpAuthority: string, sshAuthority: string, username: string>, passwordLastReset: string, provisioningState: string, resourceSets: record<resourceSettingId: string, vmResourceId: string>, totalUsage: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Environments_Update
export def "environments-update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  --properties: record # Properties of an environment — shape: {provisioningState?: string, resourceSets?: record, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: environmentSettingName, var: environment_setting_name}, {name: environmentName, var: environment_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, environment_setting_name: $environment_setting_name, environment_name: $environment_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing Environment.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}
# Returns: record<properties: record<claimedByUserName: string, claimedByUserObjectId: string, claimedByUserPrincipalId: string, isClaimed: bool, lastKnownPowerState: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, networkInterface: record<privateIpAddress: string, rdpAuthority: string, sshAuthority: string, username: string>, passwordLastReset: string, provisioningState: string, resourceSets: record<resourceSettingId: string, vmResourceId: string>, totalUsage: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Environments_CreateOrUpdate
export def "environments-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  --properties: record # Properties of an environment — shape: {latestOperationResult?: record, networkInterface?: record, provisioningState?: string, resourceSets?: record, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: environmentSettingName, var: environment_setting_name}, {name: environmentName, var: environment_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, environment_setting_name: $environment_setting_name, environment_name: $environment_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Claims the environment and assigns it to the user
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}/claim
# operationId: Environments_Claim
export def "environments-claim" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}/claim"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: environmentSettingName, var: environment_setting_name}, {name: environmentName, var: environment_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, environment_setting_name: $environment_setting_name, environment_name: $environment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resets the user password on an environment This operation can take a while to complete
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}/resetPassword
# operationId: Environments_ResetPassword
export def "environments-reset-password" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  environment_id: string # The resourceId of the environment
  --password: string # The password to assign to the user specified in
  --username: string # The username for which the password will be reset.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}/resetPassword"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: environmentSettingName, var: environment_setting_name}, {name: environmentName, var: environment_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentId, var: environment_id}, {name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, environment_setting_name: $environment_setting_name, environment_name: $environment_name, api_version: $api_version, environment_id: $environment_id, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an environment by starting all resources inside the environment. This operation can take a while to complete
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}/start
# operationId: Environments_Start
export def "environments-start" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}/start"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: environmentSettingName, var: environment_setting_name}, {name: environmentName, var: environment_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, environment_setting_name: $environment_setting_name, environment_name: $environment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops an environment by stopping all resources inside the environment This operation can take a while to complete
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}/stop
# operationId: Environments_Stop
export def "environments-stop" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/environments/{environmentName}/stop"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: environmentSettingName, var: environment_setting_name}, {name: environmentName, var: environment_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, environment_setting_name: $environment_setting_name, environment_name: $environment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provisions/deprovisions required resources for an environment setting based on current state of the lab/environment setting.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/publish
# operationId: EnvironmentSettings_Publish
export def "environment-settings-publish" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  --use-existing-image: oneof<nothing, bool> # Whether to use existing VM custom image when publishing.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/publish"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: environmentSettingName, var: environment_setting_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: useExistingImage, var: use_existing_image}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, environment_setting_name: $environment_setting_name, api_version: $api_version, use_existing_image: $use_existing_image
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a template by starting all resources inside the template. This operation can take a while to complete
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/start
# operationId: EnvironmentSettings_Start
export def "environment-settings-start" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/start"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: environmentSettingName, var: environment_setting_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, environment_setting_name: $environment_setting_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a template by starting all resources inside the template. This operation can take a while to complete
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/stop
# operationId: EnvironmentSettings_Stop
export def "environment-settings-stop" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  environment_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/environmentsettings/{environmentSettingName}/stop"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: environmentSettingName, var: environment_setting_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, environment_setting_name: $environment_setting_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register to managed lab.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/register
# operationId: Labs_Register
export def "labs-register" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/register"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List users in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Users_List
export def "users-list" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=email)'
  --filter: string # The filter to apply to the operation.
  --top: int # The maximum number of resources to return from the operation. (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation.
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}]
    query: [{name: "$expand", var: expand}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$orderby", var: orderby}, {name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, expand: $expand, filter: $filter, top: $top, orderby: $orderby, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete user. This operation can take a while to complete
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users/{userName}
# operationId: Users_Delete
export def "users-delete" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users/{userName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, user_name: $user_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users/{userName}
# Returns: record<properties: record<email: string, familyName: string, givenName: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, tenantId: string, totalUsage: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Users_Get
export def "users-get" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=email)'
  --api-version: string # Client API version. (required, default: 2018-10-15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users/{userName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, user_name: $user_name, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify properties of users.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users/{userName}
# Returns: record<properties: record<email: string, familyName: string, givenName: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, tenantId: string, totalUsage: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Users_Update
export def "users-update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  --properties: record # Lab User properties — shape: {provisioningState?: string, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users/{userName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, user_name: $user_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or replace an existing User.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users/{userName}
# Returns: record<properties: record<email: string, familyName: string, givenName: string, latestOperationResult: record<errorCode: string, errorMessage: string, httpMethod: string, operationUrl: string, requestUri: string, status: string>, provisioningState: string, tenantId: string, totalUsage: string, uniqueIdentifier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Users_CreateOrUpdate
export def "users-create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_account_name: string
  lab_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required, default: 2018-10-15)
  --properties: record # Lab User properties — shape: {latestOperationResult?: record, provisioningState?: string, uniqueIdentifier?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.LabServices/labaccounts/{labAccountName}/labs/{labName}/users/{userName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: labAccountName, var: lab_account_name}, {name: labName, var: lab_name}, {name: userName, var: user_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2018-10-15"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, lab_account_name: $lab_account_name, lab_name: $lab_name, user_name: $user_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
