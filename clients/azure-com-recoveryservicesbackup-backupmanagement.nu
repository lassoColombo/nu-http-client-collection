# Auto-generated client for RecoveryServicesBackupClient v2016-12-01
# Source: https://api.apis.guru/v2/specs/azure.com/recoveryservicesbackup-backupManagement/2016-12-01/swagger.json
# Auth: --token flag or $env.RECOVERYSERVICESBACKUPCLIENT_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "RECOVERYSERVICESBACKUPCLIENT_TOKEN"
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
    backup-engines-list: "record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>, nextLink: string>"
    backup-engines-get: "record<properties: record<azureBackupAgentVersion: string, backupEngineId: string, backupEngineState: string, backupEngineType: string, backupManagementType: string, canReRegister: bool, dpmVersion: string, extendedInfo: record<availableDiskSpace: float, azureProtectedInstances: int, databaseName: string, diskCount: int, protectedItemsCount: int, protectedServersCount: int, refreshedAt: string, usedDiskSpace: float>, friendlyName: string, healthStatus: string, isAzureBackupAgentUpgradeAvailable: bool, isDPMUpgradeAvailable: bool, registrationStatus: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string>"
    protection-containers-get: "record<properties: record<backupManagementType: string, containerType: string, friendlyName: string, healthStatus: string, protectableObjectType: string, registrationStatus: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string>"
    protection-container-operation-results-get: "record<properties: record<backupManagementType: string, containerType: string, friendlyName: string, healthStatus: string, protectableObjectType: string, registrationStatus: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string>"
    protected-items-get: "record<properties: record<backupManagementType: string, containerName: string, lastRecoveryPoint: string, policyId: string, protectedItemType: string, sourceResourceId: string, workloadType: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string>"
    protected-item-operation-results-get: "record<properties: record<backupManagementType: string, containerName: string, lastRecoveryPoint: string, policyId: string, protectedItemType: string, sourceResourceId: string, workloadType: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string>"
    protected-item-operation-statuses-get: "record<endTime: string, error: record<code: string, message: string>, id: string, name: string, properties: record<objectType: string>, startTime: string, status: string>"
    recovery-points-list: "record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>, nextLink: string>"
    recovery-points-get: "record<properties: record<objectType: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string>"
    export-jobs-operation-results-get: "record<operation: record<objectType: string>, Headers: record, statusCode: string>"
    backup-operation-statuses-get: "record<endTime: string, error: record<code: string, message: string>, id: string, name: string, properties: record<objectType: string>, startTime: string, status: string>"
    backup-policies-list: "record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>, nextLink: string>"
    protection-policies-get: "record<properties: record<backupManagementType: string, protectedItemsCount: int>, eTag: string, id: string, location: string, name: string, tags: record, type: string>"
    protection-policies-create-or-update: "record<properties: record<backupManagementType: string, protectedItemsCount: int>, eTag: string, id: string, location: string, name: string, tags: record, type: string>"
    protection-policy-operation-results-get: "record<properties: record<backupManagementType: string, protectedItemsCount: int>, eTag: string, id: string, location: string, name: string, tags: record, type: string>"
    protection-policy-operation-statuses-get: "record<endTime: string, error: record<code: string, message: string>, id: string, name: string, properties: record<objectType: string>, startTime: string, status: string>"
    backup-protectable-items-list: "record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>, nextLink: string>"
    backup-protected-items-list: "record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>, nextLink: string>"
    backup-protection-containers-list: "record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>, nextLink: string>"
    security-pi-ns-get: "record<expiryTimeInUtcTicks: int, securityPIN: string, token: string>"
    backup-usage-summaries-list: "record<value: table<currentValue: int, limit: int, name: record, nextResetTime: string, quotaPeriod: string, unit: string>>"
    backup-resource-vault-configs-get: "record<properties: record<enhancedSecurityState: string, storageType: string, storageTypeState: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string>"
    backup-resource-vault-configs-update: "record<properties: record<enhancedSecurityState: string, storageType: string, storageTypeState: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string>"
    backup-resource-storage-configs-get: "record<properties: record<storageType: string, storageTypeState: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["backup-engines-list" "backup-engines-get" "protection-container-refresh-operation-results-get" "protection-containers-get" "protection-container-operation-results-get" "protected-items-delete" "protected-items-get" "protected-items-create-or-update" "backups-trigger" "protected-item-operation-results-get" "protected-item-operation-statuses-get" "recovery-points-list" "recovery-points-get" "item-level-recovery-connections-provision" "restores-trigger" "item-level-recovery-connections-revoke" "protection-containers-refresh" "export-jobs-operation-results-get" "job-cancellations-trigger" "job-operation-results-get" "jobs-export" "backup-operation-results-get" "backup-operation-statuses-get" "backup-policies-list" "protection-policies-delete" "protection-policies-get" "protection-policies-create-or-update" "protection-policy-operation-results-get" "protection-policy-operation-statuses-get" "backup-protectable-items-list" "backup-protected-items-list" "backup-protection-containers-list" "security-pi-ns-get" "backup-usage-summaries-list" "backup-resource-vault-configs-get" "backup-resource-vault-configs-update" "backup-resource-storage-configs-get" "backup-resource-storage-configs-update" "commands"] | sort) } | get name | first)
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

