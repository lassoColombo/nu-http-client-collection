# Auto-generated client for SiteRecoveryManagementClient v2018-07-10
# Source: https://api.apis.guru/v2/specs/azure.com/recoveryservicessiterecovery-service/2018-07-10/swagger.json
# Auth: --token flag or $env.SITERECOVERYMANAGEMENTCLIENT_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "SITERECOVERYMANAGEMENTCLIENT_TOKEN"
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
    replication-eligibility-results-list: "record<value: table<id: string, name: string, properties: record, type: string>>"
    replication-eligibility-results-get: "record<id: string, name: string, properties: record<clientRequestId: string, errors: list<record>>, type: string>"
    operations-list: "record<nextLink: string, value: table<display: record, name: string, origin: string, properties: record>>"
    replication-alert-settings-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-alert-settings-get: "record<properties: record<customEmailAddresses: list<string>, locale: string, sendToOwners: string>, id: string, location: string, name: string, type: string>"
    replication-alert-settings-create: "record<properties: record<customEmailAddresses: list<string>, locale: string, sendToOwners: string>, id: string, location: string, name: string, type: string>"
    replication-events-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-events-get: "record<properties: record<affectedObjectFriendlyName: string, description: string, eventCode: string, eventSpecificDetails: record<instanceType: string>, eventType: string, fabricId: string, healthErrors: list<record>, providerSpecificDetails: record<instanceType: string>, severity: string, timeOfOccurrence: string>, id: string, location: string, name: string, type: string>"
    replication-fabrics-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-fabrics-get: "record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>, id: string, location: string, name: string, type: string>"
    replication-fabrics-create: "record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>, id: string, location: string, name: string, type: string>"
    replication-fabrics-check-consistency: "record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>, id: string, location: string, name: string, type: string>"
    replication-fabrics-reassociate-gateway: "record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>, id: string, location: string, name: string, type: string>"
    replication-fabrics-renew-certificate: "record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>, id: string, location: string, name: string, type: string>"
    replication-logical-networks-list-by-replication-fabrics: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-logical-networks-get: "record<properties: record<friendlyName: string, logicalNetworkDefinitionsStatus: string, logicalNetworkUsage: string, networkVirtualizationStatus: string>, id: string, location: string, name: string, type: string>"
    replication-networks-list-by-replication-fabrics: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-networks-get: "record<properties: record<fabricType: string, friendlyName: string, networkType: string, subnets: list<record>>, id: string, location: string, name: string, type: string>"
    replication-network-mappings-list-by-replication-networks: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-network-mappings-get: "record<properties: record<fabricSpecificSettings: record<instanceType: string>, primaryFabricFriendlyName: string, primaryNetworkFriendlyName: string, primaryNetworkId: string, recoveryFabricArmId: string, recoveryFabricFriendlyName: string, recoveryNetworkFriendlyName: string, recoveryNetworkId: string, state: string>, id: string, location: string, name: string, type: string>"
    replication-network-mappings-update: "record<properties: record<fabricSpecificSettings: record<instanceType: string>, primaryFabricFriendlyName: string, primaryNetworkFriendlyName: string, primaryNetworkId: string, recoveryFabricArmId: string, recoveryFabricFriendlyName: string, recoveryNetworkFriendlyName: string, recoveryNetworkId: string, state: string>, id: string, location: string, name: string, type: string>"
    replication-network-mappings-create: "record<properties: record<fabricSpecificSettings: record<instanceType: string>, primaryFabricFriendlyName: string, primaryNetworkFriendlyName: string, primaryNetworkId: string, recoveryFabricArmId: string, recoveryFabricFriendlyName: string, recoveryNetworkFriendlyName: string, recoveryNetworkId: string, state: string>, id: string, location: string, name: string, type: string>"
    replication-protection-containers-list-by-replication-fabrics: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-protection-containers-get: "record<properties: record<fabricFriendlyName: string, fabricSpecificDetails: record<instanceType: string>, fabricType: string, friendlyName: string, pairingStatus: string, protectedItemCount: int, role: string>, id: string, location: string, name: string, type: string>"
    replication-protection-containers-create: "record<properties: record<fabricFriendlyName: string, fabricSpecificDetails: record<instanceType: string>, fabricType: string, friendlyName: string, pairingStatus: string, protectedItemCount: int, role: string>, id: string, location: string, name: string, type: string>"
    replication-protection-containers-discover-protectable-item: "record<properties: record<fabricFriendlyName: string, fabricSpecificDetails: record<instanceType: string>, fabricType: string, friendlyName: string, pairingStatus: string, protectedItemCount: int, role: string>, id: string, location: string, name: string, type: string>"
    replication-migration-items-list-by-replication-protection-containers: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-migration-items-get: "record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>, id: string, location: string, name: string, type: string>"
    replication-migration-items-update: "record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>, id: string, location: string, name: string, type: string>"
    replication-migration-items-create: "record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>, id: string, location: string, name: string, type: string>"
    replication-migration-items-migrate: "record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>, id: string, location: string, name: string, type: string>"
    migration-recovery-points-list-by-replication-migration-items: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    migration-recovery-points-get: "record<properties: record<recoveryPointTime: string, recoveryPointType: string>, id: string, location: string, name: string, type: string>"
    replication-migration-items-test-migrate: "record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>, id: string, location: string, name: string, type: string>"
    replication-migration-items-test-migrate-cleanup: "record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>, id: string, location: string, name: string, type: string>"
    replication-protectable-items-list-by-replication-protection-containers: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-protectable-items-get: "record<properties: record<customDetails: record<instanceType: string>, friendlyName: string, protectionReadinessErrors: list<string>, protectionStatus: string, recoveryServicesProviderId: string, replicationProtectedItemId: string, supportedReplicationProviders: list<string>>, id: string, location: string, name: string, type: string>"
    replication-protected-items-list-by-replication-protection-containers: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-protected-items-get: "record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>"
    replication-protected-items-update: "record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>"
    replication-protected-items-create: "record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>"
    replication-protected-items-resolve-health-errors: "record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>"
    replication-protected-items-add-disks: "record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>"
    replication-protected-items-apply-recovery-point: "record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>"
    replication-protected-items-failover-commit: "record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>"
    replication-protected-items-planned-failover: "record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>"
    replication-protected-items-reprotect: "record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>"
    recovery-points-list-by-replication-protected-items: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    recovery-points-get: "record<properties: record<providerSpecificDetails: record<instanceType: string>, recoveryPointTime: string, recoveryPointType: string>, id: string, location: string, name: string, type: string>"
    replication-protected-items-remove-disks: "record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>"
    replication-protected-items-repair-replication: "record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>"
    target-compute-sizes-list-by-replication-protected-items: "record<nextLink: string, value: table<id: string, name: string, properties: record, type: string>>"
    replication-protected-items-test-failover: "record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>"
    replication-protected-items-test-failover-cleanup: "record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>"
    replication-protected-items-unplanned-failover: "record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>"
    replication-protected-items-update-mobility-service: "record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>"
    replication-protection-container-mappings-list-by-replication-protection-containers: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-protection-container-mappings-get: "record<properties: record<health: string, healthErrorDetails: list<record>, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, sourceFabricFriendlyName: string, sourceProtectionContainerFriendlyName: string, state: string, targetFabricFriendlyName: string, targetProtectionContainerFriendlyName: string, targetProtectionContainerId: string>, id: string, location: string, name: string, type: string>"
    replication-protection-container-mappings-update: "record<properties: record<health: string, healthErrorDetails: list<record>, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, sourceFabricFriendlyName: string, sourceProtectionContainerFriendlyName: string, state: string, targetFabricFriendlyName: string, targetProtectionContainerFriendlyName: string, targetProtectionContainerId: string>, id: string, location: string, name: string, type: string>"
    replication-protection-container-mappings-create: "record<properties: record<health: string, healthErrorDetails: list<record>, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, sourceFabricFriendlyName: string, sourceProtectionContainerFriendlyName: string, state: string, targetFabricFriendlyName: string, targetProtectionContainerFriendlyName: string, targetProtectionContainerId: string>, id: string, location: string, name: string, type: string>"
    replication-protection-containers-switch-protection: "record<properties: record<fabricFriendlyName: string, fabricSpecificDetails: record<instanceType: string>, fabricType: string, friendlyName: string, pairingStatus: string, protectedItemCount: int, role: string>, id: string, location: string, name: string, type: string>"
    replication-recovery-services-providers-list-by-replication-fabrics: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-recovery-services-providers-get: "record<properties: record<allowedScenarios: list<string>, authenticationIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, connectionStatus: string, draIdentifier: string, fabricFriendlyName: string, fabricType: string, friendlyName: string, healthErrorDetails: list<record>, lastHeartBeat: string, protectedItemCount: int, providerVersion: string, providerVersionDetails: record<expiryDate: string, status: string, version: string>, providerVersionExpiryDate: string, providerVersionState: string, resourceAccessIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, serverVersion: string>, id: string, location: string, name: string, type: string>"
    replication-recovery-services-providers-create: "record<properties: record<allowedScenarios: list<string>, authenticationIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, connectionStatus: string, draIdentifier: string, fabricFriendlyName: string, fabricType: string, friendlyName: string, healthErrorDetails: list<record>, lastHeartBeat: string, protectedItemCount: int, providerVersion: string, providerVersionDetails: record<expiryDate: string, status: string, version: string>, providerVersionExpiryDate: string, providerVersionState: string, resourceAccessIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, serverVersion: string>, id: string, location: string, name: string, type: string>"
    replication-recovery-services-providers-refresh-provider: "record<properties: record<allowedScenarios: list<string>, authenticationIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, connectionStatus: string, draIdentifier: string, fabricFriendlyName: string, fabricType: string, friendlyName: string, healthErrorDetails: list<record>, lastHeartBeat: string, protectedItemCount: int, providerVersion: string, providerVersionDetails: record<expiryDate: string, status: string, version: string>, providerVersionExpiryDate: string, providerVersionState: string, resourceAccessIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, serverVersion: string>, id: string, location: string, name: string, type: string>"
    replication-storage-classifications-list-by-replication-fabrics: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-storage-classifications-get: "record<properties: record<friendlyName: string>, id: string, location: string, name: string, type: string>"
    replication-storage-classification-mappings-list-by-replication-storage-classifications: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-storage-classification-mappings-get: "record<properties: record<targetStorageClassificationId: string>, id: string, location: string, name: string, type: string>"
    replication-storage-classification-mappings-create: "record<properties: record<targetStorageClassificationId: string>, id: string, location: string, name: string, type: string>"
    replicationv-centers-list-by-replication-fabrics: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replicationv-centers-get: "record<properties: record<discoveryStatus: string, fabricArmResourceName: string, friendlyName: string, healthErrors: list<record>, infrastructureId: string, internalId: string, ipAddress: string, lastHeartbeat: string, port: string, processServerId: string, runAsAccountId: string>, id: string, location: string, name: string, type: string>"
    replicationv-centers-update: "record<properties: record<discoveryStatus: string, fabricArmResourceName: string, friendlyName: string, healthErrors: list<record>, infrastructureId: string, internalId: string, ipAddress: string, lastHeartbeat: string, port: string, processServerId: string, runAsAccountId: string>, id: string, location: string, name: string, type: string>"
    replicationv-centers-create: "record<properties: record<discoveryStatus: string, fabricArmResourceName: string, friendlyName: string, healthErrors: list<record>, infrastructureId: string, internalId: string, ipAddress: string, lastHeartbeat: string, port: string, processServerId: string, runAsAccountId: string>, id: string, location: string, name: string, type: string>"
    replication-jobs-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-jobs-export: "record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>, id: string, location: string, name: string, type: string>"
    replication-jobs-get: "record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>, id: string, location: string, name: string, type: string>"
    replication-jobs-cancel: "record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>, id: string, location: string, name: string, type: string>"
    replication-jobs-restart: "record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>, id: string, location: string, name: string, type: string>"
    replication-jobs-resume: "record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>, id: string, location: string, name: string, type: string>"
    replication-migration-items-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-network-mappings-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-networks-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-policies-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-policies-get: "record<properties: record<friendlyName: string, providerSpecificDetails: record<instanceType: string>>, id: string, location: string, name: string, type: string>"
    replication-policies-update: "record<properties: record<friendlyName: string, providerSpecificDetails: record<instanceType: string>>, id: string, location: string, name: string, type: string>"
    replication-policies-create: "record<properties: record<friendlyName: string, providerSpecificDetails: record<instanceType: string>>, id: string, location: string, name: string, type: string>"
    replication-protected-items-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-protection-container-mappings-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-protection-containers-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-recovery-plans-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-recovery-plans-get: "record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>, id: string, location: string, name: string, type: string>"
    replication-recovery-plans-update: "record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>, id: string, location: string, name: string, type: string>"
    replication-recovery-plans-create: "record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>, id: string, location: string, name: string, type: string>"
    replication-recovery-plans-failover-commit: "record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>, id: string, location: string, name: string, type: string>"
    replication-recovery-plans-planned-failover: "record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>, id: string, location: string, name: string, type: string>"
    replication-recovery-plans-reprotect: "record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>, id: string, location: string, name: string, type: string>"
    replication-recovery-plans-test-failover: "record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>, id: string, location: string, name: string, type: string>"
    replication-recovery-plans-test-failover-cleanup: "record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>, id: string, location: string, name: string, type: string>"
    replication-recovery-plans-unplanned-failover: "record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>, id: string, location: string, name: string, type: string>"
    replication-recovery-services-providers-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-storage-classification-mappings-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-storage-classifications-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    supported-operating-systems-get: "record<properties: record<supportedOsList: list<record>>, id: string, location: string, name: string, type: string>"
    replication-vault-health-get: "record<properties: record<containersHealth: record<issues: list, resourceCount: int>, fabricsHealth: record<issues: list, resourceCount: int>, protectedItemsHealth: record<issues: list, resourceCount: int>, vaultErrors: list<record>>, id: string, location: string, name: string, type: string>"
    replication-vault-health-refresh: "record<properties: record<containersHealth: record<issues: list, resourceCount: int>, fabricsHealth: record<issues: list, resourceCount: int>, protectedItemsHealth: record<issues: list, resourceCount: int>, vaultErrors: list<record>>, id: string, location: string, name: string, type: string>"
    replication-vault-setting-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
    replication-vault-setting-get: "record<properties: record<migrationSolutionId: string>, id: string, location: string, name: string, type: string>"
    replication-vault-setting-create: "record<properties: record<migrationSolutionId: string>, id: string, location: string, name: string, type: string>"
    replicationv-centers-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["replication-eligibility-results-list" "replication-eligibility-results-get" "operations-list" "replication-alert-settings-list" "replication-alert-settings-get" "replication-alert-settings-create" "replication-events-list" "replication-events-get" "replication-fabrics-list" "replication-fabrics-purge" "replication-fabrics-get" "replication-fabrics-create" "replication-fabrics-check-consistency" "replication-fabrics-migrate-to-aad" "replication-fabrics-reassociate-gateway" "replication-fabrics-delete" "replication-fabrics-renew-certificate" "replication-logical-networks-list-by-replication-fabrics" "replication-logical-networks-get" "replication-networks-list-by-replication-fabrics" "replication-networks-get" "replication-network-mappings-list-by-replication-networks" "replication-network-mappings-delete" "replication-network-mappings-get" "replication-network-mappings-update" "replication-network-mappings-create" "replication-protection-containers-list-by-replication-fabrics" "replication-protection-containers-get" "replication-protection-containers-create" "replication-protection-containers-discover-protectable-item" "replication-protection-containers-delete" "replication-migration-items-list-by-replication-protection-containers" "replication-migration-items-delete" "replication-migration-items-get" "replication-migration-items-update" "replication-migration-items-create" "replication-migration-items-migrate" "migration-recovery-points-list-by-replication-migration-items" "migration-recovery-points-get" "replication-migration-items-test-migrate" "replication-migration-items-test-migrate-cleanup" "replication-protectable-items-list-by-replication-protection-containers" "replication-protectable-items-get" "replication-protected-items-list-by-replication-protection-containers" "replication-protected-items-purge" "replication-protected-items-get" "replication-protected-items-update" "replication-protected-items-create" "replication-protected-items-resolve-health-errors" "replication-protected-items-add-disks" "replication-protected-items-apply-recovery-point" "replication-protected-items-failover-commit" "replication-protected-items-planned-failover" "replication-protected-items-reprotect" "recovery-points-list-by-replication-protected-items" "recovery-points-get" "replication-protected-items-delete" "replication-protected-items-remove-disks" "replication-protected-items-repair-replication" "target-compute-sizes-list-by-replication-protected-items" "replication-protected-items-test-failover" "replication-protected-items-test-failover-cleanup" "replication-protected-items-unplanned-failover" "replication-protected-items-update-mobility-service" "replication-protection-container-mappings-list-by-replication-protection-containers" "replication-protection-container-mappings-purge" "replication-protection-container-mappings-get" "replication-protection-container-mappings-update" "replication-protection-container-mappings-create" "replication-protection-container-mappings-delete" "replication-protection-containers-switch-protection" "replication-recovery-services-providers-list-by-replication-fabrics" "replication-recovery-services-providers-purge" "replication-recovery-services-providers-get" "replication-recovery-services-providers-create" "replication-recovery-services-providers-refresh-provider" "replication-recovery-services-providers-delete" "replication-storage-classifications-list-by-replication-fabrics" "replication-storage-classifications-get" "replication-storage-classification-mappings-list-by-replication-storage-classifications" "replication-storage-classification-mappings-delete" "replication-storage-classification-mappings-get" "replication-storage-classification-mappings-create" "replicationv-centers-list-by-replication-fabrics" "replicationv-centers-delete" "replicationv-centers-get" "replicationv-centers-update" "replicationv-centers-create" "replication-jobs-list" "replication-jobs-export" "replication-jobs-get" "replication-jobs-cancel" "replication-jobs-restart" "replication-jobs-resume" "replication-migration-items-list" "replication-network-mappings-list" "replication-networks-list" "replication-policies-list" "replication-policies-delete" "replication-policies-get" "replication-policies-update" "replication-policies-create" "replication-protected-items-list" "replication-protection-container-mappings-list" "replication-protection-containers-list" "replication-recovery-plans-list" "replication-recovery-plans-delete" "replication-recovery-plans-get" "replication-recovery-plans-update" "replication-recovery-plans-create" "replication-recovery-plans-failover-commit" "replication-recovery-plans-planned-failover" "replication-recovery-plans-reprotect" "replication-recovery-plans-test-failover" "replication-recovery-plans-test-failover-cleanup" "replication-recovery-plans-unplanned-failover" "replication-recovery-services-providers-list" "replication-storage-classification-mappings-list" "replication-storage-classifications-list" "supported-operating-systems-get" "replication-vault-health-get" "replication-vault-health-refresh" "replication-vault-setting-list" "replication-vault-setting-get" "replication-vault-setting-create" "replicationv-centers-list" "commands"] | sort) } | get name | first)
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

