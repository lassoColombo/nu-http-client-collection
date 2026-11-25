# Auto-generated client for CustomerInsightsManagementClient v2017-04-26
# Source: https://api.apis.guru/v2/specs/azure.com/customer-insights/2017-04-26/swagger.json
# Auth: --token flag or $env.CUSTOMERINSIGHTSMANAGEMENTCLIENT_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "CUSTOMERINSIGHTSMANAGEMENTCLIENT_TOKEN"
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
def status-completer [] { ["Active" "Deleted" "Discovering" "Evaluating" "EvaluatingFailed" "Failed" "Featuring" "FeaturingFailed" "HumanIntervention" "New" "PendingDiscovering" "PendingFeaturing" "PendingModelConfirmation" "PendingTraining" "Provisioning" "ProvisioningFailed" "Training" "TrainingFailed"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    operations-list: "record<nextLink: string, value: table<display: record, name: string>>"
    hubs-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    hubs-list-by-resource-group: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    hubs-get: "record<properties: record<apiEndpoint: string, hubBillingInfo: record<maxUnits: int, minUnits: int, skuName: string>, provisioningState: string, tenantFeatures: int, webEndpoint: string>, id: string, location: string, name: string, tags: record, type: string>"
    hubs-update: "record<properties: record<apiEndpoint: string, hubBillingInfo: record<maxUnits: int, minUnits: int, skuName: string>, provisioningState: string, tenantFeatures: int, webEndpoint: string>, id: string, location: string, name: string, tags: record, type: string>"
    hubs-create-or-update: "record<properties: record<apiEndpoint: string, hubBillingInfo: record<maxUnits: int, minUnits: int, skuName: string>, provisioningState: string, tenantFeatures: int, webEndpoint: string>, id: string, location: string, name: string, tags: record, type: string>"
    authorization-policies-list-by-hub: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    authorization-policies-get: "record<properties: record<permissions: list<string>, policyName: string, primaryKey: string, secondaryKey: string>, id: string, name: string, type: string>"
    authorization-policies-create-or-update: "record<properties: record<permissions: list<string>, policyName: string, primaryKey: string, secondaryKey: string>, id: string, name: string, type: string>"
    authorization-policies-regenerate-primary-key: "record<permissions: list<string>, policyName: string, primaryKey: string, secondaryKey: string>"
    authorization-policies-regenerate-secondary-key: "record<permissions: list<string>, policyName: string, primaryKey: string, secondaryKey: string>"
    connectors-list-by-hub: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    connectors-get: "record<properties: record<connectorId: int, connectorName: string, connectorProperties: record, connectorType: string, created: string, description: string, displayName: string, isInternal: bool, lastModified: string, state: string, tenantId: string>, id: string, name: string, type: string>"
    connectors-create-or-update: "record<properties: record<connectorId: int, connectorName: string, connectorProperties: record, connectorType: string, created: string, description: string, displayName: string, isInternal: bool, lastModified: string, state: string, tenantId: string>, id: string, name: string, type: string>"
    connector-mappings-list-by-connector: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    connector-mappings-get: "record<properties: record<connectorMappingName: string, connectorName: string, connectorType: string, created: string, dataFormatId: string, description: string, displayName: string, entityType: string, entityTypeName: string, lastModified: string, mappingProperties: record<availability: record, completeOperation: record, errorManagement: record, fileFilter: string, folderPath: string, format: record, hasHeader: bool, structure: list>, nextRunTime: string, runId: string, state: string, tenantId: string>, id: string, name: string, type: string>"
    connector-mappings-create-or-update: "record<properties: record<connectorMappingName: string, connectorName: string, connectorType: string, created: string, dataFormatId: string, description: string, displayName: string, entityType: string, entityTypeName: string, lastModified: string, mappingProperties: record<availability: record, completeOperation: record, errorManagement: record, fileFilter: string, folderPath: string, format: record, hasHeader: bool, structure: list>, nextRunTime: string, runId: string, state: string, tenantId: string>, id: string, name: string, type: string>"
    images-get-upload-url-for-data: "record<contentUrl: string, imageExists: bool, relativePath: string>"
    images-get-upload-url-for-entity-type: "record<contentUrl: string, imageExists: bool, relativePath: string>"
    interactions-list-by-hub: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    interactions-get: "record<properties: record<dataSourcePrecedenceRules: list<record>, defaultDataSource: record<dataSourceReferenceId: string, dataSourceType: string, id: int, name: string, status: string>, idPropertyNames: list<string>, isActivity: bool, participantProfiles: list<record>, primaryParticipantProfilePropertyName: string, apiEntitySetName: string, entityType: string, fields: list<record>, instancesCount: int, lastChangedUtc: string, provisioningState: string, schemaItemTypeLink: string, tenantId: string, timestampFieldName: string, typeName: string, attributes: record, description: record, displayName: record, largeImage: string, localizedAttributes: record, mediumImage: string, smallImage: string>, id: string, name: string, type: string>"
    interactions-create-or-update: "record<properties: record<dataSourcePrecedenceRules: list<record>, defaultDataSource: record<dataSourceReferenceId: string, dataSourceType: string, id: int, name: string, status: string>, idPropertyNames: list<string>, isActivity: bool, participantProfiles: list<record>, primaryParticipantProfilePropertyName: string, apiEntitySetName: string, entityType: string, fields: list<record>, instancesCount: int, lastChangedUtc: string, provisioningState: string, schemaItemTypeLink: string, tenantId: string, timestampFieldName: string, typeName: string, attributes: record, description: record, displayName: record, largeImage: string, localizedAttributes: record, mediumImage: string, smallImage: string>, id: string, name: string, type: string>"
    interactions-suggest-relationship-links: "record<interactionName: string, suggestedRelationships: table<existingRelationshipName: string, profileName: string, profilePropertyReferences: list, relatedProfileName: string, relatedProfilePropertyReferences: list>>"
    kpi-list-by-hub: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    kpi-get: "record<properties: record<aliases: list<record>, calculationWindow: string, calculationWindowFieldName: string, description: record, displayName: record, entityType: string, entityTypeName: string, expression: string, extracts: list<record>, filter: string, function: string, groupBy: list<string>, groupByMetadata: list<record>, kpiName: string, participantProfilesMetadata: list<record>, provisioningState: string, tenantId: string, thresHolds: record<increasingKpi: bool, lowerLimit: float, upperLimit: float>, unit: string>, id: string, name: string, type: string>"
    kpi-create-or-update: "record<properties: record<aliases: list<record>, calculationWindow: string, calculationWindowFieldName: string, description: record, displayName: record, entityType: string, entityTypeName: string, expression: string, extracts: list<record>, filter: string, function: string, groupBy: list<string>, groupByMetadata: list<record>, kpiName: string, participantProfilesMetadata: list<record>, provisioningState: string, tenantId: string, thresHolds: record<increasingKpi: bool, lowerLimit: float, upperLimit: float>, unit: string>, id: string, name: string, type: string>"
    links-list-by-hub: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    links-get: "record<properties: record<description: record, displayName: record, linkName: string, mappings: list<record>, operationType: string, participantPropertyReferences: list<record>, provisioningState: string, referenceOnly: bool, sourceEntityType: string, sourceEntityTypeName: string, targetEntityType: string, targetEntityTypeName: string, tenantId: string>, id: string, name: string, type: string>"
    links-create-or-update: "record<properties: record<description: record, displayName: record, linkName: string, mappings: list<record>, operationType: string, participantPropertyReferences: list<record>, provisioningState: string, referenceOnly: bool, sourceEntityType: string, sourceEntityTypeName: string, targetEntityType: string, targetEntityTypeName: string, tenantId: string>, id: string, name: string, type: string>"
    predictions-list-by-hub: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    predictions-get: "record<properties: record<autoAnalyze: bool, description: record, displayName: record, grades: list<record>, involvedInteractionTypes: list<string>, involvedKpiTypes: list<string>, involvedRelationships: list<string>, mappings: record<grade: string, reason: string, score: string>, negativeOutcomeExpression: string, positiveOutcomeExpression: string, predictionName: string, primaryProfileType: string, provisioningState: string, scopeExpression: string, scoreLabel: string, systemGeneratedEntities: record<generatedInteractionTypes: list, generatedKpis: record, generatedLinks: list>, tenantId: string>, id: string, name: string, type: string>"
    predictions-create-or-update: "record<properties: record<autoAnalyze: bool, description: record, displayName: record, grades: list<record>, involvedInteractionTypes: list<string>, involvedKpiTypes: list<string>, involvedRelationships: list<string>, mappings: record<grade: string, reason: string, score: string>, negativeOutcomeExpression: string, positiveOutcomeExpression: string, predictionName: string, primaryProfileType: string, provisioningState: string, scopeExpression: string, scoreLabel: string, systemGeneratedEntities: record<generatedInteractionTypes: list, generatedKpis: record, generatedLinks: list>, tenantId: string>, id: string, name: string, type: string>"
    predictions-get-model-status: "record<message: string, modelVersion: string, predictionGuidId: string, predictionName: string, signalsUsed: int, status: string, tenantId: string, testSetCount: int, trainingAccuracy: int, trainingSetCount: int, validationSetCount: int>"
    predictions-get-training-results: "record<canonicalProfiles: table<canonicalProfileId: int, properties: list>, predictionDistribution: record<distributions: list<record>, totalNegatives: int, totalPositives: int>, primaryProfileInstanceCount: int, scoreName: string, tenantId: string>"
    profiles-list-by-hub: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    profiles-get: "record<properties: record<strongIds: list<record>, apiEntitySetName: string, entityType: string, fields: list<record>, instancesCount: int, lastChangedUtc: string, provisioningState: string, schemaItemTypeLink: string, tenantId: string, timestampFieldName: string, typeName: string, attributes: record, description: record, displayName: record, largeImage: string, localizedAttributes: record, mediumImage: string, smallImage: string>, id: string, name: string, type: string>"
    profiles-create-or-update: "record<properties: record<strongIds: list<record>, apiEntitySetName: string, entityType: string, fields: list<record>, instancesCount: int, lastChangedUtc: string, provisioningState: string, schemaItemTypeLink: string, tenantId: string, timestampFieldName: string, typeName: string, attributes: record, description: record, displayName: record, largeImage: string, localizedAttributes: record, mediumImage: string, smallImage: string>, id: string, name: string, type: string>"
    profiles-get-enriching-kpis: "table<aliases: list<record>, calculationWindow: string, calculationWindowFieldName: string, description: record, displayName: record, entityType: string, entityTypeName: string, expression: string, extracts: list<record>, filter: string, function: string, groupBy: list<string>, groupByMetadata: list<record>, kpiName: string, participantProfilesMetadata: list<record>, provisioningState: string, tenantId: string, thresHolds: record<increasingKpi: bool, lowerLimit: float, upperLimit: float>, unit: string>"
    relationship-links-list-by-hub: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    relationship-links-get: "record<properties: record<description: record, displayName: record, interactionType: string, linkName: string, mappings: list<record>, profilePropertyReferences: list<record>, provisioningState: string, relatedProfilePropertyReferences: list<record>, relationshipGuidId: string, relationshipName: string, tenantId: string>, id: string, name: string, type: string>"
    relationship-links-create-or-update: "record<properties: record<description: record, displayName: record, interactionType: string, linkName: string, mappings: list<record>, profilePropertyReferences: list<record>, provisioningState: string, relatedProfilePropertyReferences: list<record>, relationshipGuidId: string, relationshipName: string, tenantId: string>, id: string, name: string, type: string>"
    relationships-list-by-hub: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    relationships-get: "record<properties: record<cardinality: string, description: record, displayName: record, expiryDateTimeUtc: string, fields: list<record>, lookupMappings: list<record>, profileType: string, provisioningState: string, relatedProfileType: string, relationshipGuidId: string, relationshipName: string, tenantId: string>, id: string, name: string, type: string>"
    relationships-create-or-update: "record<properties: record<cardinality: string, description: record, displayName: record, expiryDateTimeUtc: string, fields: list<record>, lookupMappings: list<record>, profileType: string, provisioningState: string, relatedProfileType: string, relationshipGuidId: string, relationshipName: string, tenantId: string>, id: string, name: string, type: string>"
    role-assignments-list-by-hub: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    role-assignments-get: "record<properties: record<assignmentName: string, conflationPolicies: record<elements: list, exceptions: list>, connectors: record<elements: list, exceptions: list>, description: record, displayName: record, interactions: record<elements: list, exceptions: list>, kpis: record<elements: list, exceptions: list>, links: record<elements: list, exceptions: list>, principals: list<record>, profiles: record<elements: list, exceptions: list>, provisioningState: string, relationshipLinks: record<elements: list, exceptions: list>, relationships: record<elements: list, exceptions: list>, role: string, roleAssignments: record<elements: list, exceptions: list>, sasPolicies: record<elements: list, exceptions: list>, segments: record<elements: list, exceptions: list>, tenantId: string, views: record<elements: list, exceptions: list>, widgetTypes: record<elements: list, exceptions: list>>, id: string, name: string, type: string>"
    role-assignments-create-or-update: "record<properties: record<assignmentName: string, conflationPolicies: record<elements: list, exceptions: list>, connectors: record<elements: list, exceptions: list>, description: record, displayName: record, interactions: record<elements: list, exceptions: list>, kpis: record<elements: list, exceptions: list>, links: record<elements: list, exceptions: list>, principals: list<record>, profiles: record<elements: list, exceptions: list>, provisioningState: string, relationshipLinks: record<elements: list, exceptions: list>, relationships: record<elements: list, exceptions: list>, role: string, roleAssignments: record<elements: list, exceptions: list>, sasPolicies: record<elements: list, exceptions: list>, segments: record<elements: list, exceptions: list>, tenantId: string, views: record<elements: list, exceptions: list>, widgetTypes: record<elements: list, exceptions: list>>, id: string, name: string, type: string>"
    roles-list-by-hub: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    views-list-by-hub: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    views-get: "record<properties: record<changed: string, created: string, definition: string, displayName: record, tenantId: string, userId: string, viewName: string>, id: string, name: string, type: string>"
    views-create-or-update: "record<properties: record<changed: string, created: string, definition: string, displayName: record, tenantId: string, userId: string, viewName: string>, id: string, name: string, type: string>"
    widget-types-list-by-hub: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    widget-types-get: "record<properties: record<changed: string, created: string, definition: string, description: string, displayName: record, imageUrl: string, tenantId: string, widgetTypeName: string, widgetVersion: string>, id: string, name: string, type: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["operations-list" "hubs-list" "hubs-list-by-resource-group" "hubs-delete" "hubs-get" "hubs-update" "hubs-create-or-update" "authorization-policies-list-by-hub" "authorization-policies-get" "authorization-policies-create-or-update" "authorization-policies-regenerate-primary-key" "authorization-policies-regenerate-secondary-key" "connectors-list-by-hub" "connectors-delete" "connectors-get" "connectors-create-or-update" "connector-mappings-list-by-connector" "connector-mappings-delete" "connector-mappings-get" "connector-mappings-create-or-update" "images-get-upload-url-for-data" "images-get-upload-url-for-entity-type" "interactions-list-by-hub" "interactions-get" "interactions-create-or-update" "interactions-suggest-relationship-links" "kpi-list-by-hub" "kpi-delete" "kpi-get" "kpi-create-or-update" "kpi-reprocess" "links-list-by-hub" "links-delete" "links-get" "links-create-or-update" "predictions-list-by-hub" "predictions-delete" "predictions-get" "predictions-create-or-update" "predictions-get-model-status" "predictions-get-training-results" "predictions-model-status" "profiles-list-by-hub" "profiles-delete" "profiles-get" "profiles-create-or-update" "profiles-get-enriching-kpis" "relationship-links-list-by-hub" "relationship-links-delete" "relationship-links-get" "relationship-links-create-or-update" "relationships-list-by-hub" "relationships-delete" "relationships-get" "relationships-create-or-update" "role-assignments-list-by-hub" "role-assignments-delete" "role-assignments-get" "role-assignments-create-or-update" "roles-list-by-hub" "views-list-by-hub" "views-delete" "views-get" "views-create-or-update" "widget-types-list-by-hub" "widget-types-get" "commands"] | sort) } | get name | first)
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

# Lists all of the available Customer Insights REST API operations.
#
# GET /providers/Microsoft.CustomerInsights/operations
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.CustomerInsights/operations"
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all hubs in the specified subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.CustomerInsights/hubs
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Hubs_List
export def "hubs-list" [
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
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.CustomerInsights/hubs"
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

# Gets all the hubs in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Hubs_ListByResourceGroup
export def "hubs-list-by-resource-group" [
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs"
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

# Deletes the specified hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}
# operationId: Hubs_Delete
export def "hubs-delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}
# Returns: record<properties: record<apiEndpoint: string, hubBillingInfo: record<maxUnits: int, minUnits: int, skuName: string>, provisioningState: string, tenantFeatures: int, webEndpoint: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Hubs_Get
export def "hubs-get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Hub.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}
# Returns: record<properties: record<apiEndpoint: string, hubBillingInfo: record<maxUnits: int, minUnits: int, skuName: string>, provisioningState: string, tenantFeatures: int, webEndpoint: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Hubs_Update
export def "hubs-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
  --properties: any # Properties of hub. — shape: {hubBillingInfo?: any, tenantFeatures?: int}
  --location: string # Resource location.
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a hub, or updates an existing hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}
# Returns: record<properties: record<apiEndpoint: string, hubBillingInfo: record<maxUnits: int, minUnits: int, skuName: string>, provisioningState: string, tenantFeatures: int, webEndpoint: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Hubs_CreateOrUpdate
export def "hubs-create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
  --properties: any # Properties of hub. — shape: {hubBillingInfo?: any, tenantFeatures?: int}
  --location: string # Resource location.
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the authorization policies in a specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: AuthorizationPolicies_ListByHub
export def "authorization-policies-list-by-hub" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an authorization policy in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies/{authorizationPolicyName}
# Returns: record<properties: record<permissions: list<string>, policyName: string, primaryKey: string, secondaryKey: string>, id: string, name: string, type: string>
# operationId: AuthorizationPolicies_Get
export def "authorization-policies-get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  authorization_policy_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies/{authorizationPolicyName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: authorizationPolicyName, var: authorization_policy_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, authorization_policy_name: $authorization_policy_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an authorization policy or updates an existing authorization policy.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies/{authorizationPolicyName}
# Returns: record<properties: record<permissions: list<string>, policyName: string, primaryKey: string, secondaryKey: string>, id: string, name: string, type: string>
# operationId: AuthorizationPolicies_CreateOrUpdate
export def "authorization-policies-create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  authorization_policy_name: string
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
  --properties: any # The authorization policy. — shape: {permissions: list<string>, primaryKey?: string, secondaryKey?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies/{authorizationPolicyName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: authorizationPolicyName, var: authorization_policy_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, authorization_policy_name: $authorization_policy_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Regenerates the primary policy key of the specified authorization policy.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies/{authorizationPolicyName}/regeneratePrimaryKey
# Returns: record<permissions: list<string>, policyName: string, primaryKey: string, secondaryKey: string>
# operationId: AuthorizationPolicies_RegeneratePrimaryKey
export def "authorization-policies-regenerate-primary-key" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  authorization_policy_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies/{authorizationPolicyName}/regeneratePrimaryKey"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: authorizationPolicyName, var: authorization_policy_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, authorization_policy_name: $authorization_policy_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Regenerates the secondary policy key of the specified authorization policy.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies/{authorizationPolicyName}/regenerateSecondaryKey
# Returns: record<permissions: list<string>, policyName: string, primaryKey: string, secondaryKey: string>
# operationId: AuthorizationPolicies_RegenerateSecondaryKey
export def "authorization-policies-regenerate-secondary-key" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  authorization_policy_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies/{authorizationPolicyName}/regenerateSecondaryKey"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: authorizationPolicyName, var: authorization_policy_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, authorization_policy_name: $authorization_policy_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the connectors in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Connectors_ListByHub
export def "connectors-list-by-hub" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a connector in the hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}
# operationId: Connectors_Delete
export def "connectors-delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  connector_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: connectorName, var: connector_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, connector_name: $connector_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a connector in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}
# Returns: record<properties: record<connectorId: int, connectorName: string, connectorProperties: record, connectorType: string, created: string, description: string, displayName: string, isInternal: bool, lastModified: string, state: string, tenantId: string>, id: string, name: string, type: string>
# operationId: Connectors_Get
export def "connectors-get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  connector_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: connectorName, var: connector_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, connector_name: $connector_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a connector or updates an existing connector in the hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}
# Returns: record<properties: record<connectorId: int, connectorName: string, connectorProperties: record, connectorType: string, created: string, description: string, displayName: string, isInternal: bool, lastModified: string, state: string, tenantId: string>, id: string, name: string, type: string>
# operationId: Connectors_CreateOrUpdate
export def "connectors-create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  connector_name: string
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
  --properties: any # Properties of connector. — shape: {connectorName?: string, connectorProperties: record, connectorType: "None"|"CRM"|"AzureBlob"|"Salesforce"|"ExchangeOnline"|"Outbound", description?: string, displayName?: string, isInternal?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: connectorName, var: connector_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, connector_name: $connector_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the connector mappings in the specified connector.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}/mappings
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: ConnectorMappings_ListByConnector
export def "connector-mappings-list-by-connector" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  connector_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}/mappings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: connectorName, var: connector_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, connector_name: $connector_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a connector mapping in the connector.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}/mappings/{mappingName}
# operationId: ConnectorMappings_Delete
export def "connector-mappings-delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  connector_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}/mappings/{mappingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: connectorName, var: connector_name}, {name: mappingName, var: mapping_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, connector_name: $connector_name, mapping_name: $mapping_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a connector mapping in the connector.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}/mappings/{mappingName}
# Returns: record<properties: record<connectorMappingName: string, connectorName: string, connectorType: string, created: string, dataFormatId: string, description: string, displayName: string, entityType: string, entityTypeName: string, lastModified: string, mappingProperties: record<availability: record, completeOperation: record, errorManagement: record, fileFilter: string, folderPath: string, format: record, hasHeader: bool, structure: list>, nextRunTime: string, runId: string, state: string, tenantId: string>, id: string, name: string, type: string>
# operationId: ConnectorMappings_Get
export def "connector-mappings-get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  connector_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}/mappings/{mappingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: connectorName, var: connector_name}, {name: mappingName, var: mapping_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, connector_name: $connector_name, mapping_name: $mapping_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a connector mapping or updates an existing connector mapping in the connector.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}/mappings/{mappingName}
# Returns: record<properties: record<connectorMappingName: string, connectorName: string, connectorType: string, created: string, dataFormatId: string, description: string, displayName: string, entityType: string, entityTypeName: string, lastModified: string, mappingProperties: record<availability: record, completeOperation: record, errorManagement: record, fileFilter: string, folderPath: string, format: record, hasHeader: bool, structure: list>, nextRunTime: string, runId: string, state: string, tenantId: string>, id: string, name: string, type: string>
# operationId: ConnectorMappings_CreateOrUpdate
export def "connector-mappings-create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  connector_name: string
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
  --properties: any # The connector mapping definition. — shape: {connectorType?: "None"|"CRM"|"AzureBlob"|"Salesforce"|"ExchangeOnline"|"Outbound", description?: string, displayName?: string, entityType: "None"|"Profile"|"Interaction"|"Relationship", entityTypeName: string, mappingProperties: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}/mappings/{mappingName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: connectorName, var: connector_name}, {name: mappingName, var: mapping_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, connector_name: $connector_name, mapping_name: $mapping_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets data image upload URL.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/images/getDataImageUploadUrl
