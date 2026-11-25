# Auto-generated client for ApiManagementClient v2019-12-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/apimanagement-apimapis/2019-12-01-preview/swagger.json
# Auth: --token flag or $env.APIMANAGEMENTCLIENT_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "APIMANAGEMENTCLIENT_TOKEN"
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
def accept-completer [] { ["application/json" "application/vnd.oai.openapi" "application/vnd.oai.openapi+json" "application/vnd.sun.wadl+xml" "application/vnd.swagger.doc+json" "application/wsdl+xml"] }
def policy-id-completer [] { ["policy"] }
def format-completer [] { ["rawxml" "xml"] }
def accept-completer-1 [] { ["application/json" "application/vnd.ms-azure-apim.policy+xml" "application/vnd.ms-azure-apim.policy.raw+xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    api-list-by-service: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    api-get: "record<properties: record<apiVersionSet: record<description: string, id: string, name: string, versionHeaderName: string, versionQueryName: string, versioningScheme: string>, displayName: string, path: string, protocols: list<string>, serviceUrl: string, sourceApiId: string, apiRevision: string, apiRevisionDescription: string, apiVersion: string, apiVersionDescription: string, apiVersionSetId: string, authenticationSettings: record<oAuth2: record, openid: record>, description: string, isCurrent: bool, isOnline: bool, subscriptionKeyParameterNames: record<header: string, query: string>, subscriptionRequired: bool, type: string>, id: string, name: string, type: string>"
    api-get-entity-tag: "record"
    api-create-or-update: "record<properties: record<apiVersionSet: record<description: string, id: string, name: string, versionHeaderName: string, versionQueryName: string, versioningScheme: string>, displayName: string, path: string, protocols: list<string>, serviceUrl: string, sourceApiId: string, apiRevision: string, apiRevisionDescription: string, apiVersion: string, apiVersionDescription: string, apiVersionSetId: string, authenticationSettings: record<oAuth2: record, openid: record>, description: string, isCurrent: bool, isOnline: bool, subscriptionKeyParameterNames: record<header: string, query: string>, subscriptionRequired: bool, type: string>, id: string, name: string, type: string>"
    api-diagnostic-list-by-service: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    api-diagnostic-get: "record<properties: record<alwaysLog: string, backend: record<request: record, response: record>, frontend: record<request: record, response: record>, httpCorrelationProtocol: string, logClientIp: bool, loggerId: string, sampling: record<percentage: float, samplingType: string>, verbosity: string>, id: string, name: string, type: string>"
    api-diagnostic-get-entity-tag: "record"
    api-diagnostic-create-or-update: "record<properties: record<alwaysLog: string, backend: record<request: record, response: record>, frontend: record<request: record, response: record>, httpCorrelationProtocol: string, logClientIp: bool, loggerId: string, sampling: record<percentage: float, samplingType: string>, verbosity: string>, id: string, name: string, type: string>"
    api-issue-list-by-service: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    api-issue-get: "record<properties: record<description: string, title: string, userId: string, apiId: string, createdDate: string, state: string>, id: string, name: string, type: string>"
    api-issue-get-entity-tag: "record"
    api-issue-create-or-update: "record<properties: record<description: string, title: string, userId: string, apiId: string, createdDate: string, state: string>, id: string, name: string, type: string>"
    api-issue-attachment-list-by-service: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    api-issue-attachment-get: "record<properties: record<content: string, contentFormat: string, title: string>, id: string, name: string, type: string>"
    api-issue-attachment-get-entity-tag: "record"
    api-issue-attachment-create-or-update: "record<properties: record<content: string, contentFormat: string, title: string>, id: string, name: string, type: string>"
    api-issue-comment-list-by-service: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    api-issue-comment-get: "record<properties: record<createdDate: string, text: string, userId: string>, id: string, name: string, type: string>"
    api-issue-comment-get-entity-tag: "record"
    api-issue-comment-create-or-update: "record<properties: record<createdDate: string, text: string, userId: string>, id: string, name: string, type: string>"
    api-operation-list-by-api: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    api-operation-get: "record<properties: record<displayName: string, method: string, urlTemplate: string, description: string, policies: string, request: record<description: string, headers: list, queryParameters: list, representations: list>, responses: list<record>, templateParameters: list<record>>, id: string, name: string, type: string>"
    api-operation-get-entity-tag: "record"
    api-operation-create-or-update: "record<properties: record<displayName: string, method: string, urlTemplate: string, description: string, policies: string, request: record<description: string, headers: list, queryParameters: list, representations: list>, responses: list<record>, templateParameters: list<record>>, id: string, name: string, type: string>"
    api-operation-policy-list-by-operation: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    api-operation-policy-get: "record<properties: record<format: string, value: string>, id: string, name: string, type: string>"
    api-operation-policy-get-entity-tag: "record"
    api-operation-policy-create-or-update: "record<properties: record<format: string, value: string>, id: string, name: string, type: string>"
    tag-list-by-operation: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    tag-get-by-operation: "record<properties: record<displayName: string>, id: string, name: string, type: string>"
    tag-get-entity-state-by-operation: "record"
    tag-assign-to-operation: "record<properties: record<displayName: string>, id: string, name: string, type: string>"
    operation-list-by-tags: "record<nextLink: string, value: table<api: record, operation: record, product: record, tag: record>>"
    api-policy-list-by-api: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    api-policy-get: "record<properties: record<format: string, value: string>, id: string, name: string, type: string>"
    api-policy-get-entity-tag: "record"
    api-policy-create-or-update: "record<properties: record<format: string, value: string>, id: string, name: string, type: string>"
    api-product-list-by-apis: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    api-release-list-by-service: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    api-release-get: "record<properties: record<apiId: string, createdDateTime: string, notes: string, updatedDateTime: string>, id: string, name: string, type: string>"
    api-release-get-entity-tag: "record"
    api-release-create-or-update: "record<properties: record<apiId: string, createdDateTime: string, notes: string, updatedDateTime: string>, id: string, name: string, type: string>"
    api-revision-list-by-service: "record<nextLink: string, value: table<apiId: string, apiRevision: string, createdDateTime: string, description: string, isCurrent: bool, isOnline: bool, privateUrl: string, updatedDateTime: string>>"
    api-schema-list-by-api: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    api-schema-get: "record<properties: record<contentType: string, document: record<definitions: record, value: string>>, id: string, name: string, type: string>"
    api-schema-get-entity-tag: "record"
    api-schema-create-or-update: "record<properties: record<contentType: string, document: record<definitions: record, value: string>>, id: string, name: string, type: string>"
    api-tag-description-list-by-service: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    api-tag-description-get: "record<properties: record<displayName: string, tagId: string, description: string, externalDocsDescription: string, externalDocsUrl: string>, id: string, name: string, type: string>"
    api-tag-description-get-entity-tag: "record"
    api-tag-description-create-or-update: "record<properties: record<displayName: string, tagId: string, description: string, externalDocsDescription: string, externalDocsUrl: string>, id: string, name: string, type: string>"
    tag-list-by-api: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    tag-get-by-api: "record<properties: record<displayName: string>, id: string, name: string, type: string>"
    tag-get-entity-state-by-api: "record"
    tag-assign-to-api: "record<properties: record<displayName: string>, id: string, name: string, type: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["api-list-by-service" "api-delete" "api-get" "api-get-entity-tag" "api-update" "api-create-or-update" "api-diagnostic-list-by-service" "api-diagnostic-delete" "api-diagnostic-get" "api-diagnostic-get-entity-tag" "api-diagnostic-update" "api-diagnostic-create-or-update" "api-issue-list-by-service" "api-issue-delete" "api-issue-get" "api-issue-get-entity-tag" "api-issue-update" "api-issue-create-or-update" "api-issue-attachment-list-by-service" "api-issue-attachment-delete" "api-issue-attachment-get" "api-issue-attachment-get-entity-tag" "api-issue-attachment-create-or-update" "api-issue-comment-list-by-service" "api-issue-comment-delete" "api-issue-comment-get" "api-issue-comment-get-entity-tag" "api-issue-comment-create-or-update" "api-operation-list-by-api" "api-operation-delete" "api-operation-get" "api-operation-get-entity-tag" "api-operation-update" "api-operation-create-or-update" "api-operation-policy-list-by-operation" "api-operation-policy-delete" "api-operation-policy-get" "api-operation-policy-get-entity-tag" "api-operation-policy-create-or-update" "tag-list-by-operation" "tag-detach-from-operation" "tag-get-by-operation" "tag-get-entity-state-by-operation" "tag-assign-to-operation" "operation-list-by-tags" "api-policy-list-by-api" "api-policy-delete" "api-policy-get" "api-policy-get-entity-tag" "api-policy-create-or-update" "api-product-list-by-apis" "api-release-list-by-service" "api-release-delete" "api-release-get" "api-release-get-entity-tag" "api-release-update" "api-release-create-or-update" "api-revision-list-by-service" "api-schema-list-by-api" "api-schema-delete" "api-schema-get" "api-schema-get-entity-tag" "api-schema-create-or-update" "api-tag-description-list-by-service" "api-tag-description-delete" "api-tag-description-get" "api-tag-description-get-entity-tag" "api-tag-description-create-or-update" "tag-list-by-api" "tag-detach-from-api" "tag-get-by-api" "tag-get-entity-state-by-api" "tag-assign-to-api" "commands"] | sort) } | get name | first)
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

# Lists all APIs of the API Management service instance.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis
# Docs: https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-create-apis
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Api_ListByService
export def "api-list-by-service" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| name | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | displayName | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | description | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | serviceUrl | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | path | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --tags: string # Include tags in the response.
  --expand-api-version-set: oneof<nothing, bool> # Include full ApiVersionSet resource in response
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$skip", var: skip}, {name: tags, var: tags}, {name: expandApiVersionSet, var: expand_api_version_set}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, filter: $filter, top: $top, skip: $skip, tags: $tags, expand_api_version_set: $expand_api_version_set, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified API of the API Management service instance.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}
# operationId: Api_Delete
export def "api-delete" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-revisions: oneof<nothing, bool> # Delete all revisions of the Api.
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}]
    query: [{name: deleteRevisions, var: delete_revisions}, {name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, delete_revisions: $delete_revisions, api_version: $api_version, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of the API specified by its identifier.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}
# Returns: record<properties: record<apiVersionSet: record<description: string, id: string, name: string, versionHeaderName: string, versionQueryName: string, versioningScheme: string>, displayName: string, path: string, protocols: list<string>, serviceUrl: string, sourceApiId: string, apiRevision: string, apiRevisionDescription: string, apiVersion: string, apiVersionDescription: string, apiVersionSetId: string, authenticationSettings: record<oAuth2: record, openid: record>, description: string, isCurrent: bool, isOnline: bool, subscriptionKeyParameterNames: record<header: string, query: string>, subscriptionRequired: bool, type: string>, id: string, name: string, type: string>
# operationId: Api_Get
export def "api-get" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
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
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "application/vnd.sun.wadl+xml", "application/vnd.swagger.doc+json", "application/wsdl+xml", "application/vnd.oai.openapi", "application/vnd.oai.openapi+json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the entity state (Etag) version of the API specified by its identifier.
#
# HEAD /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}
# Returns: record
# operationId: Api_GetEntityTag
export def "api-get-entity-tag" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified API of the API Management service instance.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}
# operationId: Api_Update
export def "api-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update. (required)
  --properties: any # API update contract properties. — shape: {displayName?: string, path?: string, protocols?: list<string>, serviceUrl?: string, apiRevision?: string, apiRevisionDescription?: string, apiVersion?: string, apiVersionDescription?: string, apiVersionSetId?: string, authenticationSettings?: any, description?: string, isCurrent?: bool, subscriptionKeyParameterNames?: any, subscriptionRequired?: bool, type?: "http"|"soap"}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, api_version: $api_version, if_match: $if_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates new or updates existing specified API of the API Management service instance.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}