# Gets the validation errors in case the VM is unsuitable for protection.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{virtualMachineName}/providers/Microsoft.RecoveryServices/replicationEligibilityResults
# Returns: record<value: table<id: string, name: string, properties: record, type: string>>
# operationId: ReplicationEligibilityResults_List
export def "replication-eligibility-results-list" [
  subscription_id: string
  resource_group_name: string
  virtual_machine_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{virtualMachineName}/providers/Microsoft.RecoveryServices/replicationEligibilityResults"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualMachineName, var: virtual_machine_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_machine_name: $virtual_machine_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the validation errors in case the VM is unsuitable for protection.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{virtualMachineName}/providers/Microsoft.RecoveryServices/replicationEligibilityResults/default
# Returns: record<id: string, name: string, properties: record<clientRequestId: string, errors: list<record>>, type: string>
# operationId: ReplicationEligibilityResults_Get
export def "replication-eligibility-results-get" [
  subscription_id: string
  resource_group_name: string
  virtual_machine_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{virtualMachineName}/providers/Microsoft.RecoveryServices/replicationEligibilityResults/default"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualMachineName, var: virtual_machine_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_machine_name: $virtual_machine_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of available operations.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/operations
# Returns: record<nextLink: string, value: table<display: record, name: string, origin: string, properties: record>>
# operationId: Operations_List
export def "operations-list" [
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/operations"
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

# Gets the list of configured email notification(alert) configurations.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationAlertSettings
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationAlertSettings_List
export def "replication-alert-settings-list" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationAlertSettings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an email notification(alert) configuration.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationAlertSettings/{alertSettingName}
# Returns: record<properties: record<customEmailAddresses: list<string>, locale: string, sendToOwners: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationAlertSettings_Get
export def "replication-alert-settings-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  alert_setting_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationAlertSettings/{alertSettingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: alertSettingName, var: alert_setting_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, alert_setting_name: $alert_setting_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configures email notifications for this vault.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationAlertSettings/{alertSettingName}
# Returns: record<properties: record<customEmailAddresses: list<string>, locale: string, sendToOwners: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationAlertSettings_Create
export def "replication-alert-settings-create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  alert_setting_name: string
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
  --properties: record # Properties of a configure alert request. — shape: {customEmailAddresses?: list<string>, locale?: string, sendToOwners?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationAlertSettings/{alertSettingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: alertSettingName, var: alert_setting_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, alert_setting_name: $alert_setting_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of Azure Site Recovery events.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationEvents
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationEvents_List
export def "replication-events-list" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
  --filter: string # OData filter options.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationEvents"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the details of an Azure Site recovery event.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationEvents/{eventName}
# Returns: record<properties: record<affectedObjectFriendlyName: string, description: string, eventCode: string, eventSpecificDetails: record<instanceType: string>, eventType: string, fabricId: string, healthErrors: list<record>, providerSpecificDetails: record<instanceType: string>, severity: string, timeOfOccurrence: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationEvents_Get
export def "replication-events-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  event_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationEvents/{eventName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: eventName, var: event_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, event_name: $event_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of ASR fabrics
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationFabrics_List
export def "replication-fabrics-list" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Purges the site.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}
# operationId: ReplicationFabrics_Purge
export def "replication-fabrics-purge" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
    method: delete
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of an ASR fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}
# Returns: record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationFabrics_Get
export def "replication-fabrics-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Azure Site Recovery fabric.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}
# Returns: record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationFabrics_Create
export def "replication-fabrics-create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
  --properties: record # Properties of site details provided during the time of site creation — shape: {customDetails?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks the consistency of the ASR fabric.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/checkConsistency
# Returns: record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationFabrics_CheckConsistency
export def "replication-fabrics-check-consistency" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/checkConsistency"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Migrates the site to AAD.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/migratetoaad
# operationId: ReplicationFabrics_MigrateToAad
export def "replication-fabrics-migrate-to-aad" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/migratetoaad"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform failover of the process server.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/reassociateGateway
# Returns: record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationFabrics_ReassociateGateway
export def "replication-fabrics-reassociate-gateway" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
  --properties: record # The properties of the Failover Process Server request. — shape: {containerName?: string, sourceProcessServerId?: string, targetProcessServerId?: string, updateType?: string, vmsToMigrate?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/reassociateGateway"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the site.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/remove
# operationId: ReplicationFabrics_Delete
export def "replication-fabrics-delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/remove"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Renews certificate for the fabric.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/renewCertificate
# Returns: record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationFabrics_RenewCertificate
export def "replication-fabrics-renew-certificate" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
  --properties: record # Renew Certificate input properties. — shape: {renewCertificateType?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/renewCertificate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of logical networks under a fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationLogicalNetworks
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationLogicalNetworks_ListByReplicationFabrics
export def "replication-logical-networks-list-by-replication-fabrics" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationLogicalNetworks"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a logical network with specified server id and logical network name.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationLogicalNetworks/{logicalNetworkName}
# Returns: record<properties: record<friendlyName: string, logicalNetworkDefinitionsStatus: string, logicalNetworkUsage: string, networkVirtualizationStatus: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationLogicalNetworks_Get
export def "replication-logical-networks-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  logical_network_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationLogicalNetworks/{logicalNetworkName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: logicalNetworkName, var: logical_network_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, logical_network_name: $logical_network_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of networks under a fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationNetworks_ListByReplicationFabrics
export def "replication-networks-list-by-replication-fabrics" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a network with specified server id and network name.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}
# Returns: record<properties: record<fabricType: string, friendlyName: string, networkType: string, subnets: list<record>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationNetworks_Get
export def "replication-networks-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  network_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: networkName, var: network_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, network_name: $network_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the network mappings under a network.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationNetworkMappings_ListByReplicationNetworks
export def "replication-network-mappings-list-by-replication-networks" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  network_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: networkName, var: network_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, network_name: $network_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete network mapping.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings/{networkMappingName}
# operationId: ReplicationNetworkMappings_Delete
export def "replication-network-mappings-delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  network_name: string
  network_mapping_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings/{networkMappingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: networkName, var: network_name}, {name: networkMappingName, var: network_mapping_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, network_name: $network_name, network_mapping_name: $network_mapping_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets network mapping by name.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings/{networkMappingName}
# Returns: record<properties: record<fabricSpecificSettings: record<instanceType: string>, primaryFabricFriendlyName: string, primaryNetworkFriendlyName: string, primaryNetworkId: string, recoveryFabricArmId: string, recoveryFabricFriendlyName: string, recoveryNetworkFriendlyName: string, recoveryNetworkId: string, state: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationNetworkMappings_Get
export def "replication-network-mappings-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  network_name: string
  network_mapping_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings/{networkMappingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: networkName, var: network_name}, {name: networkMappingName, var: network_mapping_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, network_name: $network_name, network_mapping_name: $network_mapping_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates network mapping.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings/{networkMappingName}
# Returns: record<properties: record<fabricSpecificSettings: record<instanceType: string>, primaryFabricFriendlyName: string, primaryNetworkFriendlyName: string, primaryNetworkId: string, recoveryFabricArmId: string, recoveryFabricFriendlyName: string, recoveryNetworkFriendlyName: string, recoveryNetworkId: string, state: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationNetworkMappings_Update
export def "replication-network-mappings-update" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  network_name: string
  network_mapping_name: string
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
  --properties: record # Common input details for network mapping operation. — shape: {fabricSpecificDetails?: record, recoveryFabricName?: string, recoveryNetworkId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings/{networkMappingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: networkName, var: network_name}, {name: networkMappingName, var: network_mapping_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, network_name: $network_name, network_mapping_name: $network_mapping_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates network mapping.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings/{networkMappingName}
# Returns: record<properties: record<fabricSpecificSettings: record<instanceType: string>, primaryFabricFriendlyName: string, primaryNetworkFriendlyName: string, primaryNetworkId: string, recoveryFabricArmId: string, recoveryFabricFriendlyName: string, recoveryNetworkFriendlyName: string, recoveryNetworkId: string, state: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationNetworkMappings_Create
export def "replication-network-mappings-create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  network_name: string
  network_mapping_name: string
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
  --properties: record # Common input details for network mapping operation. — shape: {fabricSpecificDetails?: record, recoveryFabricName?: string, recoveryNetworkId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings/{networkMappingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: networkName, var: network_name}, {name: networkMappingName, var: network_mapping_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, network_name: $network_name, network_mapping_name: $network_mapping_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of protection container for a fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationProtectionContainers_ListByReplicationFabrics
export def "replication-protection-containers-list-by-replication-fabrics" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the protection container details.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}
# Returns: record<properties: record<fabricFriendlyName: string, fabricSpecificDetails: record<instanceType: string>, fabricType: string, friendlyName: string, pairingStatus: string, protectedItemCount: int, role: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectionContainers_Get
export def "replication-protection-containers-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a protection container.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}
# Returns: record<properties: record<fabricFriendlyName: string, fabricSpecificDetails: record<instanceType: string>, fabricType: string, friendlyName: string, pairingStatus: string, protectedItemCount: int, role: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectionContainers_Create
export def "replication-protection-containers-create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
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
  --properties: record # Create protection container input properties. — shape: {providerSpecificInput?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a protectable item to the replication protection container.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/discoverProtectableItem
# Returns: record<properties: record<fabricFriendlyName: string, fabricSpecificDetails: record<instanceType: string>, fabricType: string, friendlyName: string, pairingStatus: string, protectedItemCount: int, role: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectionContainers_DiscoverProtectableItem
export def "replication-protection-containers-discover-protectable-item" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
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
  --properties: record # Discover protectable item properties. — shape: {friendlyName?: string, ipAddress?: string, osType?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/discoverProtectableItem"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a protection container.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/remove
# operationId: ReplicationProtectionContainers_Delete
export def "replication-protection-containers-delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/remove"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of migration items in the protection container.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationMigrationItems_ListByReplicationProtectionContainers
export def "replication-migration-items-list-by-replication-protection-containers" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the migration item.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}
# operationId: ReplicationMigrationItems_Delete
export def "replication-migration-items-delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  migration_item_name: string
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
  --delete-option: string # The delete option.
]: nothing -> any {
  http-request {
    method: delete
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: migrationItemName, var: migration_item_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: deleteOption, var: delete_option}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, migration_item_name: $migration_item_name, api_version: $api_version, delete_option: $delete_option
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of a migration item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}
# Returns: record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationMigrationItems_Get
export def "replication-migration-items-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  migration_item_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: migrationItemName, var: migration_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, migration_item_name: $migration_item_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates migration item.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}
# Returns: record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationMigrationItems_Update
export def "replication-migration-items-update" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  migration_item_name: string
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
  --properties: record # Update migration item input properties. — shape: {providerSpecificDetails: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: migrationItemName, var: migration_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, migration_item_name: $migration_item_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables migration.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}
