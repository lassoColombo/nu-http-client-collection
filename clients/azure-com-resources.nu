# Auto-generated client for ResourceManagementClient v2019-08-01
# Source: https://api.apis.guru/v2/specs/azure.com/resources/2019-08-01/swagger.json
# Auth: --token flag or $env.RESOURCEMANAGEMENTCLIENT_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "RESOURCEMANAGEMENTCLIENT_TOKEN"
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


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    providers-list-at-tenant-scope: "record<nextLink: string, value: table<id: string, namespace: string, registrationPolicy: string, registrationState: string, resourceTypes: list>>"
    deployments-list-at-management-group-scope: "record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, type: string>>"
    deployments-get-at-management-group-scope: "record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>"
    deployments-check-existence-at-management-group-scope: "record"
    deployments-create-or-update-at-management-group-scope: "record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>"
    deployments-export-template-at-management-group-scope: "record<template: record>"
    deployment-operations-list-at-management-group-scope: "record<nextLink: string, value: table<id: string, operationId: string, properties: record>>"
    deployment-operations-get-at-management-group-scope: "record<id: string, operationId: string, properties: record<duration: string, provisioningState: string, request: record<content: record>, response: record<content: record>, serviceRequestId: string, statusCode: string, statusMessage: record, targetResource: record<id: string, resourceName: string, resourceType: string>, timestamp: string>>"
    deployments-validate-at-management-group-scope: "record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>>"
    deployments-calculate-template-hash: "record<minifiedTemplate: string, templateHash: string>"
    deployments-list-at-tenant-scope: "record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, type: string>>"
    deployments-get-at-tenant-scope: "record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>"
    deployments-check-existence-at-tenant-scope: "record"
    deployments-create-or-update-at-tenant-scope: "record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>"
    deployments-export-template-at-tenant-scope: "record<template: record>"
    deployment-operations-list-at-tenant-scope: "record<nextLink: string, value: table<id: string, operationId: string, properties: record>>"
    deployment-operations-get-at-tenant-scope: "record<id: string, operationId: string, properties: record<duration: string, provisioningState: string, request: record<content: record>, response: record<content: record>, serviceRequestId: string, statusCode: string, statusMessage: record, targetResource: record<id: string, resourceName: string, resourceType: string>, timestamp: string>>"
    deployments-validate-at-tenant-scope: "record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>>"
    operations-list: "record<nextLink: string, value: table<display: record, name: string>>"
    providers-get-at-tenant-scope: "record<id: string, namespace: string, registrationPolicy: string, registrationState: string, resourceTypes: table<aliases: list, apiVersions: list, capabilities: string, locations: list, properties: record, resourceType: string>>"
    providers-list: "record<nextLink: string, value: table<id: string, namespace: string, registrationPolicy: string, registrationState: string, resourceTypes: list>>"
    deployments-list-at-subscription-scope: "record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, type: string>>"
    deployments-get-at-subscription-scope: "record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>"
    deployments-check-existence-at-subscription-scope: "record"
    deployments-create-or-update-at-subscription-scope: "record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>"
    deployments-export-template-at-subscription-scope: "record<template: record>"
    deployment-operations-list-at-subscription-scope: "record<nextLink: string, value: table<id: string, operationId: string, properties: record>>"
    deployment-operations-get-at-subscription-scope: "record<id: string, operationId: string, properties: record<duration: string, provisioningState: string, request: record<content: record>, response: record<content: record>, serviceRequestId: string, statusCode: string, statusMessage: record, targetResource: record<id: string, resourceName: string, resourceType: string>, timestamp: string>>"
    deployments-validate-at-subscription-scope: "record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>>"
    deployments-what-if-at-subscription-scope: "record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<changes: list<record>>, status: string>"
    providers-get: "record<id: string, namespace: string, registrationPolicy: string, registrationState: string, resourceTypes: table<aliases: list, apiVersions: list, capabilities: string, locations: list, properties: record, resourceType: string>>"
    providers-register: "record<id: string, namespace: string, registrationPolicy: string, registrationState: string, resourceTypes: table<aliases: list, apiVersions: list, capabilities: string, locations: list, properties: record, resourceType: string>>"
    providers-unregister: "record<id: string, namespace: string, registrationPolicy: string, registrationState: string, resourceTypes: table<aliases: list, apiVersions: list, capabilities: string, locations: list, properties: record, resourceType: string>>"
    resources-list-by-resource-group: "record<nextLink: string, value: table<identity: record, kind: string, managedBy: string, plan: record, properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>"
    resource-groups-list: "record<nextLink: string, value: table<id: string, location: string, managedBy: string, name: string, properties: record, tags: record, type: string>>"
    resource-groups-get: "record<id: string, location: string, managedBy: string, name: string, properties: record<provisioningState: string>, tags: record, type: string>"
    resource-groups-check-existence: "record"
    resource-groups-update: "record<id: string, location: string, managedBy: string, name: string, properties: record<provisioningState: string>, tags: record, type: string>"
    resource-groups-create-or-update: "record<id: string, location: string, managedBy: string, name: string, properties: record<provisioningState: string>, tags: record, type: string>"
    deployment-operations-list: "record<nextLink: string, value: table<id: string, operationId: string, properties: record>>"
    deployment-operations-get: "record<id: string, operationId: string, properties: record<duration: string, provisioningState: string, request: record<content: record>, response: record<content: record>, serviceRequestId: string, statusCode: string, statusMessage: record, targetResource: record<id: string, resourceName: string, resourceType: string>, timestamp: string>>"
    resource-groups-export-template: "record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, template: record>"
    deployments-list-by-resource-group: "record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, type: string>>"
    deployments-get: "record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>"
    deployments-check-existence: "record"
    deployments-create-or-update: "record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>"
    deployments-export-template: "record<template: record>"
    deployments-validate: "record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>>"
    deployments-what-if: "record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<changes: list<record>>, status: string>"
    resources-get: "record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, kind: string, managedBy: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>"
    resources-check-existence: "record"
    resources-update: "record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, kind: string, managedBy: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>"
    resources-create-or-update: "record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, kind: string, managedBy: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>"
    resources-list: "record<nextLink: string, value: table<identity: record, kind: string, managedBy: string, plan: record, properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>"
    tags-list: "record<nextLink: string, value: table<count: record, id: string, tagName: string, values: list>>"
    tags-create-or-update: "record<count: record<type: string, value: int>, id: string, tagName: string, values: table<count: record, id: string, tagValue: string>>"
    tags-create-or-update-value: "record<count: record<type: string, value: int>, id: string, tagValue: string>"
    resources-get-by-id: "record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, kind: string, managedBy: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>"
    resources-check-existence-by-id: "record"
    resources-update-by-id: "record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, kind: string, managedBy: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>"
    resources-create-or-update-by-id: "record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, kind: string, managedBy: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>"
    deployments-list-at-scope: "record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, type: string>>"
    deployments-get-at-scope: "record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>"
    deployments-check-existence-at-scope: "record"
    deployments-create-or-update-at-scope: "record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>"
    deployments-export-template-at-scope: "record<template: record>"
    deployment-operations-list-at-scope: "record<nextLink: string, value: table<id: string, operationId: string, properties: record>>"
    deployment-operations-get-at-scope: "record<id: string, operationId: string, properties: record<duration: string, provisioningState: string, request: record<content: record>, response: record<content: record>, serviceRequestId: string, statusCode: string, statusMessage: record, targetResource: record<id: string, resourceName: string, resourceType: string>, timestamp: string>>"
    deployments-validate-at-scope: "record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["providers-list-at-tenant-scope" "deployments-list-at-management-group-scope" "deployments-delete-at-management-group-scope" "deployments-get-at-management-group-scope" "deployments-check-existence-at-management-group-scope" "deployments-create-or-update-at-management-group-scope" "deployments-cancel-at-management-group-scope" "deployments-export-template-at-management-group-scope" "deployment-operations-list-at-management-group-scope" "deployment-operations-get-at-management-group-scope" "deployments-validate-at-management-group-scope" "deployments-calculate-template-hash" "deployments-list-at-tenant-scope" "deployments-delete-at-tenant-scope" "deployments-get-at-tenant-scope" "deployments-check-existence-at-tenant-scope" "deployments-create-or-update-at-tenant-scope" "deployments-cancel-at-tenant-scope" "deployments-export-template-at-tenant-scope" "deployment-operations-list-at-tenant-scope" "deployment-operations-get-at-tenant-scope" "deployments-validate-at-tenant-scope" "operations-list" "providers-get-at-tenant-scope" "providers-list" "deployments-list-at-subscription-scope" "deployments-delete-at-subscription-scope" "deployments-get-at-subscription-scope" "deployments-check-existence-at-subscription-scope" "deployments-create-or-update-at-subscription-scope" "deployments-cancel-at-subscription-scope" "deployments-export-template-at-subscription-scope" "deployment-operations-list-at-subscription-scope" "deployment-operations-get-at-subscription-scope" "deployments-validate-at-subscription-scope" "deployments-what-if-at-subscription-scope" "providers-get" "providers-register" "providers-unregister" "resources-list-by-resource-group" "resources-move-resources" "resources-validate-move-resources" "resource-groups-list" "resource-groups-delete" "resource-groups-get" "resource-groups-check-existence" "resource-groups-update" "resource-groups-create-or-update" "deployment-operations-list" "deployment-operations-get" "resource-groups-export-template" "deployments-list-by-resource-group" "deployments-delete" "deployments-get" "deployments-check-existence" "deployments-create-or-update" "deployments-cancel" "deployments-export-template" "deployments-validate" "deployments-what-if" "resources-delete" "resources-get" "resources-check-existence" "resources-update" "resources-create-or-update" "resources-list" "tags-list" "tags-delete" "tags-create-or-update" "tags-delete-value" "tags-create-or-update-value" "resources-delete-by-id" "resources-get-by-id" "resources-check-existence-by-id" "resources-update-by-id" "resources-create-or-update-by-id" "deployments-list-at-scope" "deployments-delete-at-scope" "deployments-get-at-scope" "deployments-check-existence-at-scope" "deployments-create-or-update-at-scope" "deployments-cancel-at-scope" "deployments-export-template-at-scope" "deployment-operations-list-at-scope" "deployment-operations-get-at-scope" "deployments-validate-at-scope" "commands"] | sort) } | get name | first)
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