# Returns: record<properties: record<apiVersionSet: record<description: string, id: string, name: string, versionHeaderName: string, versionQueryName: string, versioningScheme: string>, displayName: string, path: string, protocols: list<string>, serviceUrl: string, sourceApiId: string, apiRevision: string, apiRevisionDescription: string, apiVersion: string, apiVersionDescription: string, apiVersionSetId: string, authenticationSettings: record<oAuth2: record, openid: record>, description: string, isCurrent: bool, isOnline: bool, subscriptionKeyParameterNames: record<header: string, query: string>, subscriptionRequired: bool, type: string>, id: string, name: string, type: string>
# operationId: Api_CreateOrUpdate
export def "api-create-or-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. Not required when creating an entity, but required when updating an entity.
  --properties: any # Api Create or Update Properties. — shape: {apiType?: "http"|"soap", format?: "wadl-xml"|"wadl-link-json"|"swagger-json"|"swagger-link-json"|"wsdl"|"wsdl-link"|"openapi"|"openapi+json"|"openapi-link"|"openapi+json-link", value?: string, wsdlSelector?: record, apiVersionSet?: any, displayName?: string, path: string, protocols?: list<string>, serviceUrl?: string, sourceApiId?: string, apiRevision?: string, apiRevisionDescription?: string, apiVersion?: string, apiVersionDescription?: string, apiVersionSetId?: string, ... (6 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, api_version: $api_version, if_match: $if_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all diagnostics of an API.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/diagnostics
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: ApiDiagnostic_ListByService
export def "api-diagnostic-list-by-service" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| name | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/diagnostics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$skip", var: skip}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, filter: $filter, top: $top, skip: $skip, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified Diagnostic from an API.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/diagnostics/{diagnosticId}
# operationId: ApiDiagnostic_Delete
export def "api-diagnostic-delete" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  diagnostic_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/diagnostics/{diagnosticId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: diagnosticId, var: diagnostic_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, diagnostic_id: $diagnostic_id, api_version: $api_version, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of the Diagnostic for an API specified by its identifier.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/diagnostics/{diagnosticId}
# Returns: record<properties: record<alwaysLog: string, backend: record<request: record, response: record>, frontend: record<request: record, response: record>, httpCorrelationProtocol: string, logClientIp: bool, loggerId: string, sampling: record<percentage: float, samplingType: string>, verbosity: string>, id: string, name: string, type: string>
# operationId: ApiDiagnostic_Get
export def "api-diagnostic-get" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  diagnostic_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/diagnostics/{diagnosticId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: diagnosticId, var: diagnostic_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, diagnostic_id: $diagnostic_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the entity state (Etag) version of the Diagnostic for an API specified by its identifier.
#
# HEAD /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/diagnostics/{diagnosticId}
# Returns: record
# operationId: ApiDiagnostic_GetEntityTag
export def "api-diagnostic-get-entity-tag" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  diagnostic_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/diagnostics/{diagnosticId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: diagnosticId, var: diagnostic_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, diagnostic_id: $diagnostic_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the details of the Diagnostic for an API specified by its identifier.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/diagnostics/{diagnosticId}
# operationId: ApiDiagnostic_Update
export def "api-diagnostic-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  diagnostic_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update. (required)
  --properties: any # Diagnostic Entity Properties — shape: {alwaysLog?: "allErrors", backend?: any, frontend?: any, httpCorrelationProtocol?: "None"|"Legacy"|"W3C", logClientIp?: bool, loggerId: string, sampling?: any, verbosity?: "verbose"|"information"|"error"}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/diagnostics/{diagnosticId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: diagnosticId, var: diagnostic_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, diagnostic_id: $diagnostic_id, api_version: $api_version, if_match: $if_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Diagnostic for an API or updates an existing one.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/diagnostics/{diagnosticId}
# Returns: record<properties: record<alwaysLog: string, backend: record<request: record, response: record>, frontend: record<request: record, response: record>, httpCorrelationProtocol: string, logClientIp: bool, loggerId: string, sampling: record<percentage: float, samplingType: string>, verbosity: string>, id: string, name: string, type: string>
# operationId: ApiDiagnostic_CreateOrUpdate
export def "api-diagnostic-create-or-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  diagnostic_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. Not required when creating an entity, but required when updating an entity.
  --properties: any # Diagnostic Entity Properties — shape: {alwaysLog?: "allErrors", backend?: any, frontend?: any, httpCorrelationProtocol?: "None"|"Legacy"|"W3C", logClientIp?: bool, loggerId: string, sampling?: any, verbosity?: "verbose"|"information"|"error"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/diagnostics/{diagnosticId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: diagnosticId, var: diagnostic_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, diagnostic_id: $diagnostic_id, api_version: $api_version, if_match: $if_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all issues associated with the specified API.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: ApiIssue_ListByService
export def "api-issue-list-by-service" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| name | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | userId | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | state | filter | eq | |
  --expand-comments-attachments: oneof<nothing, bool> # Expand the comment attachments.
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}]
    query: [{name: "$filter", var: filter}, {name: expandCommentsAttachments, var: expand_comments_attachments}, {name: "$top", var: top}, {name: "$skip", var: skip}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, filter: $filter, expand_comments_attachments: $expand_comments_attachments, top: $top, skip: $skip, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified Issue from an API.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}
# operationId: ApiIssue_Delete
export def "api-issue-delete" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: issueId, var: issue_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, issue_id: $issue_id, api_version: $api_version, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of the Issue for an API specified by its identifier.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}
# Returns: record<properties: record<description: string, title: string, userId: string, apiId: string, createdDate: string, state: string>, id: string, name: string, type: string>
# operationId: ApiIssue_Get
export def "api-issue-get" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand-comments-attachments: oneof<nothing, bool> # Expand the comment attachments.
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: issueId, var: issue_id}]
    query: [{name: expandCommentsAttachments, var: expand_comments_attachments}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, issue_id: $issue_id, expand_comments_attachments: $expand_comments_attachments, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the entity state (Etag) version of the Issue for an API specified by its identifier.
#
# HEAD /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}
# Returns: record
# operationId: ApiIssue_GetEntityTag
export def "api-issue-get-entity-tag" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: issueId, var: issue_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, issue_id: $issue_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing issue for an API.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}
# operationId: ApiIssue_Update
export def "api-issue-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update. (required)
  --properties: any # Issue contract Update Properties. — shape: {description?: string, title?: string, userId?: string, apiId?: string, createdDate?: string, state?: "proposed"|"open"|"removed"|"resolved"|"closed"}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: issueId, var: issue_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, issue_id: $issue_id, api_version: $api_version, if_match: $if_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Issue for an API or updates an existing one.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}