# Returns: record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationMigrationItems_Create
export def "replication-migration-items-create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  migration_item_name: string
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
  properties: record # Enable migration input properties. — shape: {policyId: string, providerSpecificDetails: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: migrationItemName, var: migration_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, migration_item_name: $migration_item_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Migrate item.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/migrate
# Returns: record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationMigrationItems_Migrate
export def "replication-migration-items-migrate" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  migration_item_name: string
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
  properties: record # Migrate input properties. — shape: {providerSpecificDetails: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/migrate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: migrationItemName, var: migration_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, migration_item_name: $migration_item_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the recovery points for a migration item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/migrationRecoveryPoints
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: MigrationRecoveryPoints_ListByReplicationMigrationItems
export def "migration-recovery-points-list-by-replication-migration-items" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  migration_item_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/migrationRecoveryPoints"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: migrationItemName, var: migration_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, migration_item_name: $migration_item_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a recovery point for a migration item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/migrationRecoveryPoints/{migrationRecoveryPointName}
# Returns: record<properties: record<recoveryPointTime: string, recoveryPointType: string>, id: string, location: string, name: string, type: string>
# operationId: MigrationRecoveryPoints_Get
export def "migration-recovery-points-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  migration_item_name: string
  migration_recovery_point_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/migrationRecoveryPoints/{migrationRecoveryPointName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: migrationItemName, var: migration_item_name}, {name: migrationRecoveryPointName, var: migration_recovery_point_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, migration_item_name: $migration_item_name, migration_recovery_point_name: $migration_recovery_point_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test migrate item.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/testMigrate
# Returns: record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationMigrationItems_TestMigrate
export def "replication-migration-items-test-migrate" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  migration_item_name: string
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
  properties: record # Test migrate input properties. — shape: {providerSpecificDetails: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/testMigrate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: migrationItemName, var: migration_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, migration_item_name: $migration_item_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test migrate cleanup.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/testMigrateCleanup
# Returns: record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationMigrationItems_TestMigrateCleanup
export def "replication-migration-items-test-migrate-cleanup" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  migration_item_name: string
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
  properties: record # Test migrate cleanup input properties. — shape: {comments?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/testMigrateCleanup"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: migrationItemName, var: migration_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, migration_item_name: $migration_item_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of protectable items.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectableItems
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationProtectableItems_ListByReplicationProtectionContainers
export def "replication-protectable-items-list-by-replication-protection-containers" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectableItems"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of a protectable item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectableItems/{protectableItemName}
# Returns: record<properties: record<customDetails: record<instanceType: string>, friendlyName: string, protectionReadinessErrors: list<string>, protectionStatus: string, recoveryServicesProviderId: string, replicationProtectedItemId: string, supportedReplicationProviders: list<string>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectableItems_Get
export def "replication-protectable-items-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  protectable_item_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectableItems/{protectableItemName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: protectableItemName, var: protectable_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, protectable_item_name: $protectable_item_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of Replication protected items.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationProtectedItems_ListByReplicationProtectionContainers
export def "replication-protected-items-list-by-replication-protection-containers" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Purges protection.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}
# operationId: ReplicationProtectedItems_Purge
export def "replication-protected-items-purge" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of a Replication protected item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}
# Returns: record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectedItems_Get
export def "replication-protected-items-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates protection.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}
# Returns: record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectedItems_Update
export def "replication-protected-items-update" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
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
  --properties: record # Update protected item input properties. — shape: {enableRdpOnTargetOption?: string, licenseType?: "NotSpecified"|"NoLicenseType"|"WindowsServer", providerSpecificDetails?: record, recoveryAvailabilitySetId?: string, recoveryAzureVMName?: string, recoveryAzureVMSize?: string, selectedRecoveryAzureNetworkId?: string, selectedSourceNicId?: string, selectedTfoAzureNetworkId?: string, vmNics?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables protection.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}