# Backup management servers registered to Recovery Services Vault. Returns a pageable list of servers.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupEngines
# Returns: record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>, nextLink: string>
# operationId: BackupEngines_List
export def "backup-engines-list" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --filter: string # OData filter options.
  --skip-token: string # skipToken Filter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupEngines"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}, {name: "$skipToken", var: skip_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, api_version: $api_version, filter: $filter, skip_token: $skip_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns backup management server registered to Recovery Services Vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupEngines/{backupEngineName}
# Returns: record<properties: record<azureBackupAgentVersion: string, backupEngineId: string, backupEngineState: string, backupEngineType: string, backupManagementType: string, canReRegister: bool, dpmVersion: string, extendedInfo: record<availableDiskSpace: float, azureProtectedInstances: int, databaseName: string, diskCount: int, protectedItemsCount: int, protectedServersCount: int, refreshedAt: string, usedDiskSpace: float>, friendlyName: string, healthStatus: string, isAzureBackupAgentUpgradeAvailable: bool, isDPMUpgradeAvailable: bool, registrationStatus: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string>
# operationId: BackupEngines_Get
export def "backup-engines-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  backup_engine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --filter: string # OData filter options.
  --skip-token: string # skipToken Filter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupEngines/{backupEngineName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: backupEngineName, var: backup_engine_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}, {name: "$skipToken", var: skip_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, backup_engine_name: $backup_engine_name, api_version: $api_version, filter: $filter, skip_token: $skip_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides the result of the refresh operation triggered by the BeginRefresh operation.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/operationResults/{operationId}