# Returns: record<contentUrl: string, imageExists: bool, relativePath: string>
# operationId: Images_GetUploadUrlForData
export def "images-get-upload-url-for-data" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
  --entity-type: string # Type of entity. Can be Profile or Interaction.
  --entity-type-name: string # Name of the entity type.
  --relative-path: string # Relative path of the image.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/images/getDataImageUploadUrl"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: entityType, var: entity_type}, {name: entityTypeName, var: entity_type_name}, {name: relativePath, var: relative_path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, api_version: $api_version, entity_type: $entity_type, entity_type_name: $entity_type_name, relative_path: $relative_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets entity type (profile or interaction) image upload URL.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/images/getEntityTypeImageUploadUrl
# Returns: record<contentUrl: string, imageExists: bool, relativePath: string>
# operationId: Images_GetUploadUrlForEntityType
export def "images-get-upload-url-for-entity-type" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
  --entity-type: string # Type of entity. Can be Profile or Interaction.
  --entity-type-name: string # Name of the entity type.
  --relative-path: string # Relative path of the image.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/images/getEntityTypeImageUploadUrl"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: entityType, var: entity_type}, {name: entityTypeName, var: entity_type_name}, {name: relativePath, var: relative_path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, api_version: $api_version, entity_type: $entity_type, entity_type_name: $entity_type_name, relative_path: $relative_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all interactions in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/interactions
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Interactions_ListByHub
export def "interactions-list-by-hub" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale-code: string # Locale of interaction to retrieve, default is en-us. (default: en-us)
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/interactions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: locale-code, var: locale_code}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, locale_code: $locale_code, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified interaction.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/interactions/{interactionName}
# Returns: record<properties: record<dataSourcePrecedenceRules: list<record>, defaultDataSource: record<dataSourceReferenceId: string, dataSourceType: string, id: int, name: string, status: string>, idPropertyNames: list<string>, isActivity: bool, participantProfiles: list<record>, primaryParticipantProfilePropertyName: string, apiEntitySetName: string, entityType: string, fields: list<record>, instancesCount: int, lastChangedUtc: string, provisioningState: string, schemaItemTypeLink: string, tenantId: string, timestampFieldName: string, typeName: string, attributes: record, description: record, displayName: record, largeImage: string, localizedAttributes: record, mediumImage: string, smallImage: string>, id: string, name: string, type: string>
# operationId: Interactions_Get
export def "interactions-get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  interaction_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale-code: string # Locale of interaction to retrieve, default is en-us. (default: en-us)
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/interactions/{interactionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: interactionName, var: interaction_name}]
    query: [{name: locale-code, var: locale_code}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, interaction_name: $interaction_name, locale_code: $locale_code, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an interaction or updates an existing interaction within a hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/interactions/{interactionName}
# Returns: record<properties: record<dataSourcePrecedenceRules: list<record>, defaultDataSource: record<dataSourceReferenceId: string, dataSourceType: string, id: int, name: string, status: string>, idPropertyNames: list<string>, isActivity: bool, participantProfiles: list<record>, primaryParticipantProfilePropertyName: string, apiEntitySetName: string, entityType: string, fields: list<record>, instancesCount: int, lastChangedUtc: string, provisioningState: string, schemaItemTypeLink: string, tenantId: string, timestampFieldName: string, typeName: string, attributes: record, description: record, displayName: record, largeImage: string, localizedAttributes: record, mediumImage: string, smallImage: string>, id: string, name: string, type: string>
# operationId: Interactions_CreateOrUpdate
export def "interactions-create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  interaction_name: string
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
  --properties: any # The Interaction Type Definition — shape: {defaultDataSource?: any, idPropertyNames?: list<string>, isActivity?: bool, participantProfiles?: list, primaryParticipantProfilePropertyName?: string, apiEntitySetName?: string, entityType?: "None"|"Profile"|"Interaction"|"Relationship", fields?: list, instancesCount?: int, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", schemaItemTypeLink?: string, timestampFieldName?: string, typeName?: string, attributes?: record, description?: record, ... (5 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/interactions/{interactionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: interactionName, var: interaction_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, interaction_name: $interaction_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suggests relationships to create relationship links.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/interactions/{interactionName}/suggestRelationshipLinks
# Returns: record<interactionName: string, suggestedRelationships: table<existingRelationshipName: string, profileName: string, profilePropertyReferences: list, relatedProfileName: string, relatedProfilePropertyReferences: list>>
# operationId: Interactions_SuggestRelationshipLinks
export def "interactions-suggest-relationship-links" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  interaction_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/interactions/{interactionName}/suggestRelationshipLinks"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: interactionName, var: interaction_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, interaction_name: $interaction_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the KPIs in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Kpi_ListByHub
export def "kpi-list-by-hub" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a KPI in the hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi/{kpiName}
# operationId: Kpi_Delete
export def "kpi-delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  kpi_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi/{kpiName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: kpiName, var: kpi_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, kpi_name: $kpi_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a KPI in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi/{kpiName}
# Returns: record<properties: record<aliases: list<record>, calculationWindow: string, calculationWindowFieldName: string, description: record, displayName: record, entityType: string, entityTypeName: string, expression: string, extracts: list<record>, filter: string, function: string, groupBy: list<string>, groupByMetadata: list<record>, kpiName: string, participantProfilesMetadata: list<record>, provisioningState: string, tenantId: string, thresHolds: record<increasingKpi: bool, lowerLimit: float, upperLimit: float>, unit: string>, id: string, name: string, type: string>
# operationId: Kpi_Get
export def "kpi-get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  kpi_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi/{kpiName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: kpiName, var: kpi_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, kpi_name: $kpi_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a KPI or updates an existing KPI in the hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi/{kpiName}
# Returns: record<properties: record<aliases: list<record>, calculationWindow: string, calculationWindowFieldName: string, description: record, displayName: record, entityType: string, entityTypeName: string, expression: string, extracts: list<record>, filter: string, function: string, groupBy: list<string>, groupByMetadata: list<record>, kpiName: string, participantProfilesMetadata: list<record>, provisioningState: string, tenantId: string, thresHolds: record<increasingKpi: bool, lowerLimit: float, upperLimit: float>, unit: string>, id: string, name: string, type: string>
# operationId: Kpi_CreateOrUpdate
export def "kpi-create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  kpi_name: string
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
  --properties: any # Defines the KPI Threshold limits. — shape: {aliases?: list, calculationWindow: "Lifetime"|"Hour"|"Day"|"Week"|"Month", calculationWindowFieldName?: string, description?: record, displayName?: record, entityType: "None"|"Profile"|"Interaction"|"Relationship", entityTypeName: string, expression: string, extracts?: list, filter?: string, function: "Sum"|"Avg"|"Min"|"Max"|"Last"|"Count"|"None"|"CountDistinct", groupBy?: list<string>, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", ... (2 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi/{kpiName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: kpiName, var: kpi_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, kpi_name: $kpi_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reprocesses the Kpi values of the specified KPI.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi/{kpiName}/reprocess
# operationId: Kpi_Reprocess
export def "kpi-reprocess" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  kpi_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi/{kpiName}/reprocess"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: kpiName, var: kpi_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, kpi_name: $kpi_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the links in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/links
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Links_ListByHub
export def "links-list-by-hub" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/links"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a link in the hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/links/{linkName}
# operationId: Links_Delete
export def "links-delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  link_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/links/{linkName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: linkName, var: link_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, link_name: $link_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a link in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/links/{linkName}
# Returns: record<properties: record<description: record, displayName: record, linkName: string, mappings: list<record>, operationType: string, participantPropertyReferences: list<record>, provisioningState: string, referenceOnly: bool, sourceEntityType: string, sourceEntityTypeName: string, targetEntityType: string, targetEntityTypeName: string, tenantId: string>, id: string, name: string, type: string>
# operationId: Links_Get
export def "links-get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  link_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/links/{linkName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: linkName, var: link_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, link_name: $link_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a link or updates an existing link in the hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/links/{linkName}
# Returns: record<properties: record<description: record, displayName: record, linkName: string, mappings: list<record>, operationType: string, participantPropertyReferences: list<record>, provisioningState: string, referenceOnly: bool, sourceEntityType: string, sourceEntityTypeName: string, targetEntityType: string, targetEntityTypeName: string, tenantId: string>, id: string, name: string, type: string>
# operationId: Links_CreateOrUpdate
export def "links-create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  link_name: string
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
  --properties: any # The definition of Link. — shape: {description?: record, displayName?: record, mappings?: list, operationType?: "Upsert"|"Delete", participantPropertyReferences: list, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", referenceOnly?: bool, sourceEntityType: "None"|"Profile"|"Interaction"|"Relationship", sourceEntityTypeName: string, targetEntityType: "None"|"Profile"|"Interaction"|"Relationship", targetEntityTypeName: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/links/{linkName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: linkName, var: link_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, link_name: $link_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the predictions in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Predictions_ListByHub
export def "predictions-list-by-hub" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Prediction in the hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}
# operationId: Predictions_Delete
export def "predictions-delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  prediction_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: predictionName, var: prediction_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, prediction_name: $prediction_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a Prediction in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}
# Returns: record<properties: record<autoAnalyze: bool, description: record, displayName: record, grades: list<record>, involvedInteractionTypes: list<string>, involvedKpiTypes: list<string>, involvedRelationships: list<string>, mappings: record<grade: string, reason: string, score: string>, negativeOutcomeExpression: string, positiveOutcomeExpression: string, predictionName: string, primaryProfileType: string, provisioningState: string, scopeExpression: string, scoreLabel: string, systemGeneratedEntities: record<generatedInteractionTypes: list, generatedKpis: record, generatedLinks: list>, tenantId: string>, id: string, name: string, type: string>
# operationId: Predictions_Get
export def "predictions-get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  prediction_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: predictionName, var: prediction_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, prediction_name: $prediction_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Prediction or updates an existing Prediction in the hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}
# Returns: record<properties: record<autoAnalyze: bool, description: record, displayName: record, grades: list<record>, involvedInteractionTypes: list<string>, involvedKpiTypes: list<string>, involvedRelationships: list<string>, mappings: record<grade: string, reason: string, score: string>, negativeOutcomeExpression: string, positiveOutcomeExpression: string, predictionName: string, primaryProfileType: string, provisioningState: string, scopeExpression: string, scoreLabel: string, systemGeneratedEntities: record<generatedInteractionTypes: list, generatedKpis: record, generatedLinks: list>, tenantId: string>, id: string, name: string, type: string>
# operationId: Predictions_CreateOrUpdate
export def "predictions-create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  prediction_name: string
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
  --properties: any # The prediction definition. — shape: {autoAnalyze: bool, description?: record, displayName?: record, grades?: list, involvedInteractionTypes?: list<string>, involvedKpiTypes?: list<string>, involvedRelationships?: list<string>, mappings: record, negativeOutcomeExpression: string, positiveOutcomeExpression: string, predictionName?: string, primaryProfileType: string, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", scopeExpression: string, scoreLabel: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: predictionName, var: prediction_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, prediction_name: $prediction_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets model status of the prediction.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}/getModelStatus