# Returns: record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectedItems_Create
export def "replication-protected-items-create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
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
  --properties: record # Enable protection input properties. — shape: {policyId?: string, protectableItemId?: string, providerSpecificDetails?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resolve health errors.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/ResolveHealthErrors
# Returns: record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectedItems_ResolveHealthErrors
export def "replication-protected-items-resolve-health-errors" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
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
  --properties: record # Resolve health input properties. — shape: {healthErrors?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/ResolveHealthErrors"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add disk(s) for protection.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/addDisks
# Returns: record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectedItems_AddDisks
export def "replication-protected-items-add-disks" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
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
  --properties: record # Add Disks input properties. — shape: {providerSpecificDetails?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/addDisks"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change or apply recovery point.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/applyRecoveryPoint
# Returns: record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectedItems_ApplyRecoveryPoint
export def "replication-protected-items-apply-recovery-point" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
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
  --properties: record # Input properties to apply recovery point. — shape: {providerSpecificDetails?: record, recoveryPointId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/applyRecoveryPoint"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute commit failover
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/failoverCommit
# Returns: record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectedItems_FailoverCommit
export def "replication-protected-items-failover-commit" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/failoverCommit"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute planned failover
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/plannedFailover
# Returns: record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectedItems_PlannedFailover
export def "replication-protected-items-planned-failover" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
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
  --properties: record # Input definition for planned failover input properties. — shape: {failoverDirection?: string, providerSpecificDetails?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/plannedFailover"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute Reverse Replication\Reprotect
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/reProtect
# Returns: record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectedItems_Reprotect
export def "replication-protected-items-reprotect" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
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
  --properties: record # Reverse replication input properties. — shape: {failoverDirection?: string, providerSpecificDetails?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/reProtect"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get recovery points for a replication protected item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/recoveryPoints
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: RecoveryPoints_ListByReplicationProtectedItems
export def "recovery-points-list-by-replication-protected-items" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/recoveryPoints"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a recovery point.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/recoveryPoints/{recoveryPointName}
# Returns: record<properties: record<providerSpecificDetails: record<instanceType: string>, recoveryPointTime: string, recoveryPointType: string>, id: string, location: string, name: string, type: string>
# operationId: RecoveryPoints_Get
export def "recovery-points-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  recovery_point_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/recoveryPoints/{recoveryPointName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}, {name: recoveryPointName, var: recovery_point_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, recovery_point_name: $recovery_point_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables protection.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/remove
# operationId: ReplicationProtectedItems_Delete
export def "replication-protected-items-delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
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
  --properties: record # Disable protection input properties. — shape: {disableProtectionReason?: "NotSpecified"|"MigrationComplete", replicationProviderInput?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/remove"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes disk(s).
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/removeDisks
# Returns: record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectedItems_RemoveDisks
export def "replication-protected-items-remove-disks" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
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
  --properties: record # Remove Disk input properties. — shape: {providerSpecificDetails?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/removeDisks"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resynchronize or repair replication.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/repairReplication