# operationId: ProtectionContainerRefreshOperationResults_Get
export def "protection-container-refresh-operation-results-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/operationResults/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: fabricName, var: fabric_name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, fabric_name: $fabric_name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details of the specific container registered to your Recovery Services Vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}
# Returns: record<properties: record<backupManagementType: string, containerType: string, friendlyName: string, healthStatus: string, protectableObjectType: string, registrationStatus: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string>
# operationId: ProtectionContainers_Get
export def "protection-containers-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: fabricName, var: fabric_name}, {name: containerName, var: container_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, fabric_name: $fabric_name, container_name: $container_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the result of any operation on the container.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/operationResults/{operationId}
# Returns: record<properties: record<backupManagementType: string, containerType: string, friendlyName: string, healthStatus: string, protectableObjectType: string, registrationStatus: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string>
# operationId: ProtectionContainerOperationResults_Get
export def "protection-container-operation-results-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/operationResults/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: fabricName, var: fabric_name}, {name: containerName, var: container_name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, fabric_name: $fabric_name, container_name: $container_name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Used to disable backup of an item within a container. This is an asynchronous operation. To know the status of the request, call the GetItemOperationResult API.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}
# operationId: ProtectedItems_Delete
export def "protected-items-delete" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: fabricName, var: fabric_name}, {name: containerName, var: container_name}, {name: protectedItemName, var: protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, fabric_name: $fabric_name, container_name: $container_name, protected_item_name: $protected_item_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides the details of the backed up item. This is an asynchronous operation. To know the status of the operation, call the GetItemOperationResult API.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}
# Returns: record<properties: record<backupManagementType: string, containerName: string, lastRecoveryPoint: string, policyId: string, protectedItemType: string, sourceResourceId: string, workloadType: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string>
# operationId: ProtectedItems_Get
export def "protected-items-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --filter: string # OData filter options.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: fabricName, var: fabric_name}, {name: containerName, var: container_name}, {name: protectedItemName, var: protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, fabric_name: $fabric_name, container_name: $container_name, protected_item_name: $protected_item_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables backup of an item or to modifies the backup policy information of an already backed up item. This is an asynchronous operation. To know the status of the operation, call the GetItemOperationResult API.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}
# operationId: ProtectedItems_CreateOrUpdate
export def "protected-items-create-or-update" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --properties: record # Base class for backup items. — shape: {backupManagementType?: "Invalid"|"AzureIaasVM"|"MAB"|"DPM"|"AzureBackupServer"|"AzureSql", containerName?: string, lastRecoveryPoint?: string, policyId?: string, protectedItemType: string, sourceResourceId?: string, workloadType?: "Invalid"|"VM"|"FileFolder"|"AzureSqlDb"|"SQLDB"|"Exchange"|"Sharepoint"|"VMwareVM"|"SystemState"|"Client"|"GenericDataSource"}
  --e-tag: string # Optional ETag.
  --location: string # Resource location.
  --tags: record # Resource tags.
]: any -> any {
  $in | http-request {
    method: put
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: fabricName, var: fabric_name}, {name: containerName, var: container_name}, {name: protectedItemName, var: protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: eTag, var: e_tag}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, fabric_name: $fabric_name, container_name: $container_name, protected_item_name: $protected_item_name, api_version: $api_version, properties: $properties, e_tag: $e_tag, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Triggers backup for specified backed up item. This is an asynchronous operation. To know the status of the operation, call GetProtectedItemOperationResult API.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/backup
# operationId: Backups_Trigger
export def "backups-trigger" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --properties: record # Base class for backup request. Workload-specific backup requests are derived from this class. — shape: {objectType: string}
  --e-tag: string # Optional ETag.
  --location: string # Resource location.
  --tags: record # Resource tags.
]: any -> any {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/backup"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: fabricName, var: fabric_name}, {name: containerName, var: container_name}, {name: protectedItemName, var: protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: eTag, var: e_tag}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, fabric_name: $fabric_name, container_name: $container_name, protected_item_name: $protected_item_name, api_version: $api_version, properties: $properties, e_tag: $e_tag, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the result of any operation on the backup item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/operationResults/{operationId}
# Returns: record<properties: record<backupManagementType: string, containerName: string, lastRecoveryPoint: string, policyId: string, protectedItemType: string, sourceResourceId: string, workloadType: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string>
# operationId: ProtectedItemOperationResults_Get
export def "protected-item-operation-results-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/operationResults/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: fabricName, var: fabric_name}, {name: containerName, var: container_name}, {name: protectedItemName, var: protected_item_name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, fabric_name: $fabric_name, container_name: $container_name, protected_item_name: $protected_item_name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the status of an operation such as triggering a backup, restore. The status can be in progress, completed or failed. You can refer to the OperationStatus enum for all the possible states of the operation. Some operations create jobs. This method returns the list of jobs associated with the operation.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/operationsStatus/{operationId}
# Returns: record<endTime: string, error: record<code: string, message: string>, id: string, name: string, properties: record<objectType: string>, startTime: string, status: string>
# operationId: ProtectedItemOperationStatuses_Get
export def "protected-item-operation-statuses-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/operationsStatus/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: fabricName, var: fabric_name}, {name: containerName, var: container_name}, {name: protectedItemName, var: protected_item_name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, fabric_name: $fabric_name, container_name: $container_name, protected_item_name: $protected_item_name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the backup copies for the backed up item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/recoveryPoints
# Returns: record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>, nextLink: string>
# operationId: RecoveryPoints_List
export def "recovery-points-list" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --filter: string # OData filter options.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/recoveryPoints"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: fabricName, var: fabric_name}, {name: containerName, var: container_name}, {name: protectedItemName, var: protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, fabric_name: $fabric_name, container_name: $container_name, protected_item_name: $protected_item_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides the information of the backed up data identified using RecoveryPointID. This is an asynchronous operation. To know the status of the operation, call the GetProtectedItemOperationResult API.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/recoveryPoints/{recoveryPointId}
# Returns: record<properties: record<objectType: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string>
# operationId: RecoveryPoints_Get
export def "recovery-points-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  recovery_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/recoveryPoints/{recoveryPointId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: fabricName, var: fabric_name}, {name: containerName, var: container_name}, {name: protectedItemName, var: protected_item_name}, {name: recoveryPointId, var: recovery_point_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, fabric_name: $fabric_name, container_name: $container_name, protected_item_name: $protected_item_name, recovery_point_id: $recovery_point_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provisions a script which invokes an iSCSI connection to the backup data. Executing this script opens a file explorer displaying all the recoverable files and folders. This is an asynchronous operation. To know the status of provisioning, call GetProtectedItemOperationResult API.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/recoveryPoints/{recoveryPointId}/provisionInstantItemRecovery
# operationId: ItemLevelRecoveryConnections_Provision
export def "item-level-recovery-connections-provision" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  recovery_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --properties: record # Parameters to restore file/folders API. — shape: {objectType: string}
  --e-tag: string # Optional ETag.
  --location: string # Resource location.
  --tags: record # Resource tags.
]: any -> any {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/recoveryPoints/{recoveryPointId}/provisionInstantItemRecovery"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: fabricName, var: fabric_name}, {name: containerName, var: container_name}, {name: protectedItemName, var: protected_item_name}, {name: recoveryPointId, var: recovery_point_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: eTag, var: e_tag}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, fabric_name: $fabric_name, container_name: $container_name, protected_item_name: $protected_item_name, recovery_point_id: $recovery_point_id, api_version: $api_version, properties: $properties, e_tag: $e_tag, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restores the specified backed up data. This is an asynchronous operation. To know the status of this API call, use GetProtectedItemOperationResult API.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/recoveryPoints/{recoveryPointId}/restore
# operationId: Restores_Trigger
export def "restores-trigger" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  recovery_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --properties: record # Base class for restore request. Workload-specific restore requests are derived from this class. — shape: {objectType: string}
  --e-tag: string # Optional ETag.
  --location: string # Resource location.
  --tags: record # Resource tags.
]: any -> any {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/recoveryPoints/{recoveryPointId}/restore"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: fabricName, var: fabric_name}, {name: containerName, var: container_name}, {name: protectedItemName, var: protected_item_name}, {name: recoveryPointId, var: recovery_point_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: eTag, var: e_tag}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, fabric_name: $fabric_name, container_name: $container_name, protected_item_name: $protected_item_name, recovery_point_id: $recovery_point_id, api_version: $api_version, properties: $properties, e_tag: $e_tag, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revokes an iSCSI connection which can be used to download a script. Executing this script opens a file explorer displaying all recoverable files and folders. This is an asynchronous operation.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/recoveryPoints/{recoveryPointId}/revokeInstantItemRecovery
# operationId: ItemLevelRecoveryConnections_Revoke
export def "item-level-recovery-connections-revoke" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  recovery_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/recoveryPoints/{recoveryPointId}/revokeInstantItemRecovery"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: fabricName, var: fabric_name}, {name: containerName, var: container_name}, {name: protectedItemName, var: protected_item_name}, {name: recoveryPointId, var: recovery_point_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, fabric_name: $fabric_name, container_name: $container_name, protected_item_name: $protected_item_name, recovery_point_id: $recovery_point_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Discovers all the containers in the subscription that can be backed up to Recovery Services Vault. This is an asynchronous operation. To know the status of the operation, call GetRefreshOperationResult API.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/refreshContainers
# operationId: ProtectionContainers_Refresh
export def "protection-containers-refresh" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/refreshContainers"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: fabricName, var: fabric_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, fabric_name: $fabric_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the operation result of operation triggered by Export Jobs API. If the operation is successful, then it also contains URL of a Blob and a SAS key to access the same. The blob contains exported jobs in JSON serialized format.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupJobs/operationResults/{operationId}
# Returns: record<operation: record<objectType: string>, Headers: record, statusCode: string>
# operationId: ExportJobsOperationResults_Get
export def "export-jobs-operation-results-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupJobs/operationResults/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a job. This is an asynchronous operation. To know the status of the cancellation, call GetCancelOperationResult API.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupJobs/{jobName}/cancel
# operationId: JobCancellations_Trigger
export def "job-cancellations-trigger" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupJobs/{jobName}/cancel"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: jobName, var: job_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, job_name: $job_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the result of any operation. the operation.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupJobs/{jobName}/operationResults/{operationId}
# operationId: JobOperationResults_Get
export def "job-operation-results-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  job_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupJobs/{jobName}/operationResults/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: jobName, var: job_name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, job_name: $job_name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Triggers export of jobs specified by filters and returns an OperationID to track.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupJobsExport
# operationId: Jobs_Export
export def "jobs-export" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --filter: string # OData filter options.
]: nothing -> any {
  http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupJobsExport"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides the status of the delete operations such as deleting backed up item. Once the operation has started, the status code in the response would be Accepted. It will continue to be in this state till it reaches completion. On successful completion, the status code will be OK. This method expects OperationID as an argument. OperationID is part of the Location header of the operation response.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupOperationResults/{operationId}
# operationId: BackupOperationResults_Get
export def "backup-operation-results-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupOperationResults/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the status of an operation such as triggering a backup, restore. The status can be in progress, completed or failed. You can refer to the OperationStatus enum for all the possible states of an operation. Some operations create jobs. This method returns the list of jobs when the operation is complete.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupOperations/{operationId}
# Returns: record<endTime: string, error: record<code: string, message: string>, id: string, name: string, properties: record<objectType: string>, startTime: string, status: string>
# operationId: BackupOperationStatuses_Get
export def "backup-operation-statuses-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupOperations/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists of backup policies associated with Recovery Services Vault. API provides pagination parameters to fetch scoped results.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupPolicies
# Returns: record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>, nextLink: string>
# operationId: BackupPolicies_List
export def "backup-policies-list" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --filter: string # OData filter options.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupPolicies"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes specified backup policy from your Recovery Services Vault. This is an asynchronous operation. Status of the operation can be fetched using GetPolicyOperationResult API.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupPolicies/{policyName}
# operationId: ProtectionPolicies_Delete
export def "protection-policies-delete" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupPolicies/{policyName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: policyName, var: policy_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, policy_name: $policy_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides the details of the backup policies associated to Recovery Services Vault. This is an asynchronous operation. Status of the operation can be fetched using GetPolicyOperationResult API.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupPolicies/{policyName}
# Returns: record<properties: record<backupManagementType: string, protectedItemsCount: int>, eTag: string, id: string, location: string, name: string, tags: record, type: string>
# operationId: ProtectionPolicies_Get
export def "protection-policies-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupPolicies/{policyName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: policyName, var: policy_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, policy_name: $policy_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or modifies a backup policy. This is an asynchronous operation. Status of the operation can be fetched using GetPolicyOperationResult API.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupPolicies/{policyName}
# Returns: record<properties: record<backupManagementType: string, protectedItemsCount: int>, eTag: string, id: string, location: string, name: string, tags: record, type: string>
# operationId: ProtectionPolicies_CreateOrUpdate
export def "protection-policies-create-or-update" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --properties: record # Base class for backup policy. Workload-specific backup policies are derived from this class. — shape: {backupManagementType: string, protectedItemsCount?: int}
  --e-tag: string # Optional ETag.
  --location: string # Resource location.
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupPolicies/{policyName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: policyName, var: policy_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: eTag, var: e_tag}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, policy_name: $policy_name, api_version: $api_version, properties: $properties, e_tag: $e_tag, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides the result of an operation.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupPolicies/{policyName}/operationResults/{operationId}
# Returns: record<properties: record<backupManagementType: string, protectedItemsCount: int>, eTag: string, id: string, location: string, name: string, tags: record, type: string>
# operationId: ProtectionPolicyOperationResults_Get
export def "protection-policy-operation-results-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  policy_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupPolicies/{policyName}/operationResults/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: policyName, var: policy_name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, policy_name: $policy_name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides the status of the asynchronous operations like backup, restore. The status can be in progress, completed or failed. You can refer to the Operation Status enum for all the possible states of an operation. Some operations create jobs. This method returns the list of jobs associated with operation.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupPolicies/{policyName}/operations/{operationId}
# Returns: record<endTime: string, error: record<code: string, message: string>, id: string, name: string, properties: record<objectType: string>, startTime: string, status: string>
# operationId: ProtectionPolicyOperationStatuses_Get
export def "protection-policy-operation-statuses-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  policy_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupPolicies/{policyName}/operations/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}, {name: policyName, var: policy_name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, policy_name: $policy_name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a pageable list of protectable objects within your subscription according to the query filter and the pagination parameters.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupProtectableItems
# Returns: record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>, nextLink: string>
# operationId: BackupProtectableItems_List
export def "backup-protectable-items-list" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --filter: string # OData filter options.
  --skip-token: string # skipToken Filter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupProtectableItems"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}, {name: "$skipToken", var: skip_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, api_version: $api_version, filter: $filter, skip_token: $skip_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a pageable list of all items that are backed up within a vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupProtectedItems
# Returns: record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>, nextLink: string>
# operationId: BackupProtectedItems_List
export def "backup-protected-items-list" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --filter: string # OData filter options.
  --skip-token: string # skipToken Filter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupProtectedItems"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}, {name: "$skipToken", var: skip_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, api_version: $api_version, filter: $filter, skip_token: $skip_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the containers registered to Recovery Services Vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupProtectionContainers
# Returns: record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>, nextLink: string>
# operationId: BackupProtectionContainers_List
export def "backup-protection-containers-list" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --filter: string # OData filter options.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupProtectionContainers"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the security PIN.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupSecurityPIN
# Returns: record<expiryTimeInUtcTicks: int, securityPIN: string, token: string>
# operationId: SecurityPINs_Get
export def "security-pi-ns-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupSecurityPIN"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the backup management usage summaries of the vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupUsageSummaries
# Returns: record<value: table<currentValue: int, limit: int, name: record, nextResetTime: string, quotaPeriod: string, unit: string>>
# operationId: BackupUsageSummaries_List
export def "backup-usage-summaries-list" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --filter: string # OData filter options.
  --skip-token: string # skipToken Filter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupUsageSummaries"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}, {name: "$skipToken", var: skip_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, api_version: $api_version, filter: $filter, skip_token: $skip_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches resource vault config.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupconfig/vaultconfig
# Returns: record<properties: record<enhancedSecurityState: string, storageType: string, storageTypeState: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string>
# operationId: BackupResourceVaultConfigs_Get
export def "backup-resource-vault-configs-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupconfig/vaultconfig"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates vault security config.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupconfig/vaultconfig
# Returns: record<properties: record<enhancedSecurityState: string, storageType: string, storageTypeState: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string>
# operationId: BackupResourceVaultConfigs_Update
export def "backup-resource-vault-configs-update" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
  --properties: record # Backup resource vault config details. — shape: {enhancedSecurityState?: "Invalid"|"Enabled"|"Disabled", storageType?: "Invalid"|"GeoRedundant"|"LocallyRedundant", storageTypeState?: "Invalid"|"Locked"|"Unlocked"}
  --e-tag: string # Optional ETag.
  --location: string # Resource location.
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupconfig/vaultconfig"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: eTag, var: e_tag}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, api_version: $api_version, properties: $properties, e_tag: $e_tag, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches resource storage config.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupstorageconfig/vaultstorageconfig
# Returns: record<properties: record<storageType: string, storageTypeState: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string>
# operationId: BackupResourceStorageConfigs_Get
export def "backup-resource-storage-configs-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupstorageconfig/vaultstorageconfig"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates vault storage model type.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupstorageconfig/vaultstorageconfig
# operationId: BackupResourceStorageConfigs_Update
export def "backup-resource-storage-configs-update" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: patch
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupstorageconfig/vaultstorageconfig"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vaultName, var: vault_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vault_name: $vault_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