# Returns: record<message: string, modelVersion: string, predictionGuidId: string, predictionName: string, signalsUsed: int, status: string, tenantId: string, testSetCount: int, trainingAccuracy: int, trainingSetCount: int, validationSetCount: int>
# operationId: Predictions_GetModelStatus
export def "predictions-get-model-status" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  prediction_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}/getModelStatus"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: predictionName, var: prediction_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, prediction_name: $prediction_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets training results.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}/getTrainingResults
# Returns: record<canonicalProfiles: table<canonicalProfileId: int, properties: list>, predictionDistribution: record<distributions: list<record>, totalNegatives: int, totalPositives: int>, primaryProfileInstanceCount: int, scoreName: string, tenantId: string>
# operationId: Predictions_GetTrainingResults
export def "predictions-get-training-results" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  prediction_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}/getTrainingResults"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: predictionName, var: prediction_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, prediction_name: $prediction_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates the model status of prediction.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}/modelStatus
# operationId: Predictions_ModelStatus
export def "predictions-model-status" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  prediction_name: string
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
  status: string@status-completer # Prediction model life cycle. When prediction is in PendingModelConfirmation status, it is allowed to update the status to PendingFeaturing or Active through API.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}/modelStatus"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: predictionName, var: prediction_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, prediction_name: $prediction_name, api_version: $api_version, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all profile in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Profiles_ListByHub