# Returns: record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectedItems_RepairReplication
export def "replication-protected-items-repair-replication" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/repairReplication"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of target compute sizes for the replication protected item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/targetComputeSizes
# Returns: record<nextLink: string, value: table<id: string, name: string, properties: record, type: string>>
# operationId: TargetComputeSizes_ListByReplicationProtectedItems
export def "target-compute-sizes-list-by-replication-protected-items" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/targetComputeSizes"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute test failover
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/testFailover
# Returns: record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectedItems_TestFailover
export def "replication-protected-items-test-failover" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
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
  --properties: record # Input definition for planned failover input properties. — shape: {failoverDirection?: string, networkId?: string, networkType?: string, providerSpecificDetails?: record, skipTestFailoverCleanup?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/testFailover"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute test failover cleanup.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/testFailoverCleanup
# Returns: record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectedItems_TestFailoverCleanup
export def "replication-protected-items-test-failover-cleanup" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
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
  properties: record # Input definition for test failover cleanup input properties. — shape: {comments?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/testFailoverCleanup"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute unplanned failover
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/unplannedFailover
# Returns: record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectedItems_UnplannedFailover
export def "replication-protected-items-unplanned-failover" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
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
  --properties: record # Input definition for planned failover input properties. — shape: {failoverDirection?: string, providerSpecificDetails?: record, sourceSiteOperations?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/unplannedFailover"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicatedProtectedItemName, var: replicated_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replicated_protected_item_name: $replicated_protected_item_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the mobility service on a protected item.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicationProtectedItemName}/updateMobilityService