# Gets all resource providers for the tenant.
#
# GET /providers
# Returns: record<nextLink: string, value: table<id: string, namespace: string, registrationPolicy: string, registrationState: string, resourceTypes: list>>
# operationId: Providers_ListAtTenantScope
export def "providers-list-at-tenant-scope" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The number of results to return. If null is passed returns all providers. (format: int32)
  --expand: string # The properties to include in the results. For example, use &$expand=metadata in the query string to retrieve resource provider metadata. To include property aliases in response, use $expand=resourceTypes/aliases.
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers"
    query: [{name: "$top", var: top}, {name: "$expand", var: expand}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    top: $top, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the deployments for a management group.
#
# GET /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/
# Returns: record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, type: string>>
# operationId: Deployments_ListAtManagementGroupScope
export def "deployments-list-at-management-group-scope" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The filter to apply on the operation. For example, you can use $filter=provisioningState eq '{state}'.
  --top: int # The number of results to get. If null is passed, returns all deployments. (format: int32)
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, filter: $filter, top: $top, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a deployment from the deployment history.
#
# DELETE /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_DeleteAtManagementGroupScope
export def "deployments-delete-at-management-group-scope" [
  group_id: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: groupId, var: group_id}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    group_id: $group_id, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a deployment.
#
# GET /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}
# Returns: record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>
# operationId: Deployments_GetAtManagementGroupScope
export def "deployments-get-at-management-group-scope" [
  group_id: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: groupId, var: group_id}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks whether the deployment exists.
#
# HEAD /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}
# Returns: record
# operationId: Deployments_CheckExistenceAtManagementGroupScope
export def "deployments-check-existence-at-management-group-scope" [
  group_id: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: groupId, var: group_id}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deploys resources at management group scope.
#
# PUT /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}
# Returns: record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>
# operationId: Deployments_CreateOrUpdateAtManagementGroupScope
export def "deployments-create-or-update-at-management-group-scope" [
  group_id: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: groupId, var: group_id}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    group_id: $group_id, deployment_name: $deployment_name, api_version: $api_version, location: $location, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a currently running template deployment.
#
# POST /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}/cancel
# operationId: Deployments_CancelAtManagementGroupScope
export def "deployments-cancel-at-management-group-scope" [
  group_id: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}/cancel"
    path_params: [{name: groupId, var: group_id}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports the template used for specified deployment.
#
# POST /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}/exportTemplate
# Returns: record<template: record>
# operationId: Deployments_ExportTemplateAtManagementGroupScope
export def "deployments-export-template-at-management-group-scope" [
  group_id: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}/exportTemplate"
    path_params: [{name: groupId, var: group_id}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all deployments operations for a deployment.
#
# GET /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}/operations
# Returns: record<nextLink: string, value: table<id: string, operationId: string, properties: record>>
# operationId: DeploymentOperations_ListAtManagementGroupScope
export def "deployment-operations-list-at-management-group-scope" [
  group_id: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The number of results to return. (format: int32)
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}/operations"
    path_params: [{name: groupId, var: group_id}, {name: deploymentName, var: deployment_name}]
    query: [{name: "$top", var: top}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, deployment_name: $deployment_name, top: $top, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a deployments operation.
#
# GET /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}/operations/{operationId}
# Returns: record<id: string, operationId: string, properties: record<duration: string, provisioningState: string, request: record<content: record>, response: record<content: record>, serviceRequestId: string, statusCode: string, statusMessage: record, targetResource: record<id: string, resourceName: string, resourceType: string>, timestamp: string>>
# operationId: DeploymentOperations_GetAtManagementGroupScope
export def "deployment-operations-get-at-management-group-scope" [
  group_id: string
  deployment_name: string
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
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}/operations/{operationId}"
    path_params: [{name: groupId, var: group_id}, {name: deploymentName, var: deployment_name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, deployment_name: $deployment_name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates whether the specified template is syntactically correct and will be accepted by Azure Resource Manager..
#
# POST /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}/validate
# Returns: record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>>
# operationId: Deployments_ValidateAtManagementGroupScope
export def "deployments-validate-at-management-group-scope" [
  group_id: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}/validate"
    path_params: [{name: groupId, var: group_id}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, deployment_name: $deployment_name, api_version: $api_version, location: $location, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate the hash of the given template.
#
# POST /providers/Microsoft.Resources/calculateTemplateHash
# Returns: record<minifiedTemplate: string, templateHash: string>
# operationId: Deployments_CalculateTemplateHash
export def "deployments-calculate-template-hash" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.Resources/calculateTemplateHash"
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the deployments at the tenant scope.
#
# GET /providers/Microsoft.Resources/deployments/
# Returns: record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, type: string>>
# operationId: Deployments_ListAtTenantScope
export def "deployments-list-at-tenant-scope" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The filter to apply on the operation. For example, you can use $filter=provisioningState eq '{state}'.
  --top: int # The number of results to get. If null is passed, returns all deployments. (format: int32)
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Resources/deployments/"
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, top: $top, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a deployment from the deployment history.
#
# DELETE /providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_DeleteAtTenantScope
export def "deployments-delete-at-tenant-scope" [
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a deployment.
#
# GET /providers/Microsoft.Resources/deployments/{deploymentName}
# Returns: record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>
# operationId: Deployments_GetAtTenantScope
export def "deployments-get-at-tenant-scope" [
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks whether the deployment exists.
#
# HEAD /providers/Microsoft.Resources/deployments/{deploymentName}
# Returns: record
# operationId: Deployments_CheckExistenceAtTenantScope
export def "deployments-check-existence-at-tenant-scope" [
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deploys resources at tenant scope.
#
# PUT /providers/Microsoft.Resources/deployments/{deploymentName}
# Returns: record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>
# operationId: Deployments_CreateOrUpdateAtTenantScope
export def "deployments-create-or-update-at-tenant-scope" [
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    deployment_name: $deployment_name, api_version: $api_version, location: $location, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a currently running template deployment.
#
# POST /providers/Microsoft.Resources/deployments/{deploymentName}/cancel
# operationId: Deployments_CancelAtTenantScope
export def "deployments-cancel-at-tenant-scope" [
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/providers/Microsoft.Resources/deployments/{deploymentName}/cancel"
    path_params: [{name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports the template used for specified deployment.
#
# POST /providers/Microsoft.Resources/deployments/{deploymentName}/exportTemplate
# Returns: record<template: record>
# operationId: Deployments_ExportTemplateAtTenantScope
export def "deployments-export-template-at-tenant-scope" [
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/providers/Microsoft.Resources/deployments/{deploymentName}/exportTemplate"
    path_params: [{name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all deployments operations for a deployment.
#
# GET /providers/Microsoft.Resources/deployments/{deploymentName}/operations
# Returns: record<nextLink: string, value: table<id: string, operationId: string, properties: record>>
# operationId: DeploymentOperations_ListAtTenantScope
export def "deployment-operations-list-at-tenant-scope" [
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The number of results to return. (format: int32)
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Resources/deployments/{deploymentName}/operations"
    path_params: [{name: deploymentName, var: deployment_name}]
    query: [{name: "$top", var: top}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deployment_name: $deployment_name, top: $top, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a deployments operation.
#
# GET /providers/Microsoft.Resources/deployments/{deploymentName}/operations/{operationId}
# Returns: record<id: string, operationId: string, properties: record<duration: string, provisioningState: string, request: record<content: record>, response: record<content: record>, serviceRequestId: string, statusCode: string, statusMessage: record, targetResource: record<id: string, resourceName: string, resourceType: string>, timestamp: string>>
# operationId: DeploymentOperations_GetAtTenantScope
export def "deployment-operations-get-at-tenant-scope" [
  deployment_name: string
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
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Resources/deployments/{deploymentName}/operations/{operationId}"
    path_params: [{name: deploymentName, var: deployment_name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deployment_name: $deployment_name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates whether the specified template is syntactically correct and will be accepted by Azure Resource Manager..
#
# POST /providers/Microsoft.Resources/deployments/{deploymentName}/validate
# Returns: record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>>
# operationId: Deployments_ValidateAtTenantScope
export def "deployments-validate-at-tenant-scope" [
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.Resources/deployments/{deploymentName}/validate"
    path_params: [{name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deployment_name: $deployment_name, api_version: $api_version, location: $location, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the available Microsoft.Resources REST API operations.
#
# GET /providers/Microsoft.Resources/operations
# Returns: record<nextLink: string, value: table<display: record, name: string>>
# operationId: Operations_List
export def "operations-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Resources/operations"
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified resource provider at the tenant level.
#
# GET /providers/{resourceProviderNamespace}
# Returns: record<id: string, namespace: string, registrationPolicy: string, registrationState: string, resourceTypes: table<aliases: list, apiVersions: list, capabilities: string, locations: list, properties: record, resourceType: string>>
# operationId: Providers_GetAtTenantScope
export def "providers-get-at-tenant-scope" [
  resource_provider_namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # The $expand query parameter. For example, to include property aliases in response, use $expand=resourceTypes/aliases.
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/{resourceProviderNamespace}"
    path_params: [{name: resourceProviderNamespace, var: resource_provider_namespace}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_provider_namespace: $resource_provider_namespace, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all resource providers for a subscription.
#
# GET /subscriptions/{subscriptionId}/providers
# Returns: record<nextLink: string, value: table<id: string, namespace: string, registrationPolicy: string, registrationState: string, resourceTypes: list>>
# operationId: Providers_List
export def "providers-list" [
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
  --top: int # The number of results to return. If null is passed returns all deployments. (format: int32)
  --expand: string # The properties to include in the results. For example, use &$expand=metadata in the query string to retrieve resource provider metadata. To include property aliases in response, use $expand=resourceTypes/aliases.
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: "$top", var: top}, {name: "$expand", var: expand}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, top: $top, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the deployments for a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/
# Returns: record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, type: string>>
# operationId: Deployments_ListAtSubscriptionScope
export def "deployments-list-at-subscription-scope" [
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
  --filter: string # The filter to apply on the operation. For example, you can use $filter=provisioningState eq '{state}'.
  --top: int # The number of results to get. If null is passed, returns all deployments. (format: int32)
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, filter: $filter, top: $top, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a deployment from the deployment history.
#
# DELETE /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_DeleteAtSubscriptionScope
export def "deployments-delete-at-subscription-scope" [
  subscription_id: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a deployment.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}
# Returns: record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>
# operationId: Deployments_GetAtSubscriptionScope
export def "deployments-get-at-subscription-scope" [
  subscription_id: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks whether the deployment exists.
#
# HEAD /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}
# Returns: record
# operationId: Deployments_CheckExistenceAtSubscriptionScope
export def "deployments-check-existence-at-subscription-scope" [
  subscription_id: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deploys resources at subscription scope.
#
# PUT /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}
# Returns: record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>
# operationId: Deployments_CreateOrUpdateAtSubscriptionScope
export def "deployments-create-or-update-at-subscription-scope" [
  subscription_id: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  --location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, deployment_name: $deployment_name, api_version: $api_version, location: $location, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a currently running template deployment.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}/cancel
# operationId: Deployments_CancelAtSubscriptionScope
export def "deployments-cancel-at-subscription-scope" [
  subscription_id: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}/cancel"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports the template used for specified deployment.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}/exportTemplate
# Returns: record<template: record>
# operationId: Deployments_ExportTemplateAtSubscriptionScope
export def "deployments-export-template-at-subscription-scope" [
  subscription_id: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}/exportTemplate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all deployments operations for a deployment.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}/operations
# Returns: record<nextLink: string, value: table<id: string, operationId: string, properties: record>>
# operationId: DeploymentOperations_ListAtSubscriptionScope
export def "deployment-operations-list-at-subscription-scope" [
  subscription_id: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The number of results to return. (format: int32)
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}/operations"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: deploymentName, var: deployment_name}]
    query: [{name: "$top", var: top}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, deployment_name: $deployment_name, top: $top, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a deployments operation.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}/operations/{operationId}
# Returns: record<id: string, operationId: string, properties: record<duration: string, provisioningState: string, request: record<content: record>, response: record<content: record>, serviceRequestId: string, statusCode: string, statusMessage: record, targetResource: record<id: string, resourceName: string, resourceType: string>, timestamp: string>>
# operationId: DeploymentOperations_GetAtSubscriptionScope
export def "deployment-operations-get-at-subscription-scope" [
  subscription_id: string
  deployment_name: string
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
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}/operations/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: deploymentName, var: deployment_name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, deployment_name: $deployment_name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates whether the specified template is syntactically correct and will be accepted by Azure Resource Manager..
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}/validate
# Returns: record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>>
# operationId: Deployments_ValidateAtSubscriptionScope
export def "deployments-validate-at-subscription-scope" [
  subscription_id: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  --location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}/validate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, deployment_name: $deployment_name, api_version: $api_version, location: $location, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns changes that will be made by the deployment if executed at the scope of the subscription.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}/whatIf
# Returns: record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<changes: list<record>>, status: string>
# operationId: Deployments_WhatIfAtSubscriptionScope
export def "deployments-what-if-at-subscription-scope" [
  subscription_id: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  --location: string # The location to store the deployment data.
  properties: any # Deployment What-if properties. — shape: {whatIfSettings?: any, debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}/whatIf"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, deployment_name: $deployment_name, api_version: $api_version, location: $location, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified resource provider.
#
# GET /subscriptions/{subscriptionId}/providers/{resourceProviderNamespace}
# Returns: record<id: string, namespace: string, registrationPolicy: string, registrationState: string, resourceTypes: table<aliases: list, apiVersions: list, capabilities: string, locations: list, properties: record, resourceType: string>>
# operationId: Providers_Get
export def "providers-get" [
  subscription_id: string
  resource_provider_namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # The $expand query parameter. For example, to include property aliases in response, use $expand=resourceTypes/aliases.
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/{resourceProviderNamespace}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceProviderNamespace, var: resource_provider_namespace}]
    query: [{name: "$expand", var: expand}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_provider_namespace: $resource_provider_namespace, expand: $expand, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a subscription with a resource provider.
#
# POST /subscriptions/{subscriptionId}/providers/{resourceProviderNamespace}/register
# Returns: record<id: string, namespace: string, registrationPolicy: string, registrationState: string, resourceTypes: table<aliases: list, apiVersions: list, capabilities: string, locations: list, properties: record, resourceType: string>>
# operationId: Providers_Register
export def "providers-register" [
  subscription_id: string
  resource_provider_namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/{resourceProviderNamespace}/register"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceProviderNamespace, var: resource_provider_namespace}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_provider_namespace: $resource_provider_namespace, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unregisters a subscription from a resource provider.
#
# POST /subscriptions/{subscriptionId}/providers/{resourceProviderNamespace}/unregister
# Returns: record<id: string, namespace: string, registrationPolicy: string, registrationState: string, resourceTypes: table<aliases: list, apiVersions: list, capabilities: string, locations: list, properties: record, resourceType: string>>
# operationId: Providers_Unregister
export def "providers-unregister" [
  subscription_id: string
  resource_provider_namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/{resourceProviderNamespace}/unregister"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceProviderNamespace, var: resource_provider_namespace}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_provider_namespace: $resource_provider_namespace, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the resources for a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/resources
# Returns: record<nextLink: string, value: table<identity: record, kind: string, managedBy: string, plan: record, properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Resources_ListByResourceGroup
export def "resources-list-by-resource-group" [
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
  --filter: string # The filter to apply on the operation.The properties you can use for eq (equals) or ne (not equals) are: location, resourceType, name, resourceGroup, identity, identity/principalId, plan, plan/publisher, plan/product, plan/name, plan/version, and plan/promotionCode.For example, to filter by a resource type, use: $filter=resourceType eq 'Microsoft.Network/virtualNetworks'You can use substringof(value, property) in the filter. The properties you can use for substring are: name and resourceGroup.For example, to get all resources with 'demo' anywhere in the name, use: $filter=substringof('demo', name)You can link more than one substringof together by adding and/or operators.You can filter by tag names and values. For example, to filter for a tag name and value, use $filter=tagName eq 'tag1' and tagValue eq 'Value1'. When you filter by a tag name and value, the tags for each resource are not returned in the results.You can use some properties together when filtering. The combinations you can use are: substringof and/or resourceType, plan and plan/publisher and plan/name, identity and identity/principalId.
  --expand: string # The $expand query parameter. You can expand createdTime and changedTime. For example, to expand both properties, use $expand=changedTime,createdTime
  --top: int # The number of results to return. If null is passed, returns all resources. (format: int32)
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/resources"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: "$filter", var: filter}, {name: "$expand", var: expand}, {name: "$top", var: top}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, filter: $filter, expand: $expand, top: $top, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves resources from one resource group to another resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{sourceResourceGroupName}/moveResources
# operationId: Resources_MoveResources
export def "resources-move-resources" [
  subscription_id: string
  source_resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  --resources: list<string> # The IDs of the resources.
  --target-resource-group: string # The target resource group.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{sourceResourceGroupName}/moveResources"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: sourceResourceGroupName, var: source_resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: resources, var: resources}, {name: targetResourceGroup, var: target_resource_group}]}
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, source_resource_group_name: $source_resource_group_name, api_version: $api_version, resources: $resources, target_resource_group: $target_resource_group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates whether resources can be moved from one resource group to another resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{sourceResourceGroupName}/validateMoveResources
# operationId: Resources_ValidateMoveResources
export def "resources-validate-move-resources" [
  subscription_id: string
  source_resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  --resources: list<string> # The IDs of the resources.
  --target-resource-group: string # The target resource group.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{sourceResourceGroupName}/validateMoveResources"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: sourceResourceGroupName, var: source_resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: resources, var: resources}, {name: targetResourceGroup, var: target_resource_group}]}
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, source_resource_group_name: $source_resource_group_name, api_version: $api_version, resources: $resources, target_resource_group: $target_resource_group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the resource groups for a subscription.
#
# GET /subscriptions/{subscriptionId}/resourcegroups
# Returns: record<nextLink: string, value: table<id: string, location: string, managedBy: string, name: string, properties: record, tags: record, type: string>>
# operationId: ResourceGroups_List
export def "resource-groups-list" [
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
  --filter: string # The filter to apply on the operation.You can filter by tag names and values. For example, to filter for a tag name and value, use $filter=tagName eq 'tag1' and tagValue eq 'Value1'
  --top: int # The number of results to return. If null is passed, returns all resource groups. (format: int32)
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourcegroups"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, filter: $filter, top: $top, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a resource group.
#
# DELETE /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}
# operationId: ResourceGroups_Delete
export def "resource-groups-delete" [
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
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a resource group.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}
# Returns: record<id: string, location: string, managedBy: string, name: string, properties: record<provisioningState: string>, tags: record, type: string>
# operationId: ResourceGroups_Get
export def "resource-groups-get" [
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
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks whether a resource group exists.
#
# HEAD /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}
# Returns: record
# operationId: ResourceGroups_CheckExistence
export def "resource-groups-check-existence" [
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
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a resource group.
#
# PATCH /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}
# Returns: record<id: string, location: string, managedBy: string, name: string, properties: record<provisioningState: string>, tags: record, type: string>
# operationId: ResourceGroups_Update
export def "resource-groups-update" [
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
  --api-version: string # The API version to use for this operation. (required)
  --managed-by: string # The ID of the resource that manages this resource group.
  --name: string # The name of the resource group.
  --properties: any # The resource group properties.
  --tags: record # The tags attached to the resource group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: managedBy, var: managed_by}, {name: name, var: name}, {name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version, managed_by: $managed_by, name: $name, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a resource group.
#
# PUT /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}
# Returns: record<id: string, location: string, managedBy: string, name: string, properties: record<provisioningState: string>, tags: record, type: string>
# operationId: ResourceGroups_CreateOrUpdate
export def "resource-groups-create-or-update" [
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
  --api-version: string # The API version to use for this operation. (required)
  location: string # The location of the resource group. It cannot be changed after the resource group has been created. It must be one of the supported Azure locations.
  --managed-by: string # The ID of the resource that manages this resource group.
  --properties: any # The resource group properties.
  --tags: record # The tags attached to the resource group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: managedBy, var: managed_by}, {name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version, location: $location, managed_by: $managed_by, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all deployments operations for a deployment.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/deployments/{deploymentName}/operations
# Returns: record<nextLink: string, value: table<id: string, operationId: string, properties: record>>
# operationId: DeploymentOperations_List
export def "deployment-operations-list" [
  subscription_id: string
  resource_group_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The number of results to return. (format: int32)
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/deployments/{deploymentName}/operations"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: deploymentName, var: deployment_name}]
    query: [{name: "$top", var: top}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, deployment_name: $deployment_name, top: $top, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a deployments operation.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/deployments/{deploymentName}/operations/{operationId}
# Returns: record<id: string, operationId: string, properties: record<duration: string, provisioningState: string, request: record<content: record>, response: record<content: record>, serviceRequestId: string, statusCode: string, statusMessage: record, targetResource: record<id: string, resourceName: string, resourceType: string>, timestamp: string>>
# operationId: DeploymentOperations_Get
export def "deployment-operations-get" [
  subscription_id: string
  resource_group_name: string
  deployment_name: string
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
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/deployments/{deploymentName}/operations/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: deploymentName, var: deployment_name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, deployment_name: $deployment_name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Captures the specified resource group as a template.
#
# POST /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/exportTemplate
# Returns: record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, template: record>
# operationId: ResourceGroups_ExportTemplate
export def "resource-groups-export-template" [
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
  --api-version: string # The API version to use for this operation. (required)
  --options: string # The export template options. A CSV-formatted list containing zero or more of the following: 'IncludeParameterDefaultValue', 'IncludeComments', 'SkipResourceNameParameterization', 'SkipAllParameterization'
  --resources: list<string> # The IDs of the resources to filter the export by. To export all resources, supply an array with single entry '*'.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/exportTemplate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: options, var: options}, {name: resources, var: resources}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version, options: $options, resources: $resources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the deployments for a resource group.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/
# Returns: record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, type: string>>
# operationId: Deployments_ListByResourceGroup
export def "deployments-list-by-resource-group" [
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
  --filter: string # The filter to apply on the operation. For example, you can use $filter=provisioningState eq '{state}'.
  --top: int # The number of results to get. If null is passed, returns all deployments. (format: int32)
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, filter: $filter, top: $top, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a deployment from the deployment history.
#
# DELETE /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_Delete
export def "deployments-delete" [
  subscription_id: string
  resource_group_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a deployment.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}
# Returns: record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>
# operationId: Deployments_Get
export def "deployments-get" [
  subscription_id: string
  resource_group_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks whether the deployment exists.
#
# HEAD /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}
# Returns: record
# operationId: Deployments_CheckExistence
export def "deployments-check-existence" [
  subscription_id: string
  resource_group_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deploys resources to a resource group.
#
# PUT /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}
# Returns: record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>
# operationId: Deployments_CreateOrUpdate
export def "deployments-create-or-update" [
  subscription_id: string
  resource_group_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  --location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, deployment_name: $deployment_name, api_version: $api_version, location: $location, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a currently running template deployment.
#
# POST /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}/cancel
# operationId: Deployments_Cancel
export def "deployments-cancel" [
  subscription_id: string
  resource_group_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}/cancel"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports the template used for specified deployment.
#
# POST /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}/exportTemplate
# Returns: record<template: record>
# operationId: Deployments_ExportTemplate
export def "deployments-export-template" [
  subscription_id: string
  resource_group_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}/exportTemplate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates whether the specified template is syntactically correct and will be accepted by Azure Resource Manager..
#
# POST /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}/validate
# Returns: record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>>
# operationId: Deployments_Validate
export def "deployments-validate" [
  subscription_id: string
  resource_group_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  --location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}/validate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, deployment_name: $deployment_name, api_version: $api_version, location: $location, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns changes that will be made by the deployment if executed at the scope of the resource group.
#
# POST /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}/whatIf
# Returns: record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<changes: list<record>>, status: string>
# operationId: Deployments_WhatIf
export def "deployments-what-if" [
  subscription_id: string
  resource_group_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  --location: string # The location to store the deployment data.
  properties: any # Deployment What-if properties. — shape: {whatIfSettings?: any, debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}/whatIf"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, deployment_name: $deployment_name, api_version: $api_version, location: $location, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a resource.
#
# DELETE /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{parentResourcePath}/{resourceType}/{resourceName}
# operationId: Resources_Delete
export def "resources-delete" [
  subscription_id: string
  resource_group_name: string
  resource_provider_namespace: string
  parent_resource_path: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{parentResourcePath}/{resourceType}/{resourceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceProviderNamespace, var: resource_provider_namespace}, {name: parentResourcePath, var: parent_resource_path}, {name: resourceType, var: resource_type}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_provider_namespace: $resource_provider_namespace, parent_resource_path: $parent_resource_path, resource_type: $resource_type, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a resource.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{parentResourcePath}/{resourceType}/{resourceName}
# Returns: record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, kind: string, managedBy: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Resources_Get
export def "resources-get" [
  subscription_id: string
  resource_group_name: string
  resource_provider_namespace: string
  parent_resource_path: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{parentResourcePath}/{resourceType}/{resourceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceProviderNamespace, var: resource_provider_namespace}, {name: parentResourcePath, var: parent_resource_path}, {name: resourceType, var: resource_type}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_provider_namespace: $resource_provider_namespace, parent_resource_path: $parent_resource_path, resource_type: $resource_type, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks whether a resource exists.
#
# HEAD /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{parentResourcePath}/{resourceType}/{resourceName}
# Returns: record
# operationId: Resources_CheckExistence
export def "resources-check-existence" [
  subscription_id: string
  resource_group_name: string
  resource_provider_namespace: string
  parent_resource_path: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{parentResourcePath}/{resourceType}/{resourceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceProviderNamespace, var: resource_provider_namespace}, {name: parentResourcePath, var: parent_resource_path}, {name: resourceType, var: resource_type}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_provider_namespace: $resource_provider_namespace, parent_resource_path: $parent_resource_path, resource_type: $resource_type, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a resource.
#
# PATCH /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{parentResourcePath}/{resourceType}/{resourceName}
# Returns: record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, kind: string, managedBy: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Resources_Update
export def "resources-update" [
  subscription_id: string
  resource_group_name: string
  resource_provider_namespace: string
  parent_resource_path: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  --identity: any # Identity for the resource. — shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --kind: string # The kind of the resource.
  --managed-by: string # ID of the resource that manages this resource.
  --plan: any # Plan for the resource. — shape: {name?: string, product?: string, promotionCode?: string, publisher?: string, version?: string}
  --properties: record # The resource properties.
  --sku: any # SKU for the resource. — shape: {capacity?: int, family?: string, model?: string, name?: string, size?: string, tier?: string}
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{parentResourcePath}/{resourceType}/{resourceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceProviderNamespace, var: resource_provider_namespace}, {name: parentResourcePath, var: parent_resource_path}, {name: resourceType, var: resource_type}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: identity, var: identity}, {name: kind, var: kind}, {name: managedBy, var: managed_by}, {name: plan, var: plan}, {name: properties, var: properties}, {name: sku, var: sku}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_provider_namespace: $resource_provider_namespace, parent_resource_path: $parent_resource_path, resource_type: $resource_type, resource_name: $resource_name, api_version: $api_version, identity: $identity, kind: $kind, managed_by: $managed_by, plan: $plan, properties: $properties, sku: $sku, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a resource.
#
# PUT /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{parentResourcePath}/{resourceType}/{resourceName}
# Returns: record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, kind: string, managedBy: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Resources_CreateOrUpdate
export def "resources-create-or-update" [
  subscription_id: string
  resource_group_name: string
  resource_provider_namespace: string
  parent_resource_path: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  --identity: any # Identity for the resource. — shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --kind: string # The kind of the resource.
  --managed-by: string # ID of the resource that manages this resource.
  --plan: any # Plan for the resource. — shape: {name?: string, product?: string, promotionCode?: string, publisher?: string, version?: string}
  --properties: record # The resource properties.
  --sku: any # SKU for the resource. — shape: {capacity?: int, family?: string, model?: string, name?: string, size?: string, tier?: string}
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{parentResourcePath}/{resourceType}/{resourceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceProviderNamespace, var: resource_provider_namespace}, {name: parentResourcePath, var: parent_resource_path}, {name: resourceType, var: resource_type}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: identity, var: identity}, {name: kind, var: kind}, {name: managedBy, var: managed_by}, {name: plan, var: plan}, {name: properties, var: properties}, {name: sku, var: sku}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_provider_namespace: $resource_provider_namespace, parent_resource_path: $parent_resource_path, resource_type: $resource_type, resource_name: $resource_name, api_version: $api_version, identity: $identity, kind: $kind, managed_by: $managed_by, plan: $plan, properties: $properties, sku: $sku, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the resources in a subscription.
#
# GET /subscriptions/{subscriptionId}/resources
# Returns: record<nextLink: string, value: table<identity: record, kind: string, managedBy: string, plan: record, properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Resources_List
export def "resources-list" [
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
  --filter: string # The filter to apply on the operation.The properties you can use for eq (equals) or ne (not equals) are: location, resourceType, name, resourceGroup, identity, identity/principalId, plan, plan/publisher, plan/product, plan/name, plan/version, and plan/promotionCode.For example, to filter by a resource type, use: $filter=resourceType eq 'Microsoft.Network/virtualNetworks'You can use substringof(value, property) in the filter. The properties you can use for substring are: name and resourceGroup.For example, to get all resources with 'demo' anywhere in the name, use: $filter=substringof('demo', name)You can link more than one substringof together by adding and/or operators.You can filter by tag names and values. For example, to filter for a tag name and value, use $filter=tagName eq 'tag1' and tagValue eq 'Value1'. When you filter by a tag name and value, the tags for each resource are not returned in the results.You can use some properties together when filtering. The combinations you can use are: substringof and/or resourceType, plan and plan/publisher and plan/name, identity and identity/principalId.
  --expand: string # The $expand query parameter. You can expand createdTime and changedTime. For example, to expand both properties, use $expand=changedTime,createdTime
  --top: int # The number of results to return. If null is passed, returns all resource groups. (format: int32)
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resources"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: "$filter", var: filter}, {name: "$expand", var: expand}, {name: "$top", var: top}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, filter: $filter, expand: $expand, top: $top, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the names and values of all resource tags that are defined in a subscription.
#
# GET /subscriptions/{subscriptionId}/tagNames
# Returns: record<nextLink: string, value: table<count: record, id: string, tagName: string, values: list>>
# operationId: Tags_List
export def "tags-list" [
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
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/tagNames"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a tag from the subscription.
#
# DELETE /subscriptions/{subscriptionId}/tagNames/{tagName}
# operationId: Tags_Delete
export def "tags-delete" [
  subscription_id: string
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/tagNames/{tagName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: tagName, var: tag_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, tag_name: $tag_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a tag in the subscription.
#
# PUT /subscriptions/{subscriptionId}/tagNames/{tagName}
# Returns: record<count: record<type: string, value: int>, id: string, tagName: string, values: table<count: record, id: string, tagValue: string>>
# operationId: Tags_CreateOrUpdate
export def "tags-create-or-update" [
  subscription_id: string
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/tagNames/{tagName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: tagName, var: tag_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, tag_name: $tag_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a tag value.
#
# DELETE /subscriptions/{subscriptionId}/tagNames/{tagName}/tagValues/{tagValue}
# operationId: Tags_DeleteValue
export def "tags-delete-value" [
  subscription_id: string
  tag_name: string
  tag_value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/tagNames/{tagName}/tagValues/{tagValue}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: tagName, var: tag_name}, {name: tagValue, var: tag_value}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, tag_name: $tag_name, tag_value: $tag_value, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a tag value. The name of the tag must already exist.
#
# PUT /subscriptions/{subscriptionId}/tagNames/{tagName}/tagValues/{tagValue}
# Returns: record<count: record<type: string, value: int>, id: string, tagValue: string>
# operationId: Tags_CreateOrUpdateValue
export def "tags-create-or-update-value" [
  subscription_id: string
  tag_name: string
  tag_value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/tagNames/{tagName}/tagValues/{tagValue}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: tagName, var: tag_name}, {name: tagValue, var: tag_value}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, tag_name: $tag_name, tag_value: $tag_value, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a resource by ID.
#
# DELETE /{resourceId}
# operationId: Resources_DeleteById
export def "resources-delete-by-id" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/{resourceId}"
    path_params: [{name: resourceId, var: resource_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    resource_id: $resource_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a resource by ID.
#
# GET /{resourceId}
# Returns: record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, kind: string, managedBy: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Resources_GetById
export def "resources-get-by-id" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{resourceId}"
    path_params: [{name: resourceId, var: resource_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_id: $resource_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks by ID whether a resource exists.
#
# HEAD /{resourceId}
# Returns: record
# operationId: Resources_CheckExistenceById
export def "resources-check-existence-by-id" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/{resourceId}"
    path_params: [{name: resourceId, var: resource_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_id: $resource_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a resource by ID.
#
# PATCH /{resourceId}
# Returns: record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, kind: string, managedBy: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Resources_UpdateById
export def "resources-update-by-id" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  --identity: any # Identity for the resource. — shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --kind: string # The kind of the resource.
  --managed-by: string # ID of the resource that manages this resource.
  --plan: any # Plan for the resource. — shape: {name?: string, product?: string, promotionCode?: string, publisher?: string, version?: string}
  --properties: record # The resource properties.
  --sku: any # SKU for the resource. — shape: {capacity?: int, family?: string, model?: string, name?: string, size?: string, tier?: string}
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/{resourceId}"
    path_params: [{name: resourceId, var: resource_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: identity, var: identity}, {name: kind, var: kind}, {name: managedBy, var: managed_by}, {name: plan, var: plan}, {name: properties, var: properties}, {name: sku, var: sku}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    resource_id: $resource_id, api_version: $api_version, identity: $identity, kind: $kind, managed_by: $managed_by, plan: $plan, properties: $properties, sku: $sku, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a resource by ID.
#
# PUT /{resourceId}
# Returns: record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, kind: string, managedBy: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Resources_CreateOrUpdateById
export def "resources-create-or-update-by-id" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  --identity: any # Identity for the resource. — shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --kind: string # The kind of the resource.
  --managed-by: string # ID of the resource that manages this resource.
  --plan: any # Plan for the resource. — shape: {name?: string, product?: string, promotionCode?: string, publisher?: string, version?: string}
  --properties: record # The resource properties.
  --sku: any # SKU for the resource. — shape: {capacity?: int, family?: string, model?: string, name?: string, size?: string, tier?: string}
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{resourceId}"
    path_params: [{name: resourceId, var: resource_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: identity, var: identity}, {name: kind, var: kind}, {name: managedBy, var: managed_by}, {name: plan, var: plan}, {name: properties, var: properties}, {name: sku, var: sku}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    resource_id: $resource_id, api_version: $api_version, identity: $identity, kind: $kind, managed_by: $managed_by, plan: $plan, properties: $properties, sku: $sku, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the deployments at the given scope.
#
# GET /{scope}/providers/Microsoft.Resources/deployments/
# Returns: record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, type: string>>
# operationId: Deployments_ListAtScope
export def "deployments-list-at-scope" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The filter to apply on the operation. For example, you can use $filter=provisioningState eq '{state}'.
  --top: int # The number of results to get. If null is passed, returns all deployments. (format: int32)
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{scope}/providers/Microsoft.Resources/deployments/"
    path_params: [{name: scope, var: scope}]
    query: [{name: "$filter", var: filter}, {name: "$top", var: top}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scope: $scope, filter: $filter, top: $top, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a deployment from the deployment history.
#
# DELETE /{scope}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_DeleteAtScope
export def "deployments-delete-at-scope" [
  scope: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/{scope}/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: scope, var: scope}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    scope: $scope, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a deployment.
#
# GET /{scope}/providers/Microsoft.Resources/deployments/{deploymentName}
# Returns: record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>
# operationId: Deployments_GetAtScope
export def "deployments-get-at-scope" [
  scope: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{scope}/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: scope, var: scope}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scope: $scope, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks whether the deployment exists.
#
# HEAD /{scope}/providers/Microsoft.Resources/deployments/{deploymentName}
# Returns: record
# operationId: Deployments_CheckExistenceAtScope
export def "deployments-check-existence-at-scope" [
  scope: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/{scope}/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: scope, var: scope}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    scope: $scope, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deploys resources at a given scope.
#
# PUT /{scope}/providers/Microsoft.Resources/deployments/{deploymentName}
# Returns: record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string>
# operationId: Deployments_CreateOrUpdateAtScope
export def "deployments-create-or-update-at-scope" [
  scope: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  --location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/{scope}/providers/Microsoft.Resources/deployments/{deploymentName}"
    path_params: [{name: scope, var: scope}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    scope: $scope, deployment_name: $deployment_name, api_version: $api_version, location: $location, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a currently running template deployment.
#
# POST /{scope}/providers/Microsoft.Resources/deployments/{deploymentName}/cancel
# operationId: Deployments_CancelAtScope
export def "deployments-cancel-at-scope" [
  scope: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/{scope}/providers/Microsoft.Resources/deployments/{deploymentName}/cancel"
    path_params: [{name: scope, var: scope}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    scope: $scope, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports the template used for specified deployment.
#
# POST /{scope}/providers/Microsoft.Resources/deployments/{deploymentName}/exportTemplate
# Returns: record<template: record>
# operationId: Deployments_ExportTemplateAtScope
export def "deployments-export-template-at-scope" [
  scope: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/{scope}/providers/Microsoft.Resources/deployments/{deploymentName}/exportTemplate"
    path_params: [{name: scope, var: scope}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scope: $scope, deployment_name: $deployment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all deployments operations for a deployment.
#
# GET /{scope}/providers/Microsoft.Resources/deployments/{deploymentName}/operations
# Returns: record<nextLink: string, value: table<id: string, operationId: string, properties: record>>
# operationId: DeploymentOperations_ListAtScope
export def "deployment-operations-list-at-scope" [
  scope: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The number of results to return. (format: int32)
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{scope}/providers/Microsoft.Resources/deployments/{deploymentName}/operations"
    path_params: [{name: scope, var: scope}, {name: deploymentName, var: deployment_name}]
    query: [{name: "$top", var: top}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scope: $scope, deployment_name: $deployment_name, top: $top, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a deployments operation.
#
# GET /{scope}/providers/Microsoft.Resources/deployments/{deploymentName}/operations/{operationId}
# Returns: record<id: string, operationId: string, properties: record<duration: string, provisioningState: string, request: record<content: record>, response: record<content: record>, serviceRequestId: string, statusCode: string, statusMessage: record, targetResource: record<id: string, resourceName: string, resourceType: string>, timestamp: string>>
# operationId: DeploymentOperations_GetAtScope
export def "deployment-operations-get-at-scope" [
  scope: string
  deployment_name: string
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
  --api-version: string # The API version to use for this operation. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{scope}/providers/Microsoft.Resources/deployments/{deploymentName}/operations/{operationId}"
    path_params: [{name: scope, var: scope}, {name: deploymentName, var: deployment_name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scope: $scope, deployment_name: $deployment_name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates whether the specified template is syntactically correct and will be accepted by Azure Resource Manager..
#
# POST /{scope}/providers/Microsoft.Resources/deployments/{deploymentName}/validate
# Returns: record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>>
# operationId: Deployments_ValidateAtScope
export def "deployments-validate-at-scope" [
  scope: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation. (required)
  --location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{scope}/providers/Microsoft.Resources/deployments/{deploymentName}/validate"
    path_params: [{name: scope, var: scope}, {name: deploymentName, var: deployment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scope: $scope, deployment_name: $deployment_name, api_version: $api_version, location: $location, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