# Returns: record<properties: record<description: string, title: string, userId: string, apiId: string, createdDate: string, state: string>, id: string, name: string, type: string>
# operationId: ApiIssue_CreateOrUpdate
export def "api-issue-create-or-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. Not required when creating an entity, but required when updating an entity.
  --properties: any # Issue contract Properties. — shape: {description: string, title: string, userId: string, apiId?: string, createdDate?: string, state?: "proposed"|"open"|"removed"|"resolved"|"closed"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: issueId, var: issue_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, issue_id: $issue_id, api_version: $api_version, if_match: $if_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all attachments for the Issue associated with the specified API.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/attachments
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: ApiIssueAttachment_ListByService
export def "api-issue-attachment-list-by-service" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| name | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | userId | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/attachments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: issueId, var: issue_id}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$skip", var: skip}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, issue_id: $issue_id, filter: $filter, top: $top, skip: $skip, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified comment from an Issue.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/attachments/{attachmentId}
# operationId: ApiIssueAttachment_Delete
export def "api-issue-attachment-delete" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  issue_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/attachments/{attachmentId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: issueId, var: issue_id}, {name: attachmentId, var: attachment_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, issue_id: $issue_id, attachment_id: $attachment_id, api_version: $api_version, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of the issue Attachment for an API specified by its identifier.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/attachments/{attachmentId}
# Returns: record<properties: record<content: string, contentFormat: string, title: string>, id: string, name: string, type: string>
# operationId: ApiIssueAttachment_Get
export def "api-issue-attachment-get" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  issue_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/attachments/{attachmentId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: issueId, var: issue_id}, {name: attachmentId, var: attachment_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, issue_id: $issue_id, attachment_id: $attachment_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the entity state (Etag) version of the issue Attachment for an API specified by its identifier.
#
# HEAD /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/attachments/{attachmentId}
# Returns: record
# operationId: ApiIssueAttachment_GetEntityTag
export def "api-issue-attachment-get-entity-tag" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  issue_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/attachments/{attachmentId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: issueId, var: issue_id}, {name: attachmentId, var: attachment_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, issue_id: $issue_id, attachment_id: $attachment_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Attachment for the Issue in an API or updates an existing one.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/attachments/{attachmentId}
# Returns: record<properties: record<content: string, contentFormat: string, title: string>, id: string, name: string, type: string>
# operationId: ApiIssueAttachment_CreateOrUpdate
export def "api-issue-attachment-create-or-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  issue_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. Not required when creating an entity, but required when updating an entity.
  --properties: any # Issue Attachment contract Properties. — shape: {content: string, contentFormat: string, title: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/attachments/{attachmentId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: issueId, var: issue_id}, {name: attachmentId, var: attachment_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, issue_id: $issue_id, attachment_id: $attachment_id, api_version: $api_version, if_match: $if_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all comments for the Issue associated with the specified API.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/comments
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: ApiIssueComment_ListByService
export def "api-issue-comment-list-by-service" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| name | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | userId | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/comments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: issueId, var: issue_id}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$skip", var: skip}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, issue_id: $issue_id, filter: $filter, top: $top, skip: $skip, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified comment from an Issue.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/comments/{commentId}
# operationId: ApiIssueComment_Delete
export def "api-issue-comment-delete" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  issue_id: string
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/comments/{commentId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: issueId, var: issue_id}, {name: commentId, var: comment_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, issue_id: $issue_id, comment_id: $comment_id, api_version: $api_version, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of the issue Comment for an API specified by its identifier.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/comments/{commentId}
# Returns: record<properties: record<createdDate: string, text: string, userId: string>, id: string, name: string, type: string>
# operationId: ApiIssueComment_Get
export def "api-issue-comment-get" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  issue_id: string
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/comments/{commentId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: issueId, var: issue_id}, {name: commentId, var: comment_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, issue_id: $issue_id, comment_id: $comment_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the entity state (Etag) version of the issue Comment for an API specified by its identifier.
#
# HEAD /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/comments/{commentId}
# Returns: record
# operationId: ApiIssueComment_GetEntityTag
export def "api-issue-comment-get-entity-tag" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  issue_id: string
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/comments/{commentId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: issueId, var: issue_id}, {name: commentId, var: comment_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, issue_id: $issue_id, comment_id: $comment_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Comment for the Issue in an API or updates an existing one.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/comments/{commentId}
# Returns: record<properties: record<createdDate: string, text: string, userId: string>, id: string, name: string, type: string>
# operationId: ApiIssueComment_CreateOrUpdate
export def "api-issue-comment-create-or-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  issue_id: string
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. Not required when creating an entity, but required when updating an entity.
  --properties: any # Issue Comment contract Properties. — shape: {createdDate?: string, text: string, userId: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/issues/{issueId}/comments/{commentId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: issueId, var: issue_id}, {name: commentId, var: comment_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, issue_id: $issue_id, comment_id: $comment_id, api_version: $api_version, if_match: $if_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists a collection of the operations for the specified API.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: ApiOperation_ListByApi
export def "api-operation-list-by-api" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| name | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | displayName | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | method | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | description | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | urlTemplate | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --tags: string # Include tags in the response.
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$skip", var: skip}, {name: tags, var: tags}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, filter: $filter, top: $top, skip: $skip, tags: $tags, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified operation in the API.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}
# operationId: ApiOperation_Delete
export def "api-operation-delete" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, operation_id: $operation_id, api_version: $api_version, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of the API Operation specified by its identifier.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}
# Returns: record<properties: record<displayName: string, method: string, urlTemplate: string, description: string, policies: string, request: record<description: string, headers: list, queryParameters: list, representations: list>, responses: list<record>, templateParameters: list<record>>, id: string, name: string, type: string>
# operationId: ApiOperation_Get
export def "api-operation-get" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the entity state (Etag) version of the API operation specified by its identifier.
#
# HEAD /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}
# Returns: record
# operationId: ApiOperation_GetEntityTag
export def "api-operation-get-entity-tag" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the details of the operation in the API specified by its identifier.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}
# operationId: ApiOperation_Update
export def "api-operation-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update. (required)
  --properties: any # Operation Update Contract Properties. — shape: {displayName?: string, method?: string, urlTemplate?: string, description?: string, policies?: string, request?: any, responses?: list, templateParameters?: list}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, operation_id: $operation_id, api_version: $api_version, if_match: $if_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new operation in the API or updates an existing one.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}
# Returns: record<properties: record<displayName: string, method: string, urlTemplate: string, description: string, policies: string, request: record<description: string, headers: list, queryParameters: list, representations: list>, responses: list<record>, templateParameters: list<record>>, id: string, name: string, type: string>
# operationId: ApiOperation_CreateOrUpdate
export def "api-operation-create-or-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. Not required when creating an entity, but required when updating an entity.
  --properties: any # Operation Contract Properties — shape: {displayName: string, method: string, urlTemplate: string, description?: string, policies?: string, request?: any, responses?: list, templateParameters?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, operation_id: $operation_id, api_version: $api_version, if_match: $if_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of policy configuration at the API Operation level.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/policies
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: ApiOperationPolicy_ListByOperation
export def "api-operation-policy-list-by-operation" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/policies"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the policy configuration at the Api Operation.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/policies/{policyId}
# operationId: ApiOperationPolicy_Delete
export def "api-operation-policy-delete" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  operation_id: string
  policy_id: string@policy-id-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/policies/{policyId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: operationId, var: operation_id}, {name: policyId, var: policy_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, operation_id: $operation_id, policy_id: $policy_id, api_version: $api_version, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the policy configuration at the API Operation level.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/policies/{policyId}
# Returns: record<properties: record<format: string, value: string>, id: string, name: string, type: string>
# operationId: ApiOperationPolicy_Get
export def "api-operation-policy-get" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  operation_id: string
  policy_id: string@policy-id-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # Policy Export Format. (default: xml)
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/policies/{policyId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: operationId, var: operation_id}, {name: policyId, var: policy_id}]
    query: [{name: format, var: format}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, operation_id: $operation_id, policy_id: $policy_id, format: $format, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the entity state (Etag) version of the API operation policy specified by its identifier.
#
# HEAD /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/policies/{policyId}
# Returns: record
# operationId: ApiOperationPolicy_GetEntityTag
export def "api-operation-policy-get-entity-tag" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  operation_id: string
  policy_id: string@policy-id-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/policies/{policyId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: operationId, var: operation_id}, {name: policyId, var: policy_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, operation_id: $operation_id, policy_id: $policy_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates policy configuration for the API Operation level.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/policies/{policyId}
# Returns: record<properties: record<format: string, value: string>, id: string, name: string, type: string>
# operationId: ApiOperationPolicy_CreateOrUpdate
export def "api-operation-policy-create-or-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  operation_id: string
  policy_id: string@policy-id-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. Not required when creating an entity, but required when updating an entity.
  --properties: any # Policy contract Properties. — shape: {format?: "xml"|"xml-link"|"rawxml"|"rawxml-link", value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/policies/{policyId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: operationId, var: operation_id}, {name: policyId, var: policy_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, operation_id: $operation_id, policy_id: $policy_id, api_version: $api_version, if_match: $if_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all Tags associated with the Operation.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/tags
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Tag_ListByOperation
export def "tag-list-by-operation" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| displayName | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | name | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/tags"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: operationId, var: operation_id}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$skip", var: skip}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, operation_id: $operation_id, filter: $filter, top: $top, skip: $skip, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detach the tag from the Operation.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/tags/{tagId}
# operationId: Tag_DetachFromOperation
export def "tag-detach-from-operation" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  operation_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/tags/{tagId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: operationId, var: operation_id}, {name: tagId, var: tag_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, operation_id: $operation_id, tag_id: $tag_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tag associated with the Operation.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/tags/{tagId}
# Returns: record<properties: record<displayName: string>, id: string, name: string, type: string>
# operationId: Tag_GetByOperation
export def "tag-get-by-operation" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  operation_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/tags/{tagId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: operationId, var: operation_id}, {name: tagId, var: tag_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, operation_id: $operation_id, tag_id: $tag_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the entity state version of the tag specified by its identifier.
#
# HEAD /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/tags/{tagId}
# Returns: record
# operationId: Tag_GetEntityStateByOperation
export def "tag-get-entity-state-by-operation" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  operation_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/tags/{tagId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: operationId, var: operation_id}, {name: tagId, var: tag_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, operation_id: $operation_id, tag_id: $tag_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign tag to the Operation.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/tags/{tagId}
# Returns: record<properties: record<displayName: string>, id: string, name: string, type: string>
# operationId: Tag_AssignToOperation
export def "tag-assign-to-operation" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  operation_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operations/{operationId}/tags/{tagId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: operationId, var: operation_id}, {name: tagId, var: tag_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, operation_id: $operation_id, tag_id: $tag_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists a collection of operations associated with tags.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operationsByTags
# Returns: record<nextLink: string, value: table<api: record, operation: record, product: record, tag: record>>
# operationId: Operation_ListByTags
export def "operation-list-by-tags" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| name | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | displayName | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | apiName | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | description | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | method | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | urlTemplate | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --include-not-tagged-operations: oneof<nothing, bool> # Include not tagged Operations.
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/operationsByTags"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$skip", var: skip}, {name: includeNotTaggedOperations, var: include_not_tagged_operations}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, filter: $filter, top: $top, skip: $skip, include_not_tagged_operations: $include_not_tagged_operations, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the policy configuration at the API level.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/policies
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: ApiPolicy_ListByApi
export def "api-policy-list-by-api" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/policies"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the policy configuration at the Api.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/policies/{policyId}
# operationId: ApiPolicy_Delete
export def "api-policy-delete" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  policy_id: string@policy-id-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/policies/{policyId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: policyId, var: policy_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, policy_id: $policy_id, api_version: $api_version, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the policy configuration at the API level.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/policies/{policyId}
# Returns: record<properties: record<format: string, value: string>, id: string, name: string, type: string>
# operationId: ApiPolicy_Get
export def "api-policy-get" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  policy_id: string@policy-id-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --format: string@format-completer # Policy Export Format. (default: xml)
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/policies/{policyId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: policyId, var: policy_id}]
    query: [{name: format, var: format}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "application/vnd.ms-azure-apim.policy+xml", "application/vnd.ms-azure-apim.policy.raw+xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, policy_id: $policy_id, format: $format, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the entity state (Etag) version of the API policy specified by its identifier.
#
# HEAD /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/policies/{policyId}
# Returns: record
# operationId: ApiPolicy_GetEntityTag
export def "api-policy-get-entity-tag" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  policy_id: string@policy-id-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/policies/{policyId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: policyId, var: policy_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, policy_id: $policy_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates policy configuration for the API.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/policies/{policyId}
# Returns: record<properties: record<format: string, value: string>, id: string, name: string, type: string>
# operationId: ApiPolicy_CreateOrUpdate
export def "api-policy-create-or-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  policy_id: string@policy-id-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. Not required when creating an entity, but required when updating an entity.
  --properties: any # Policy contract Properties. — shape: {format?: "xml"|"xml-link"|"rawxml"|"rawxml-link", value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/policies/{policyId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: policyId, var: policy_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, policy_id: $policy_id, api_version: $api_version, if_match: $if_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all Products, which the API is part of.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/products
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: ApiProduct_ListByApis
export def "api-product-list-by-apis" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| displayName | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/products"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$skip", var: skip}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, filter: $filter, top: $top, skip: $skip, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all releases of an API. An API release is created when making an API Revision current. Releases are also used to rollback to previous revisions. Results will be paged and can be constrained by the $top and $skip parameters.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/releases
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: ApiRelease_ListByService
export def "api-release-list-by-service" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| notes | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/releases"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$skip", var: skip}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, filter: $filter, top: $top, skip: $skip, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified release in the API.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/releases/{releaseId}
# operationId: ApiRelease_Delete
export def "api-release-delete" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  release_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/releases/{releaseId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: releaseId, var: release_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, release_id: $release_id, api_version: $api_version, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the details of an API release.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/releases/{releaseId}
# Returns: record<properties: record<apiId: string, createdDateTime: string, notes: string, updatedDateTime: string>, id: string, name: string, type: string>
# operationId: ApiRelease_Get
export def "api-release-get" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  release_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/releases/{releaseId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: releaseId, var: release_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, release_id: $release_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the etag of an API release.
#
# HEAD /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/releases/{releaseId}
# Returns: record
# operationId: ApiRelease_GetEntityTag
export def "api-release-get-entity-tag" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  release_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/releases/{releaseId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: releaseId, var: release_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, release_id: $release_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the details of the release of the API specified by its identifier.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/releases/{releaseId}
# operationId: ApiRelease_Update
export def "api-release-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  release_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update. (required)
  --properties: any # API Release details — shape: {apiId?: string, notes?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/releases/{releaseId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: releaseId, var: release_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, release_id: $release_id, api_version: $api_version, if_match: $if_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Release for the API.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/releases/{releaseId}
# Returns: record<properties: record<apiId: string, createdDateTime: string, notes: string, updatedDateTime: string>, id: string, name: string, type: string>
# operationId: ApiRelease_CreateOrUpdate
export def "api-release-create-or-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  release_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. Not required when creating an entity, but required when updating an entity.
  --properties: any # API Release details — shape: {apiId?: string, notes?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/releases/{releaseId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: releaseId, var: release_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, release_id: $release_id, api_version: $api_version, if_match: $if_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all revisions of an API.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/revisions
# Returns: record<nextLink: string, value: table<apiId: string, apiRevision: string, createdDateTime: string, description: string, isCurrent: bool, isOnline: bool, privateUrl: string, updatedDateTime: string>>
# operationId: ApiRevision_ListByService
export def "api-revision-list-by-service" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| apiRevision | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/revisions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$skip", var: skip}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, filter: $filter, top: $top, skip: $skip, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the schema configuration at the API level.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/schemas
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: ApiSchema_ListByApi
export def "api-schema-list-by-api" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| contentType | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/schemas"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$skip", var: skip}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, filter: $filter, top: $top, skip: $skip, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the schema configuration at the Api.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/schemas/{schemaId}
# operationId: ApiSchema_Delete
export def "api-schema-delete" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  schema_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # If true removes all references to the schema before deleting it.
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/schemas/{schemaId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: schemaId, var: schema_id}]
    query: [{name: force, var: force}, {name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, schema_id: $schema_id, force: $force, api_version: $api_version, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the schema configuration at the API level.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/schemas/{schemaId}
# Returns: record<properties: record<contentType: string, document: record<definitions: record, value: string>>, id: string, name: string, type: string>
# operationId: ApiSchema_Get
export def "api-schema-get" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  schema_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/schemas/{schemaId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: schemaId, var: schema_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, schema_id: $schema_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the entity state (Etag) version of the schema specified by its identifier.
#
# HEAD /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/schemas/{schemaId}
# Returns: record
# operationId: ApiSchema_GetEntityTag
export def "api-schema-get-entity-tag" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  schema_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/schemas/{schemaId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: schemaId, var: schema_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, schema_id: $schema_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates schema configuration for the API.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/schemas/{schemaId}
# Returns: record<properties: record<contentType: string, document: record<definitions: record, value: string>>, id: string, name: string, type: string>
# operationId: ApiSchema_CreateOrUpdate
export def "api-schema-create-or-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  schema_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. Not required when creating an entity, but required when updating an entity.
  --properties: any # API Schema create or update contract Properties. — shape: {contentType: string, document?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/schemas/{schemaId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: schemaId, var: schema_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, schema_id: $schema_id, api_version: $api_version, if_match: $if_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all Tags descriptions in scope of API. Model similar to swagger - tagDescription is defined on API level but tag may be assigned to the Operations
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tagDescriptions
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: ApiTagDescription_ListByService
export def "api-tag-description-list-by-service" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| displayName | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | name | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tagDescriptions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$skip", var: skip}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, filter: $filter, top: $top, skip: $skip, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete tag description for the Api.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tagDescriptions/{tagDescriptionId}
# operationId: ApiTagDescription_Delete
export def "api-tag-description-delete" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  tag_description_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. ETag should match the current entity state from the header response of the GET request or it should be * for unconditional update. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tagDescriptions/{tagDescriptionId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: tagDescriptionId, var: tag_description_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, tag_description_id: $tag_description_id, api_version: $api_version, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Tag description in scope of API
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tagDescriptions/{tagDescriptionId}
# Returns: record<properties: record<displayName: string, tagId: string, description: string, externalDocsDescription: string, externalDocsUrl: string>, id: string, name: string, type: string>
# operationId: ApiTagDescription_Get
export def "api-tag-description-get" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  tag_description_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tagDescriptions/{tagDescriptionId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: tagDescriptionId, var: tag_description_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, tag_description_id: $tag_description_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the entity state version of the tag specified by its identifier.
#
# HEAD /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tagDescriptions/{tagDescriptionId}
# Returns: record
# operationId: ApiTagDescription_GetEntityTag
export def "api-tag-description-get-entity-tag" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  tag_description_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tagDescriptions/{tagDescriptionId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: tagDescriptionId, var: tag_description_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, tag_description_id: $tag_description_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create/Update tag description in scope of the Api.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tagDescriptions/{tagDescriptionId}
# Returns: record<properties: record<displayName: string, tagId: string, description: string, externalDocsDescription: string, externalDocsUrl: string>, id: string, name: string, type: string>
# operationId: ApiTagDescription_CreateOrUpdate
export def "api-tag-description-create-or-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  tag_description_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
  --if-match: string # ETag of the Entity. Not required when creating an entity, but required when updating an entity.
  --properties: any # Parameters supplied to the Create TagDescription operation. — shape: {description?: string, externalDocsDescription?: string, externalDocsUrl?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tagDescriptions/{tagDescriptionId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: tagDescriptionId, var: tag_description_id}]
    query: [{name: api-version, var: api_version, required: true}]
    header: [{name: If-Match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, tag_description_id: $tag_description_id, api_version: $api_version, if_match: $if_match, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all Tags associated with the API.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tags
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Tag_ListByApi
export def "tag-list-by-api" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| displayName | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith | | name | filter | ge, le, eq, ne, gt, lt | substringof, contains, startswith, endswith |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tags"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: "$skip", var: skip}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, filter: $filter, top: $top, skip: $skip, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detach the tag from the Api.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tags/{tagId}
# operationId: Tag_DetachFromApi
export def "tag-detach-from-api" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tags/{tagId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: tagId, var: tag_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, tag_id: $tag_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tag associated with the API.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tags/{tagId}
# Returns: record<properties: record<displayName: string>, id: string, name: string, type: string>
# operationId: Tag_GetByApi
export def "tag-get-by-api" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tags/{tagId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: tagId, var: tag_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, tag_id: $tag_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the entity state version of the tag specified by its identifier.
#
# HEAD /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tags/{tagId}
# Returns: record
# operationId: Tag_GetEntityStateByApi
export def "tag-get-entity-state-by-api" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tags/{tagId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: tagId, var: tag_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, tag_id: $tag_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign tag to the Api.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tags/{tagId}
# Returns: record<properties: record<displayName: string>, id: string, name: string, type: string>
# operationId: Tag_AssignToApi
export def "tag-assign-to-api" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  api_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/apis/{apiId}/tags/{tagId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: serviceName, var: service_name}, {name: apiId, var: api_id}, {name: tagId, var: tag_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name, api_id: $api_id, tag_id: $tag_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