# Returns: record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectedItems_UpdateMobilityService
export def "replication-protected-items-update-mobility-service" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replication_protected_item_name: string
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
  --properties: record # The properties of an update mobility service request. — shape: {runAsAccountId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicationProtectedItemName}/updateMobilityService"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: replicationProtectedItemName, var: replication_protected_item_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, replication_protected_item_name: $replication_protected_item_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of protection container mappings for a protection container.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationProtectionContainerMappings_ListByReplicationProtectionContainers
export def "replication-protection-container-mappings-list-by-replication-protection-containers" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Purge protection container mapping.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}
# operationId: ReplicationProtectionContainerMappings_Purge
export def "replication-protection-container-mappings-purge" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  mapping_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: mappingName, var: mapping_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, mapping_name: $mapping_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a protection container mapping/
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}
# Returns: record<properties: record<health: string, healthErrorDetails: list<record>, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, sourceFabricFriendlyName: string, sourceProtectionContainerFriendlyName: string, state: string, targetFabricFriendlyName: string, targetProtectionContainerFriendlyName: string, targetProtectionContainerId: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectionContainerMappings_Get
export def "replication-protection-container-mappings-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  mapping_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: mappingName, var: mapping_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, mapping_name: $mapping_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update protection container mapping.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}
# Returns: record<properties: record<health: string, healthErrorDetails: list<record>, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, sourceFabricFriendlyName: string, sourceProtectionContainerFriendlyName: string, state: string, targetFabricFriendlyName: string, targetProtectionContainerFriendlyName: string, targetProtectionContainerId: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectionContainerMappings_Update
export def "replication-protection-container-mappings-update" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  mapping_name: string
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
  --properties: record # Container pairing update input. — shape: {providerSpecificInput?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: mappingName, var: mapping_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, mapping_name: $mapping_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create protection container mapping.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}
# Returns: record<properties: record<health: string, healthErrorDetails: list<record>, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, sourceFabricFriendlyName: string, sourceProtectionContainerFriendlyName: string, state: string, targetFabricFriendlyName: string, targetProtectionContainerFriendlyName: string, targetProtectionContainerId: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectionContainerMappings_Create
export def "replication-protection-container-mappings-create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  mapping_name: string
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
  --properties: record # Configure pairing input properties. — shape: {policyId?: string, providerSpecificInput?: record, targetProtectionContainerId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: mappingName, var: mapping_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, mapping_name: $mapping_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove protection container mapping.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}/remove
# operationId: ReplicationProtectionContainerMappings_Delete
export def "replication-protection-container-mappings-delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  mapping_name: string
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
  --properties: record # Unpairing input properties. — shape: {providerSpecificInput?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}/remove"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}, {name: mappingName, var: mapping_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, mapping_name: $mapping_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Switches protection from one container to another or one replication provider to another.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/switchprotection
# Returns: record<properties: record<fabricFriendlyName: string, fabricSpecificDetails: record<instanceType: string>, fabricType: string, friendlyName: string, pairingStatus: string, protectedItemCount: int, role: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationProtectionContainers_SwitchProtection
export def "replication-protection-containers-switch-protection" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
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
  --properties: record # Switch protection input properties. — shape: {providerSpecificDetails?: record, replicationProtectedItemName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/switchprotection"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: protectionContainerName, var: protection_container_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, protection_container_name: $protection_container_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of registered recovery services providers for the fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationRecoveryServicesProviders_ListByReplicationFabrics
export def "replication-recovery-services-providers-list-by-replication-fabrics" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Purges recovery service provider from fabric
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}
# operationId: ReplicationRecoveryServicesProviders_Purge
export def "replication-recovery-services-providers-purge" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  provider_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: providerName, var: provider_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, provider_name: $provider_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of a recovery services provider.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}
# Returns: record<properties: record<allowedScenarios: list<string>, authenticationIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, connectionStatus: string, draIdentifier: string, fabricFriendlyName: string, fabricType: string, friendlyName: string, healthErrorDetails: list<record>, lastHeartBeat: string, protectedItemCount: int, providerVersion: string, providerVersionDetails: record<expiryDate: string, status: string, version: string>, providerVersionExpiryDate: string, providerVersionState: string, resourceAccessIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, serverVersion: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationRecoveryServicesProviders_Get
export def "replication-recovery-services-providers-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  provider_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: providerName, var: provider_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, provider_name: $provider_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a recovery services provider.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}
# Returns: record<properties: record<allowedScenarios: list<string>, authenticationIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, connectionStatus: string, draIdentifier: string, fabricFriendlyName: string, fabricType: string, friendlyName: string, healthErrorDetails: list<record>, lastHeartBeat: string, protectedItemCount: int, providerVersion: string, providerVersionDetails: record<expiryDate: string, status: string, version: string>, providerVersionExpiryDate: string, providerVersionState: string, resourceAccessIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, serverVersion: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationRecoveryServicesProviders_Create
export def "replication-recovery-services-providers-create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  provider_name: string
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
  properties: record # The properties of an add provider request. — shape: {authenticationIdentityInput: record, machineName: string, resourceAccessIdentityInput: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: providerName, var: provider_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, provider_name: $provider_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refresh details from the recovery services provider.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}/refreshProvider
# Returns: record<properties: record<allowedScenarios: list<string>, authenticationIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, connectionStatus: string, draIdentifier: string, fabricFriendlyName: string, fabricType: string, friendlyName: string, healthErrorDetails: list<record>, lastHeartBeat: string, protectedItemCount: int, providerVersion: string, providerVersionDetails: record<expiryDate: string, status: string, version: string>, providerVersionExpiryDate: string, providerVersionState: string, resourceAccessIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, serverVersion: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationRecoveryServicesProviders_RefreshProvider
export def "replication-recovery-services-providers-refresh-provider" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  provider_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}/refreshProvider"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: providerName, var: provider_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, provider_name: $provider_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes provider from fabric. Note: Deleting provider for any fabric other than SingleHost is unsupported. To maintain backward compatibility for released clients the object "deleteRspInput" is used (if the object is empty we assume that it is old client and continue the old behavior).
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}/remove
# operationId: ReplicationRecoveryServicesProviders_Delete
export def "replication-recovery-services-providers-delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  provider_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}/remove"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: providerName, var: provider_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, provider_name: $provider_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of storage classification objects under a fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationStorageClassifications_ListByReplicationFabrics
export def "replication-storage-classifications-list-by-replication-fabrics" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of a storage classification.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}
# Returns: record<properties: record<friendlyName: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationStorageClassifications_Get
export def "replication-storage-classifications-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  storage_classification_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: storageClassificationName, var: storage_classification_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, storage_classification_name: $storage_classification_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of storage classification mappings objects under a storage.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}/replicationStorageClassificationMappings
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationStorageClassificationMappings_ListByReplicationStorageClassifications
export def "replication-storage-classification-mappings-list-by-replication-storage-classifications" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  storage_classification_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}/replicationStorageClassificationMappings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: storageClassificationName, var: storage_classification_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, storage_classification_name: $storage_classification_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a storage classification mapping.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}/replicationStorageClassificationMappings/{storageClassificationMappingName}
# operationId: ReplicationStorageClassificationMappings_Delete
export def "replication-storage-classification-mappings-delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  storage_classification_name: string
  storage_classification_mapping_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}/replicationStorageClassificationMappings/{storageClassificationMappingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: storageClassificationName, var: storage_classification_name}, {name: storageClassificationMappingName, var: storage_classification_mapping_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, storage_classification_name: $storage_classification_name, storage_classification_mapping_name: $storage_classification_mapping_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of a storage classification mapping.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}/replicationStorageClassificationMappings/{storageClassificationMappingName}