export def "profiles-list-by-hub" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale-code: string # Locale of profile to retrieve, default is en-us. (default: en-us)
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: locale-code, var: locale_code}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, locale_code: $locale_code, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a profile within a hub
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles/{profileName}
# operationId: Profiles_Delete
export def "profiles-delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale-code: string # Locale of profile to retrieve, default is en-us. (default: en-us)
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles/{profileName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: profileName, var: profile_name}]
    query: [{name: locale-code, var: locale_code}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, profile_name: $profile_name, locale_code: $locale_code, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified profile.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles/{profileName}
# Returns: record<properties: record<strongIds: list<record>, apiEntitySetName: string, entityType: string, fields: list<record>, instancesCount: int, lastChangedUtc: string, provisioningState: string, schemaItemTypeLink: string, tenantId: string, timestampFieldName: string, typeName: string, attributes: record, description: record, displayName: record, largeImage: string, localizedAttributes: record, mediumImage: string, smallImage: string>, id: string, name: string, type: string>
# operationId: Profiles_Get
export def "profiles-get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale-code: string # Locale of profile to retrieve, default is en-us. (default: en-us)
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles/{profileName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: profileName, var: profile_name}]
    query: [{name: locale-code, var: locale_code}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, profile_name: $profile_name, locale_code: $locale_code, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a profile within a Hub, or updates an existing profile.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles/{profileName}
# Returns: record<properties: record<strongIds: list<record>, apiEntitySetName: string, entityType: string, fields: list<record>, instancesCount: int, lastChangedUtc: string, provisioningState: string, schemaItemTypeLink: string, tenantId: string, timestampFieldName: string, typeName: string, attributes: record, description: record, displayName: record, largeImage: string, localizedAttributes: record, mediumImage: string, smallImage: string>, id: string, name: string, type: string>
# operationId: Profiles_CreateOrUpdate
export def "profiles-create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  profile_name: string
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
  --properties: any # The profile type definition. — shape: {strongIds?: list, apiEntitySetName?: string, entityType?: "None"|"Profile"|"Interaction"|"Relationship", fields?: list, instancesCount?: int, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", schemaItemTypeLink?: string, timestampFieldName?: string, typeName?: string, attributes?: record, description?: record, displayName?: record, largeImage?: string, localizedAttributes?: record, mediumImage?: string, smallImage?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles/{profileName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: profileName, var: profile_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, profile_name: $profile_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the KPIs that enrich the profile Type identified by the supplied name. Enrichment happens through participants of the Interaction on an Interaction KPI and through Relationships for Profile KPIs.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles/{profileName}/getEnrichingKpis
# Returns: table<aliases: list<record>, calculationWindow: string, calculationWindowFieldName: string, description: record, displayName: record, entityType: string, entityTypeName: string, expression: string, extracts: list<record>, filter: string, function: string, groupBy: list<string>, groupByMetadata: list<record>, kpiName: string, participantProfilesMetadata: list<record>, provisioningState: string, tenantId: string, thresHolds: record<increasingKpi: bool, lowerLimit: float, upperLimit: float>, unit: string>
# operationId: Profiles_GetEnrichingKpis
export def "profiles-get-enriching-kpis" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  profile_name: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles/{profileName}/getEnrichingKpis"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: profileName, var: profile_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, profile_name: $profile_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all relationship links in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationshipLinks
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: RelationshipLinks_ListByHub
export def "relationship-links-list-by-hub" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationshipLinks"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a relationship link within a hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationshipLinks/{relationshipLinkName}
# operationId: RelationshipLinks_Delete
export def "relationship-links-delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  relationship_link_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationshipLinks/{relationshipLinkName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: relationshipLinkName, var: relationship_link_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, relationship_link_name: $relationship_link_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified relationship Link.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationshipLinks/{relationshipLinkName}
# Returns: record<properties: record<description: record, displayName: record, interactionType: string, linkName: string, mappings: list<record>, profilePropertyReferences: list<record>, provisioningState: string, relatedProfilePropertyReferences: list<record>, relationshipGuidId: string, relationshipName: string, tenantId: string>, id: string, name: string, type: string>
# operationId: RelationshipLinks_Get
export def "relationship-links-get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  relationship_link_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationshipLinks/{relationshipLinkName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: relationshipLinkName, var: relationship_link_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, relationship_link_name: $relationship_link_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a relationship link or updates an existing relationship link within a hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationshipLinks/{relationshipLinkName}
# Returns: record<properties: record<description: record, displayName: record, interactionType: string, linkName: string, mappings: list<record>, profilePropertyReferences: list<record>, provisioningState: string, relatedProfilePropertyReferences: list<record>, relationshipGuidId: string, relationshipName: string, tenantId: string>, id: string, name: string, type: string>
# operationId: RelationshipLinks_CreateOrUpdate
export def "relationship-links-create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  relationship_link_name: string
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
  --properties: any # The definition of relationship link. — shape: {description?: record, displayName?: record, interactionType: string, mappings?: list, profilePropertyReferences: list, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", relatedProfilePropertyReferences: list, relationshipName: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationshipLinks/{relationshipLinkName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: relationshipLinkName, var: relationship_link_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, relationship_link_name: $relationship_link_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all relationships in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationships
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Relationships_ListByHub
export def "relationships-list-by-hub" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationships"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a relationship within a hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationships/{relationshipName}
# operationId: Relationships_Delete
export def "relationships-delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  relationship_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationships/{relationshipName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: relationshipName, var: relationship_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, relationship_name: $relationship_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified relationship.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationships/{relationshipName}
# Returns: record<properties: record<cardinality: string, description: record, displayName: record, expiryDateTimeUtc: string, fields: list<record>, lookupMappings: list<record>, profileType: string, provisioningState: string, relatedProfileType: string, relationshipGuidId: string, relationshipName: string, tenantId: string>, id: string, name: string, type: string>
# operationId: Relationships_Get
export def "relationships-get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  relationship_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationships/{relationshipName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: relationshipName, var: relationship_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, relationship_name: $relationship_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a relationship or updates an existing relationship within a hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationships/{relationshipName}
# Returns: record<properties: record<cardinality: string, description: record, displayName: record, expiryDateTimeUtc: string, fields: list<record>, lookupMappings: list<record>, profileType: string, provisioningState: string, relatedProfileType: string, relationshipGuidId: string, relationshipName: string, tenantId: string>, id: string, name: string, type: string>
# operationId: Relationships_CreateOrUpdate
export def "relationships-create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  relationship_name: string
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
  --properties: any # The definition of Relationship. — shape: {cardinality?: "OneToOne"|"OneToMany"|"ManyToMany", description?: record, displayName?: record, expiryDateTimeUtc?: string, fields?: list, lookupMappings?: list, profileType: string, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", relatedProfileType: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationships/{relationshipName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: relationshipName, var: relationship_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, relationship_name: $relationship_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the role assignments for the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roleAssignments
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: RoleAssignments_ListByHub
export def "role-assignments-list-by-hub" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roleAssignments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the role assignment in the hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roleAssignments/{assignmentName}
# operationId: RoleAssignments_Delete
export def "role-assignments-delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  assignment_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roleAssignments/{assignmentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: assignmentName, var: assignment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, assignment_name: $assignment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the role assignment in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roleAssignments/{assignmentName}
# Returns: record<properties: record<assignmentName: string, conflationPolicies: record<elements: list, exceptions: list>, connectors: record<elements: list, exceptions: list>, description: record, displayName: record, interactions: record<elements: list, exceptions: list>, kpis: record<elements: list, exceptions: list>, links: record<elements: list, exceptions: list>, principals: list<record>, profiles: record<elements: list, exceptions: list>, provisioningState: string, relationshipLinks: record<elements: list, exceptions: list>, relationships: record<elements: list, exceptions: list>, role: string, roleAssignments: record<elements: list, exceptions: list>, sasPolicies: record<elements: list, exceptions: list>, segments: record<elements: list, exceptions: list>, tenantId: string, views: record<elements: list, exceptions: list>, widgetTypes: record<elements: list, exceptions: list>>, id: string, name: string, type: string>
# operationId: RoleAssignments_Get
export def "role-assignments-get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  assignment_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roleAssignments/{assignmentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: assignmentName, var: assignment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, assignment_name: $assignment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a role assignment in the hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roleAssignments/{assignmentName}
# Returns: record<properties: record<assignmentName: string, conflationPolicies: record<elements: list, exceptions: list>, connectors: record<elements: list, exceptions: list>, description: record, displayName: record, interactions: record<elements: list, exceptions: list>, kpis: record<elements: list, exceptions: list>, links: record<elements: list, exceptions: list>, principals: list<record>, profiles: record<elements: list, exceptions: list>, provisioningState: string, relationshipLinks: record<elements: list, exceptions: list>, relationships: record<elements: list, exceptions: list>, role: string, roleAssignments: record<elements: list, exceptions: list>, sasPolicies: record<elements: list, exceptions: list>, segments: record<elements: list, exceptions: list>, tenantId: string, views: record<elements: list, exceptions: list>, widgetTypes: record<elements: list, exceptions: list>>, id: string, name: string, type: string>
# operationId: RoleAssignments_CreateOrUpdate
export def "role-assignments-create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  assignment_name: string
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
  --properties: any # The Role Assignment definition. — shape: {conflationPolicies?: any, connectors?: any, description?: record, displayName?: record, interactions?: any, kpis?: any, links?: any, principals: list, profiles?: any, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", relationshipLinks?: any, relationships?: any, role: "Admin"|"Reader"|"ManageAdmin"|"ManageReader"|"DataAdmin"|"DataReader", roleAssignments?: any, sasPolicies?: any, segments?: any, views?: any, widgetTypes?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roleAssignments/{assignmentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: assignmentName, var: assignment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, assignment_name: $assignment_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all the roles for the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roles
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Roles_ListByHub
export def "roles-list-by-hub" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roles"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all available views for given user in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/views
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Views_ListByHub
export def "views-list-by-hub" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
  --user-id: string # The user ID. Use * to retrieve hub level views. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/views"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: userId, var: user_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, api_version: $api_version, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a view in the specified hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/views/{viewName}
# operationId: Views_Delete
export def "views-delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  view_name: string
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
  --user-id: string # The user ID. Use * to retrieve hub level view. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/views/{viewName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: viewName, var: view_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: userId, var: user_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, view_name: $view_name, api_version: $api_version, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a view in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/views/{viewName}
# Returns: record<properties: record<changed: string, created: string, definition: string, displayName: record, tenantId: string, userId: string, viewName: string>, id: string, name: string, type: string>
# operationId: Views_Get
export def "views-get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  view_name: string
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
  --user-id: string # The user ID. Use * to retrieve hub level view. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/views/{viewName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: viewName, var: view_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: userId, var: user_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, view_name: $view_name, api_version: $api_version, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a view or updates an existing view in the hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/views/{viewName}
# Returns: record<properties: record<changed: string, created: string, definition: string, displayName: record, tenantId: string, userId: string, viewName: string>, id: string, name: string, type: string>
# operationId: Views_CreateOrUpdate
export def "views-create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  view_name: string
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
  --properties: any # The view in Customer 360 web application. — shape: {definition: string, displayName?: record, userId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/views/{viewName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: viewName, var: view_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, view_name: $view_name, api_version: $api_version, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all available widget types in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/widgetTypes
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: WidgetTypes_ListByHub
export def "widget-types-list-by-hub" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/widgetTypes"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a widget type in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/widgetTypes/{widgetTypeName}
# Returns: record<properties: record<changed: string, created: string, definition: string, description: string, displayName: record, imageUrl: string, tenantId: string, widgetTypeName: string, widgetVersion: string>, id: string, name: string, type: string>
# operationId: WidgetTypes_Get
export def "widget-types-get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  widget_type_name: string
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
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/widgetTypes/{widgetTypeName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: hubName, var: hub_name}, {name: widgetTypeName, var: widget_type_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, hub_name: $hub_name, widget_type_name: $widget_type_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