# Returns: record<properties: record<targetStorageClassificationId: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationStorageClassificationMappings_Get
export def "replication-storage-classification-mappings-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  storage_classification_name: string
  storage_classification_mapping_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}/replicationStorageClassificationMappings/{storageClassificationMappingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: storageClassificationName, var: storage_classification_name}, {name: storageClassificationMappingName, var: storage_classification_mapping_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, storage_classification_name: $storage_classification_name, storage_classification_mapping_name: $storage_classification_mapping_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create storage classification mapping.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}/replicationStorageClassificationMappings/{storageClassificationMappingName}
# Returns: record<properties: record<targetStorageClassificationId: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationStorageClassificationMappings_Create
export def "replication-storage-classification-mappings-create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  storage_classification_name: string
  storage_classification_mapping_name: string
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
  --properties: record # Storage mapping input properties. — shape: {targetStorageClassificationId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}/replicationStorageClassificationMappings/{storageClassificationMappingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: storageClassificationName, var: storage_classification_name}, {name: storageClassificationMappingName, var: storage_classification_mapping_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, storage_classification_name: $storage_classification_name, storage_classification_mapping_name: $storage_classification_mapping_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of vCenter registered under a fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationvCenters_ListByReplicationFabrics
export def "replicationv-centers-list-by-replication-fabrics" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove vCenter operation.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters/{vCenterName}
# operationId: ReplicationvCenters_Delete
export def "replicationv-centers-delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  v_center_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters/{vCenterName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: vCenterName, var: v_center_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, v_center_name: $v_center_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of a vCenter.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters/{vCenterName}
# Returns: record<properties: record<discoveryStatus: string, fabricArmResourceName: string, friendlyName: string, healthErrors: list<record>, infrastructureId: string, internalId: string, ipAddress: string, lastHeartbeat: string, port: string, processServerId: string, runAsAccountId: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationvCenters_Get
export def "replicationv-centers-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  v_center_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters/{vCenterName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: vCenterName, var: v_center_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, v_center_name: $v_center_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update vCenter operation.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters/{vCenterName}
# Returns: record<properties: record<discoveryStatus: string, fabricArmResourceName: string, friendlyName: string, healthErrors: list<record>, infrastructureId: string, internalId: string, ipAddress: string, lastHeartbeat: string, port: string, processServerId: string, runAsAccountId: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationvCenters_Update
export def "replicationv-centers-update" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  v_center_name: string
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
  --properties: record # The properties of an update vCenter request. — shape: {friendlyName?: string, ipAddress?: string, port?: string, processServerId?: string, runAsAccountId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters/{vCenterName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: vCenterName, var: v_center_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, v_center_name: $v_center_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add vCenter.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters/{vCenterName}
# Returns: record<properties: record<discoveryStatus: string, fabricArmResourceName: string, friendlyName: string, healthErrors: list<record>, infrastructureId: string, internalId: string, ipAddress: string, lastHeartbeat: string, port: string, processServerId: string, runAsAccountId: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationvCenters_Create
export def "replicationv-centers-create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  v_center_name: string
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
  --properties: record # The properties of an add vCenter request. — shape: {friendlyName?: string, ipAddress?: string, port?: string, processServerId?: string, runAsAccountId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters/{vCenterName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: fabricName, var: fabric_name}, {name: vCenterName, var: v_center_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, fabric_name: $fabric_name, v_center_name: $v_center_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of jobs.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationJobs_List
export def "replication-jobs-list" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
  --filter: string # OData filter options.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports the details of the Azure Site Recovery jobs of the vault.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/export
# Returns: record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationJobs_Export
export def "replication-jobs-export" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
  --affected-object-types: string # The type of objects.
  --end-time: string # Date time to get jobs up to.
  --fabric-id: string # The Id of the fabric to search jobs under.
  --job-status: string # The states of the job to be filtered can be in.
  --start-time: string # Date time to get jobs from.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/export"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: affectedObjectTypes, var: affected_object_types}, {name: endTime, var: end_time}, {name: fabricId, var: fabric_id}, {name: jobStatus, var: job_status}, {name: startTime, var: start_time}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version, affected_object_types: $affected_object_types, end_time: $end_time, fabric_id: $fabric_id, job_status: $job_status, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the job details.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/{jobName}
# Returns: record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationJobs_Get
export def "replication-jobs-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/{jobName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: jobName, var: job_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, job_name: $job_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels the specified job.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/{jobName}/cancel
# Returns: record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationJobs_Cancel
export def "replication-jobs-cancel" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/{jobName}/cancel"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: jobName, var: job_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, job_name: $job_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restarts the specified job.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/{jobName}/restart
# Returns: record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationJobs_Restart
export def "replication-jobs-restart" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/{jobName}/restart"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: jobName, var: job_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, job_name: $job_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resumes the specified job.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/{jobName}/resume
# Returns: record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationJobs_Resume
export def "replication-jobs-resume" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
  --properties: record # Resume job properties. — shape: {comments?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/{jobName}/resume"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: jobName, var: job_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, job_name: $job_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of migration items in the vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationMigrationItems
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationMigrationItems_List
export def "replication-migration-items-list" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
  --skip-token: string # The pagination token.
  --filter: string # OData filter options.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationMigrationItems"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: skipToken, var: skip_token}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version, skip_token: $skip_token, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the network mappings under a vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationNetworkMappings
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationNetworkMappings_List
export def "replication-network-mappings-list" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationNetworkMappings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of networks. View-only API.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationNetworks
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationNetworks_List
export def "replication-networks-list" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationNetworks"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of replication policies
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationPolicies_List
export def "replication-policies-list" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the policy.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies/{policyName}
# operationId: ReplicationPolicies_Delete
export def "replication-policies-delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies/{policyName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: policyName, var: policy_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, policy_name: $policy_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the requested policy.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies/{policyName}
# Returns: record<properties: record<friendlyName: string, providerSpecificDetails: record<instanceType: string>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationPolicies_Get
export def "replication-policies-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies/{policyName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: policyName, var: policy_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, policy_name: $policy_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the policy.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies/{policyName}
# Returns: record<properties: record<friendlyName: string, providerSpecificDetails: record<instanceType: string>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationPolicies_Update
export def "replication-policies-update" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
  --properties: record # Policy update properties. — shape: {replicationProviderSettings?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies/{policyName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: policyName, var: policy_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, policy_name: $policy_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates the policy.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies/{policyName}
# Returns: record<properties: record<friendlyName: string, providerSpecificDetails: record<instanceType: string>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationPolicies_Create
export def "replication-policies-create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
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
  --properties: record # Policy creation properties. — shape: {providerSpecificInput?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies/{policyName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: policyName, var: policy_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, policy_name: $policy_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of replication protected items.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationProtectedItems
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationProtectedItems_List
export def "replication-protected-items-list" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
  --skip-token: string # The pagination token. Possible values: "FabricId" or "FabricId_CloudId" or null
  --filter: string # OData filter options.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationProtectedItems"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: skipToken, var: skip_token}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version, skip_token: $skip_token, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of all protection container mappings in a vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationProtectionContainerMappings
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationProtectionContainerMappings_List
export def "replication-protection-container-mappings-list" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationProtectionContainerMappings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of all protection containers in a vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationProtectionContainers
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationProtectionContainers_List
export def "replication-protection-containers-list" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationProtectionContainers"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of recovery plans.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationRecoveryPlans_List
export def "replication-recovery-plans-list" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified recovery plan.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}
# operationId: ReplicationRecoveryPlans_Delete
export def "replication-recovery-plans-delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: recoveryPlanName, var: recovery_plan_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, recovery_plan_name: $recovery_plan_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the requested recovery plan.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}
# Returns: record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationRecoveryPlans_Get
export def "replication-recovery-plans-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: recoveryPlanName, var: recovery_plan_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, recovery_plan_name: $recovery_plan_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the given recovery plan.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}
# Returns: record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationRecoveryPlans_Update
export def "replication-recovery-plans-update" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
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
  --properties: record # Recovery plan update properties. — shape: {groups?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: recoveryPlanName, var: recovery_plan_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, recovery_plan_name: $recovery_plan_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a recovery plan with the given details.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}
# Returns: record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationRecoveryPlans_Create
export def "replication-recovery-plans-create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
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
  properties: record # Recovery plan creation properties. — shape: {failoverDeploymentModel?: "NotApplicable"|"Classic"|"ResourceManager", groups: list, primaryFabricId: string, recoveryFabricId: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: recoveryPlanName, var: recovery_plan_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, recovery_plan_name: $recovery_plan_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute commit failover of the recovery plan.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/failoverCommit
# Returns: record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationRecoveryPlans_FailoverCommit
export def "replication-recovery-plans-failover-commit" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/failoverCommit"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: recoveryPlanName, var: recovery_plan_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, recovery_plan_name: $recovery_plan_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute planned failover of the recovery plan.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/plannedFailover
# Returns: record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationRecoveryPlans_PlannedFailover
export def "replication-recovery-plans-planned-failover" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
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
  properties: record # Recovery plan planned failover input properties. — shape: {failoverDirection: "PrimaryToRecovery"|"RecoveryToPrimary", providerSpecificDetails?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/plannedFailover"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: recoveryPlanName, var: recovery_plan_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, recovery_plan_name: $recovery_plan_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute reprotect of the recovery plan.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/reProtect
# Returns: record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationRecoveryPlans_Reprotect
export def "replication-recovery-plans-reprotect" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/reProtect"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: recoveryPlanName, var: recovery_plan_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, recovery_plan_name: $recovery_plan_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute test failover of the recovery plan.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/testFailover
# Returns: record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationRecoveryPlans_TestFailover
export def "replication-recovery-plans-test-failover" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
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
  properties: record # Recovery plan test failover input properties. — shape: {failoverDirection: "PrimaryToRecovery"|"RecoveryToPrimary", networkId?: string, networkType: string, providerSpecificDetails?: list, skipTestFailoverCleanup?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/testFailover"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: recoveryPlanName, var: recovery_plan_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, recovery_plan_name: $recovery_plan_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute test failover cleanup of the recovery plan.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/testFailoverCleanup
# Returns: record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationRecoveryPlans_TestFailoverCleanup
export def "replication-recovery-plans-test-failover-cleanup" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
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
  properties: record # Recovery plan test failover cleanup input properties. — shape: {comments?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/testFailoverCleanup"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: recoveryPlanName, var: recovery_plan_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, recovery_plan_name: $recovery_plan_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute unplanned failover of the recovery plan.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/unplannedFailover
# Returns: record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationRecoveryPlans_UnplannedFailover
export def "replication-recovery-plans-unplanned-failover" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
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
  properties: record # Recovery plan unplanned failover input properties. — shape: {failoverDirection: "PrimaryToRecovery"|"RecoveryToPrimary", providerSpecificDetails?: list, sourceSiteOperations: "Required"|"NotRequired"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/unplannedFailover"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: recoveryPlanName, var: recovery_plan_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, recovery_plan_name: $recovery_plan_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of registered recovery services providers in the vault. This is a view only api.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryServicesProviders
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationRecoveryServicesProviders_List
export def "replication-recovery-services-providers-list" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryServicesProviders"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of storage classification mappings objects under a vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationStorageClassificationMappings
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationStorageClassificationMappings_List
export def "replication-storage-classification-mappings-list" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationStorageClassificationMappings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of storage classification objects under a vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationStorageClassifications
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationStorageClassifications_List
export def "replication-storage-classifications-list" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationStorageClassifications"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the data of supported OSes by SRS.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationSupportedOperatingSystems
# Returns: record<properties: record<supportedOsList: list<record>>, id: string, location: string, name: string, type: string>
# operationId: SupportedOperatingSystems_Get
export def "supported-operating-systems-get" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationSupportedOperatingSystems"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the health summary for the vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultHealth
# Returns: record<properties: record<containersHealth: record<issues: list, resourceCount: int>, fabricsHealth: record<issues: list, resourceCount: int>, protectedItemsHealth: record<issues: list, resourceCount: int>, vaultErrors: list<record>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationVaultHealth_Get
export def "replication-vault-health-get" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultHealth"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refreshes health summary of the vault.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultHealth/default/refresh
# Returns: record<properties: record<containersHealth: record<issues: list, resourceCount: int>, fabricsHealth: record<issues: list, resourceCount: int>, protectedItemsHealth: record<issues: list, resourceCount: int>, vaultErrors: list<record>>, id: string, location: string, name: string, type: string>
# operationId: ReplicationVaultHealth_Refresh
export def "replication-vault-health-refresh" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultHealth/default/refresh"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of vault setting.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultSettings
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationVaultSetting_List
export def "replication-vault-setting-list" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultSettings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the vault setting.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultSettings/{vaultSettingName}
# Returns: record<properties: record<migrationSolutionId: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationVaultSetting_Get
export def "replication-vault-setting-get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  vault_setting_name: string
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
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultSettings/{vaultSettingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: vaultSettingName, var: vault_setting_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, vault_setting_name: $vault_setting_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates vault setting. A vault setting object is a singleton per vault and it is always present by default.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultSettings/{vaultSettingName}
# Returns: record<properties: record<migrationSolutionId: string>, id: string, location: string, name: string, type: string>
# operationId: ReplicationVaultSetting_Create
export def "replication-vault-setting-create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  vault_setting_name: string
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
  properties: record # Input to create vault setting. — shape: {migrationSolutionId: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultSettings/{vaultSettingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}, {name: vaultSettingName, var: vault_setting_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, vault_setting_name: $vault_setting_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of vCenter registered under the vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationvCenters
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, type: string>>
# operationId: ReplicationvCenters_List
export def "replicationv-centers-list" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationvCenters"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: resourceName, var: resource_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, resource_name: $resource_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
