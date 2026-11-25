# Auto-generated client for ADHybridHealthService v2014-01-01
# Source: https://api.apis.guru/v2/specs/azure.com/adhybridhealthservice-ADHybridHealthService/2014-01-01/swagger.json
# Auth: --token flag or $env.ADHYBRIDHEALTHSERVICE_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "ADHYBRIDHEALTHSERVICE_TOKEN"
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
def next-partition-key-completer [] { [" "] }
def next-row-key-completer [] { [" "] }
def server-reported-monitoring-level-completer [] { ["Full" "Off" "Partial"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    adds-services-list: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>>"
    adds-services-add: "record<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list<string>, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list<string>, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>"
    adds-services-list-premium-services: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>>"
    adds-services-get: "record<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list<string>, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list<string>, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>"
    adds-services-update: "record<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list<string>, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list<string>, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>"
    ad-domain-service-members-list: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, addsRoles: list, createdDate: string, dcTypes: list, dimensions: list, disabled: bool, disabledReason: int, domainName: string, gcReachable: bool, installedQfes: list, isAdvertising: bool, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: list, monitoringConfigurationsCustomized: list, osName: string, osVersion: string, pdcReachable: bool, properties: list, recommendedQfes: list, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, siteName: string, status: string, sysvolState: bool, tenantId: string>>"
    adds-service-members-list: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, addsRoles: list, createdDate: string, dcTypes: list, dimensions: list, disabled: bool, disabledReason: int, domainName: string, gcReachable: bool, installedQfes: list, isAdvertising: bool, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: list, monitoringConfigurationsCustomized: list, osName: string, osVersion: string, pdcReachable: bool, properties: list, recommendedQfes: list, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, siteName: string, status: string, sysvolState: bool, tenantId: string>>"
    alerts-list-adds-alerts: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlertProperties: list, additionalInformation: list, alertId: string, createdDate: string, description: string, displayName: string, lastUpdated: string, level: string, monitorRoleType: string, relatedLinks: list, remediation: string, resolvedAlertProperties: list, resolvedDate: string, scope: string, serviceId: string, serviceMemberId: string, shortName: string, state: string, tenantId: string>>"
    configuration-list-adds-configurations: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<key: string, value: string>>"
    dimensions-list-adds-dimensions: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, displayName: string, health: string, lastUpdated: string, resolvedAlerts: int, signature: string, simpleProperties: record, type: string>>"
    adds-services-user-preference-get: "record<metricNames: list<string>>"
    adds-services-get-forest-summary: "record<domainCount: int, domains: list<string>, forestName: string, monitoredDcCount: int, siteCount: int, sites: list<string>, totalDcCount: int>"
    adds-services-list-metric-metadata: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<displayName: string, groupings: list, isDefault: bool, isDevOps: bool, isPerfCounter: bool, kind: string, maxValue: int, metricName: string, metricsProcessorClassName: string, minValue: int, valueKind: string>>"
    adds-services-get-metric-metadata: "record<displayName: string, groupings: table<displayName: string, invisibleForUi: bool, key: string>, isDefault: bool, isDevOps: bool, isPerfCounter: bool, kind: string, maxValue: int, metricName: string, metricsProcessorClassName: string, minValue: int, valueKind: string>"
    adds-services-get-metric-metadata-for-group: "record<sets: table<setName: string, values: list>, timeStamps: list<string>>"
    adds-service-get-metrics: "record<sets: table<setName: string, values: list>, timeStamps: list<string>>"
    adds-services-list-metrics-average: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<key: string, value: string>>"
    adds-services-list-metrics-sum: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<key: string, value: string>>"
    adds-services-list-replication-details: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<domain: string, inboundNeighborCollection: list, lastAttemptedSync: string, lastSuccessfulSync: string, site: string, status: int, targetServer: string>>"
    adds-services-replication-status-get: "record<errorDcCount: int, forestName: string, totalDcCount: int>"
    adds-services-list-replication-summary: "record<value: table<domain: string, inboundNeighborCollection: list, lastAttemptedSync: string, lastSuccessfulSync: string, site: string, status: int, targetServer: string>>"
    adds-services-service-members-list: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, createdDate: string, dimensions: record, disabled: bool, disabledReason: int, installedQfes: record, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, osName: string, osVersion: string, properties: record, recommendedQfes: record, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, status: string, tenantId: string>>"
    adds-services-service-members-add: "record<activeAlerts: int, additionalInformation: string, createdDate: string, dimensions: record, disabled: bool, disabledReason: int, installedQfes: record, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, osName: string, osVersion: string, properties: record, recommendedQfes: record, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, status: string, tenantId: string>"
    adds-service-members-get: "record<activeAlerts: int, additionalInformation: string, createdDate: string, dimensions: record, disabled: bool, disabledReason: int, installedQfes: record, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, osName: string, osVersion: string, properties: record, recommendedQfes: record, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, status: string, tenantId: string>"
    adds-services-list-server-alerts: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlertProperties: list, additionalInformation: list, alertId: string, createdDate: string, description: string, displayName: string, lastUpdated: string, level: string, monitorRoleType: string, relatedLinks: list, remediation: string, resolvedAlertProperties: list, resolvedDate: string, scope: string, serviceId: string, serviceMemberId: string, shortName: string, state: string, tenantId: string>>"
    adds-service-members-list-credentials: "record<value: table<credentialData: list, identifier: string, type: string>>"
    configuration-get: "record<aadLicense: string, aadPremium: bool, agentAutoUpdate: bool, alertSuppressionTimeInMins: int, consentedToMicrosoftDevOps: bool, countryLetterCode: string, createdDate: string, devOpsTtl: string, disabled: bool, disabledReason: int, globalAdminsEmail: list<string>, initialDomain: string, lastDisabled: string, lastVerified: string, onboarded: bool, onboardingAllowed: bool, pksCertificate: record, privatePreviewTenant: bool, tenantId: string, tenantInQuarantine: bool, tenantName: string>"
    configuration-update: "record<aadLicense: string, aadPremium: bool, agentAutoUpdate: bool, alertSuppressionTimeInMins: int, consentedToMicrosoftDevOps: bool, countryLetterCode: string, createdDate: string, devOpsTtl: string, disabled: bool, disabledReason: int, globalAdminsEmail: list<string>, initialDomain: string, lastDisabled: string, lastVerified: string, onboarded: bool, onboardingAllowed: bool, pksCertificate: record, privatePreviewTenant: bool, tenantId: string, tenantInQuarantine: bool, tenantName: string>"
    configuration-add: "record<aadLicense: string, aadPremium: bool, agentAutoUpdate: bool, alertSuppressionTimeInMins: int, consentedToMicrosoftDevOps: bool, countryLetterCode: string, createdDate: string, devOpsTtl: string, disabled: bool, disabledReason: int, globalAdminsEmail: list<string>, initialDomain: string, lastDisabled: string, lastVerified: string, onboarded: bool, onboardingAllowed: bool, pksCertificate: record, privatePreviewTenant: bool, tenantId: string, tenantInQuarantine: bool, tenantName: string>"
    operations-list: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<display: record, name: string>>"
    reports-get-dev-ops: "record<value: bool>"
    service-members-list-connectors: "record<value: table<attributesIncluded: list, classesIncluded: list, connectorId: string, description: string, id: string, name: string, partitions: list, passwordHashSyncConfiguration: record, passwordManagementSettings: record, runProfiles: list, schemaXml: string, timeCreated: string, timeLastModified: string, type: string, version: int>>"
    services-list: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>>"
    services-add: "record<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list<string>, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list<string>, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>"
    services-list-premium: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>>"
    services-get: "record<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list<string>, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list<string>, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>"
    services-update: "record<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list<string>, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list<string>, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>"
    services-get-tenant-whitelisting: "record<value: bool>"
    services-list-alerts: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlertProperties: list, additionalInformation: list, alertId: string, createdDate: string, description: string, displayName: string, lastUpdated: string, level: string, monitorRoleType: string, relatedLinks: list, remediation: string, resolvedAlertProperties: list, resolvedDate: string, scope: string, serviceId: string, serviceMemberId: string, shortName: string, state: string, tenantId: string>>"
    services-get-feature-availibility: "record<value: bool>"
    services-list-export-errors: "record<value: table<count: int, errorBucket: string, truncated: bool>>"
    services-list-export-errors-v2: "record<value: table<attributeName: string, attributeValue: string, createdDate: string, csObjectId: string, dn: string, existingObject: record, exportErrorStatus: int, id: string, incomingObject: record, incomingObjectDisplayName: string, incomingObjectType: string, mergedEntityId: string, modifiedOrRemovedAttributeValue: string, runStepResultId: string, samAccountName: string, serverErrorDetail: string, serviceId: string, serviceMemberId: string, timeFirstOccurred: string, timeOccurred: string, type: string, userPrincipalName: string>>"
    services-list-export-status: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<endTime: string, runStepResultId: string, serviceId: string, serviceMemberId: string>>"
    services-add-alert-feedback: "record<comment: string, consentedToShare: bool, createdDate: string, feedback: string, level: string, serviceMemberId: string, shortName: string, state: string>"
    services-list-alert-feedback: "record<value: table<comment: string, consentedToShare: bool, createdDate: string, feedback: string, level: string, serviceMemberId: string, shortName: string, state: string>>"
    services-list-metric-metadata: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<displayName: string, groupings: list, isDefault: bool, isDevOps: bool, isPerfCounter: bool, kind: string, maxValue: int, metricName: string, metricsProcessorClassName: string, minValue: int, valueKind: string>>"
    services-get-metric-metadata: "record<displayName: string, groupings: table<displayName: string, invisibleForUi: bool, key: string>, isDefault: bool, isDevOps: bool, isPerfCounter: bool, kind: string, maxValue: int, metricName: string, metricsProcessorClassName: string, minValue: int, valueKind: string>"
    services-get-metric-metadata-for-group: "record<sets: table<setName: string, values: list>, timeStamps: list<string>>"
    service-get-metrics: "record<sets: table<setName: string, values: list>, timeStamps: list<string>>"
    services-list-metrics-average: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<key: string, value: string>>"
    services-list-metrics-sum: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<key: string, value: string>>"
    services-list-monitoring-configurations: "record<value: table<key: string, value: string>>"
    services-list-user-bad-password-report: "record<value: table<ipAddress: string, lastUpdated: string, totalErrorAttempts: int, uniqueIpAddresses: string, userId: string>>"
    services-list-all-risky-ip-download-report: "record<value: table<blobCreateDateTime: string, jobCompletionTime: string, resultSasUri: string, serviceId: string, status: string, tenantId: string>>"
    services-list-current-risky-ip-download-report: "record<value: table<blobCreateDateTime: string, jobCompletionTime: string, resultSasUri: string, serviceId: string, status: string, tenantId: string>>"
    service-members-list: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, createdDate: string, dimensions: record, disabled: bool, disabledReason: int, installedQfes: record, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, osName: string, osVersion: string, properties: record, recommendedQfes: record, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, status: string, tenantId: string>>"
    service-members-add: "record<activeAlerts: int, additionalInformation: string, createdDate: string, dimensions: record, disabled: bool, disabledReason: int, installedQfes: record, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, osName: string, osVersion: string, properties: record, recommendedQfes: record, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, status: string, tenantId: string>"
    service-members-get: "record<activeAlerts: int, additionalInformation: string, createdDate: string, dimensions: record, disabled: bool, disabledReason: int, installedQfes: record, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, osName: string, osVersion: string, properties: record, recommendedQfes: record, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, status: string, tenantId: string>"
    service-members-list-alerts: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlertProperties: list, additionalInformation: list, alertId: string, createdDate: string, description: string, displayName: string, lastUpdated: string, level: string, monitorRoleType: string, relatedLinks: list, remediation: string, resolvedAlertProperties: list, resolvedDate: string, scope: string, serviceId: string, serviceMemberId: string, shortName: string, state: string, tenantId: string>>"
    service-members-list-credentials: "record<value: table<credentialData: list, identifier: string, type: string>>"
    service-members-list-data-freshness: "record<value: table<key: string, value: string>>"
    service-members-list-export-status: "record<continuationToken: string, nextLink: string, totalCount: int, value: table<endTime: string, runStepResultId: string, serviceId: string, serviceMemberId: string>>"
    service-members-list-global-configuration: "record<value: table<featureSet: list, numSavedPwdEvent: int, passwordSyncEnabled: bool, schemaXml: string, version: int>>"
    service-members-get-connector-metadata: "record<connectors: table<connectorDisplayName: string, connectorId: string>, runProfileNames: list<string>>"
    service-members-get-metrics: "record<sets: table<setName: string, values: list>, timeStamps: list<string>>"
    service-members-get-service-configuration: "record<serviceAccount: string, serviceType: int, sqlDatabaseName: string, sqlDatabaseSize: int, sqlEdition: string, sqlInstance: string, sqlServer: string, sqlVersion: string, version: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["adds-services-list" "adds-services-add" "adds-services-list-premium-services" "adds-services-delete" "adds-services-get" "adds-services-update" "ad-domain-service-members-list" "adds-service-members-list" "alerts-list-adds-alerts" "configuration-list-adds-configurations" "dimensions-list-adds-dimensions" "adds-services-user-preference-delete" "adds-services-user-preference-get" "adds-services-user-preference-add" "adds-services-get-forest-summary" "adds-services-list-metric-metadata" "adds-services-get-metric-metadata" "adds-services-get-metric-metadata-for-group" "adds-service-get-metrics" "adds-services-list-metrics-average" "adds-services-list-metrics-sum" "adds-services-list-replication-details" "adds-services-replication-status-get" "adds-services-list-replication-summary" "adds-services-service-members-list" "adds-services-service-members-add" "adds-service-members-delete" "adds-service-members-get" "adds-services-list-server-alerts" "adds-service-members-list-credentials" "configuration-get" "configuration-update" "configuration-add" "operations-list" "reports-get-dev-ops" "service-members-list-connectors" "services-list" "services-add" "services-list-premium" "services-delete" "services-get" "services-update" "services-get-tenant-whitelisting" "services-list-alerts" "services-get-feature-availibility" "services-list-export-errors" "services-list-export-errors-v2" "services-list-export-status" "services-add-alert-feedback" "services-list-alert-feedback" "services-list-metric-metadata" "services-get-metric-metadata" "services-get-metric-metadata-for-group" "service-get-metrics" "services-list-metrics-average" "services-list-metrics-sum" "services-update-monitoring-configuration" "services-list-monitoring-configurations" "services-list-user-bad-password-report" "services-list-all-risky-ip-download-report" "services-list-current-risky-ip-download-report" "service-members-list" "service-members-add" "service-members-delete" "service-members-get" "service-members-list-alerts" "service-members-list-credentials" "service-members-delete-data" "service-members-list-data-freshness" "service-members-list-export-status" "service-members-list-global-configuration" "service-members-get-connector-metadata" "service-members-get-metrics" "service-members-get-service-configuration" "commands"] | sort) } | get name | first)
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

# Gets the details of Active Directory Domain Service, for a tenant, that are onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>>
# operationId: addsServices_list
export def "adds-services-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The service property filter to apply.
  --service-type: string # The service type for the services onboarded to Azure Active Directory Connect Health. Depending on whether the service is monitoring, ADFS, Sync or ADDS roles, the service type can either be AdFederationService or AadSyncService or AdDomainService.
  --skip-count: int # The skip count, which specifies the number of elements that can be bypassed from a sequence and then return the remaining elements.
  --take-count: int # The take count , which specifies the number of elements that can be returned from a sequence.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices"
    query: [{name: "$filter", var: filter}, {name: serviceType, var: service_type}, {name: skipCount, var: skip_count}, {name: takeCount, var: take_count}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, service_type: $service_type, skip_count: $skip_count, take_count: $take_count, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Onboards a service for a given tenant in Azure Active Directory Connect Health.
#
# POST /providers/Microsoft.ADHybridHealthService/addsservices
# Returns: record<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list<string>, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list<string>, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>
# operationId: addsServices_add
export def "adds-services-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
  --active-alerts: int # The count of alerts that are currently active for the service.
  --additional-information: string # The additional information related to the service.
  --created-date: string # The date and time, in UTC, when the service was onboarded to Azure Active Directory Connect Health. (format: date-time)
  --custom-notification-emails: list<string> # The list of additional emails that are configured to receive notifications about the service.
  --disabled: oneof<nothing, bool> # Indicates if the service is disabled or not.
  --display-name: string # The display name of the service.
  --health: string # The health of the service.
  --id: string # The id of the service.
  --last-disabled: string # The date and time, in UTC, when the service was last disabled. (format: date-time)
  --last-updated: string # The date or time , in UTC, when the service properties were last updated. (format: date-time)
  --monitoring-configurations-computed: record # The monitoring configuration of the service which determines what activities are monitored by Azure Active Directory Connect Health.
  --monitoring-configurations-customized: record # The customized monitoring configuration of the service which determines what activities are monitored by Azure Active Directory Connect Health.
  --notification-email-enabled: oneof<nothing, bool> # Indicates if email notification is enabled or not.
  --notification-email-enabled-for-global-admins: oneof<nothing, bool> # Indicates if email notification is enabled for global administrators of the tenant.
  --notification-emails: list<string> # The list of emails to whom service notifications will be sent.
  --notification-emails-enabled-for-global-admins: oneof<nothing, bool> # Indicates if email notification is enabled for global administrators of the tenant.
  --original-disabled-state: oneof<nothing, bool> # Gets the original disable state.
  --resolved-alerts: int # The total count of alerts that has been resolved for the service.
  --service-id: string # The id of the service.
  --service-name: string # The name of the service.
  --signature: string # The signature of the service.
  --simple-properties: record # List of service specific configuration properties.
  --tenant-id: string # The id of the tenant to which the service is registered to.
  --type: string # The service type for the services onboarded to Azure Active Directory Connect Health. Depending on whether the service is monitoring, ADFS, Sync or ADDS roles, the service type can either be AdFederationService or AadSyncService or AdDomainService.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.ADHybridHealthService/addsservices"
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: activeAlerts, var: active_alerts}, {name: additionalInformation, var: additional_information}, {name: createdDate, var: created_date}, {name: customNotificationEmails, var: custom_notification_emails}, {name: disabled, var: disabled}, {name: displayName, var: display_name}, {name: health, var: health}, {name: id, var: id}, {name: lastDisabled, var: last_disabled}, {name: lastUpdated, var: last_updated}, {name: monitoringConfigurationsComputed, var: monitoring_configurations_computed}, {name: monitoringConfigurationsCustomized, var: monitoring_configurations_customized}, {name: notificationEmailEnabled, var: notification_email_enabled}, {name: notificationEmailEnabledForGlobalAdmins, var: notification_email_enabled_for_global_admins}, {name: notificationEmails, var: notification_emails}, {name: notificationEmailsEnabledForGlobalAdmins, var: notification_emails_enabled_for_global_admins}, {name: originalDisabledState, var: original_disabled_state}, {name: resolvedAlerts, var: resolved_alerts}, {name: serviceId, var: service_id}, {name: serviceName, var: service_name}, {name: signature, var: signature}, {name: simpleProperties, var: simple_properties}, {name: tenantId, var: tenant_id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, active_alerts: $active_alerts, additional_information: $additional_information, created_date: $created_date, custom_notification_emails: $custom_notification_emails, disabled: $disabled, display_name: $display_name, health: $health, id: $id, last_disabled: $last_disabled, last_updated: $last_updated, monitoring_configurations_computed: $monitoring_configurations_computed, monitoring_configurations_customized: $monitoring_configurations_customized, notification_email_enabled: $notification_email_enabled, notification_email_enabled_for_global_admins: $notification_email_enabled_for_global_admins, notification_emails: $notification_emails, notification_emails_enabled_for_global_admins: $notification_emails_enabled_for_global_admins, original_disabled_state: $original_disabled_state, resolved_alerts: $resolved_alerts, service_id: $service_id, service_name: $service_name, signature: $signature, simple_properties: $simple_properties, tenant_id: $tenant_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of Active Directory Domain Services for a tenant having Azure AD Premium license and is onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/premiumCheck
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>>
# operationId: addsServices_listPremiumServices
export def "adds-services-list-premium-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The service property filter to apply.
  --service-type: string # The service type for the services onboarded to Azure Active Directory Connect Health. Depending on whether the service is monitoring, ADFS, Sync or ADDS roles, the service type can either be AdFederationService or AadSyncService or AdDomainService.
  --skip-count: int # The skip count, which specifies the number of elements that can be bypassed from a sequence and then return the remaining elements.
  --take-count: int # The take count , which specifies the number of elements that can be returned from a sequence.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/premiumCheck"
    query: [{name: "$filter", var: filter}, {name: serviceType, var: service_type}, {name: skipCount, var: skip_count}, {name: takeCount, var: take_count}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, service_type: $service_type, skip_count: $skip_count, take_count: $take_count, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Active Directory Domain Service which is onboarded to Azure Active Directory Connect Health.
#
# DELETE /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}
# operationId: addsServices_delete
export def "adds-services-delete" [
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
  --confirm: oneof<nothing, bool> # Indicates if the service will be permanently deleted or disabled. True indicates that the service will be permanently deleted and False indicates that the service will be marked disabled and then deleted after 30 days, if it is not re-registered.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: confirm, var: confirm}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    service_name: $service_name, confirm: $confirm, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of an Active Directory Domain Service for a tenant having Azure AD Premium license and is onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}
# Returns: record<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list<string>, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list<string>, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>
# operationId: addsServices_get
export def "adds-services-get" [
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
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an Active Directory Domain Service properties of an onboarded service.
#
# PATCH /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}
# Returns: record<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list<string>, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list<string>, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>
# operationId: addsServices_update
export def "adds-services-update" [
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
  --api-version: string # The version of the API to be used with the client request. (required)
  --active-alerts: int # The count of alerts that are currently active for the service.
  --additional-information: string # The additional information related to the service.
  --created-date: string # The date and time, in UTC, when the service was onboarded to Azure Active Directory Connect Health. (format: date-time)
  --custom-notification-emails: list<string> # The list of additional emails that are configured to receive notifications about the service.
  --disabled: oneof<nothing, bool> # Indicates if the service is disabled or not.
  --display-name: string # The display name of the service.
  --health: string # The health of the service.
  --id: string # The id of the service.
  --last-disabled: string # The date and time, in UTC, when the service was last disabled. (format: date-time)
  --last-updated: string # The date or time , in UTC, when the service properties were last updated. (format: date-time)
  --monitoring-configurations-computed: record # The monitoring configuration of the service which determines what activities are monitored by Azure Active Directory Connect Health.
  --monitoring-configurations-customized: record # The customized monitoring configuration of the service which determines what activities are monitored by Azure Active Directory Connect Health.
  --notification-email-enabled: oneof<nothing, bool> # Indicates if email notification is enabled or not.
  --notification-email-enabled-for-global-admins: oneof<nothing, bool> # Indicates if email notification is enabled for global administrators of the tenant.
  --notification-emails: list<string> # The list of emails to whom service notifications will be sent.
  --notification-emails-enabled-for-global-admins: oneof<nothing, bool> # Indicates if email notification is enabled for global administrators of the tenant.
  --original-disabled-state: oneof<nothing, bool> # Gets the original disable state.
  --resolved-alerts: int # The total count of alerts that has been resolved for the service.
  --service-id: string # The id of the service.
  --body-service-name: string # The name of the service. (spec name: serviceName)
  --signature: string # The signature of the service.
  --simple-properties: record # List of service specific configuration properties.
  --tenant-id: string # The id of the tenant to which the service is registered to.
  --type: string # The service type for the services onboarded to Azure Active Directory Connect Health. Depending on whether the service is monitoring, ADFS, Sync or ADDS roles, the service type can either be AdFederationService or AadSyncService or AdDomainService.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: activeAlerts, var: active_alerts}, {name: additionalInformation, var: additional_information}, {name: createdDate, var: created_date}, {name: customNotificationEmails, var: custom_notification_emails}, {name: disabled, var: disabled}, {name: displayName, var: display_name}, {name: health, var: health}, {name: id, var: id}, {name: lastDisabled, var: last_disabled}, {name: lastUpdated, var: last_updated}, {name: monitoringConfigurationsComputed, var: monitoring_configurations_computed}, {name: monitoringConfigurationsCustomized, var: monitoring_configurations_customized}, {name: notificationEmailEnabled, var: notification_email_enabled}, {name: notificationEmailEnabledForGlobalAdmins, var: notification_email_enabled_for_global_admins}, {name: notificationEmails, var: notification_emails}, {name: notificationEmailsEnabledForGlobalAdmins, var: notification_emails_enabled_for_global_admins}, {name: originalDisabledState, var: original_disabled_state}, {name: resolvedAlerts, var: resolved_alerts}, {name: serviceId, var: service_id}, {name: serviceName, var: body_service_name}, {name: signature, var: signature}, {name: simpleProperties, var: simple_properties}, {name: tenantId, var: tenant_id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, api_version: $api_version, active_alerts: $active_alerts, additional_information: $additional_information, created_date: $created_date, custom_notification_emails: $custom_notification_emails, disabled: $disabled, display_name: $display_name, health: $health, id: $id, last_disabled: $last_disabled, last_updated: $last_updated, monitoring_configurations_computed: $monitoring_configurations_computed, monitoring_configurations_customized: $monitoring_configurations_customized, notification_email_enabled: $notification_email_enabled, notification_email_enabled_for_global_admins: $notification_email_enabled_for_global_admins, notification_emails: $notification_emails, notification_emails_enabled_for_global_admins: $notification_emails_enabled_for_global_admins, original_disabled_state: $original_disabled_state, resolved_alerts: $resolved_alerts, service_id: $service_id, body_service_name: $body_service_name, signature: $signature, simple_properties: $simple_properties, tenant_id: $tenant_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of the servers, for a given Active Directory Domain Service, that are onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/addomainservicemembers
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, addsRoles: list, createdDate: string, dcTypes: list, dimensions: list, disabled: bool, disabledReason: int, domainName: string, gcReachable: bool, installedQfes: list, isAdvertising: bool, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: list, monitoringConfigurationsCustomized: list, osName: string, osVersion: string, pdcReachable: bool, properties: list, recommendedQfes: list, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, siteName: string, status: string, sysvolState: bool, tenantId: string>>
# operationId: adDomainServiceMembers_list
export def "ad-domain-service-members-list" [
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
  --filter: string # The server property filter to apply.
  --is-groupby-site: oneof<nothing, bool> # Indicates if the result should be grouped by site or not. (required)
  --query: string # The custom query.
  --next-partition-key: string@next-partition-key-completer # The next partition key to query for. (required)
  --next-row-key: string@next-row-key-completer # The next row key to query for. (required)
  --take-count: int # The take count , which specifies the number of elements that can be returned from a sequence.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/addomainservicemembers"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: "$filter", var: filter}, {name: isGroupbySite, var: is_groupby_site, required: true}, {name: query, var: query}, {name: nextPartitionKey, var: next_partition_key, required: true, default: " "}, {name: nextRowKey, var: next_row_key, required: true, default: " "}, {name: takeCount, var: take_count}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, filter: $filter, is_groupby_site: $is_groupby_site, query: $query, next_partition_key: $next_partition_key, next_row_key: $next_row_key, take_count: $take_count, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of the Active Directory Domain servers, for a given Active Directory Domain Service, that are onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/addsservicemembers
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, addsRoles: list, createdDate: string, dcTypes: list, dimensions: list, disabled: bool, disabledReason: int, domainName: string, gcReachable: bool, installedQfes: list, isAdvertising: bool, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: list, monitoringConfigurationsCustomized: list, osName: string, osVersion: string, pdcReachable: bool, properties: list, recommendedQfes: list, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, siteName: string, status: string, sysvolState: bool, tenantId: string>>
# operationId: addsServiceMembers_list
export def "adds-service-members-list" [
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
  --filter: string # The server property filter to apply.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/addsservicemembers"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the alerts for a given Active Directory Domain Service.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/alerts
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlertProperties: list, additionalInformation: list, alertId: string, createdDate: string, description: string, displayName: string, lastUpdated: string, level: string, monitorRoleType: string, relatedLinks: list, remediation: string, resolvedAlertProperties: list, resolvedDate: string, scope: string, serviceId: string, serviceMemberId: string, shortName: string, state: string, tenantId: string>>
# operationId: alerts_listAddsAlerts
export def "alerts-list-adds-alerts" [
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
  --filter: string # The alert property filter to apply.
  --state: string # The alert state to query for.
  --from: string # The start date to query for. (format: date-time)
  --to: string # The end date till when to query for. (format: date-time)
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/alerts"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: "$filter", var: filter}, {name: state, var: state}, {name: from, var: from}, {name: to, var: to}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, filter: $filter, state: $state, from: $from, to: $to, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the service configurations.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/configuration
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<key: string, value: string>>
# operationId: configuration_listAddsConfigurations
export def "configuration-list-adds-configurations" [
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
  --grouping: string # The grouping for configurations.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/configuration"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: grouping, var: grouping}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, grouping: $grouping
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the dimensions for a given dimension type in a server.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/dimensions/{dimension}
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, displayName: string, health: string, lastUpdated: string, resolvedAlerts: int, signature: string, simpleProperties: record, type: string>>
# operationId: dimensions_listAddsDimensions
export def "dimensions-list-adds-dimensions" [
  service_name: string
  dimension: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/dimensions/{dimension}"
    path_params: [{name: serviceName, var: service_name}, {name: dimension, var: dimension}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, dimension: $dimension, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the user preferences for a given feature.
#
# DELETE /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/features/{featureName}/userpreference
# operationId: addsServicesUserPreference_delete
export def "adds-services-user-preference-delete" [
  service_name: string
  feature_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/features/{featureName}/userpreference"
    path_params: [{name: serviceName, var: service_name}, {name: featureName, var: feature_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, feature_name: $feature_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the user preferences for a given feature.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/features/{featureName}/userpreference
# Returns: record<metricNames: list<string>>
# operationId: addsServicesUserPreference_get
export def "adds-services-user-preference-get" [
  service_name: string
  feature_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/features/{featureName}/userpreference"
    path_params: [{name: serviceName, var: service_name}, {name: featureName, var: feature_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, feature_name: $feature_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds the user preferences for a given feature.
#
# POST /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/features/{featureName}/userpreference
# operationId: addsServicesUserPreference_add
export def "adds-services-user-preference-add" [
  service_name: string
  feature_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
  --metric-names: list<string> # The name of the metric.
]: any -> any {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/features/{featureName}/userpreference"
    path_params: [{name: serviceName, var: service_name}, {name: featureName, var: feature_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: metricNames, var: metric_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, feature_name: $feature_name, api_version: $api_version, metric_names: $metric_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the forest summary for a given Active Directory Domain Service, that is onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/forestsummary
# Returns: record<domainCount: int, domains: list<string>, forestName: string, monitoredDcCount: int, siteCount: int, sites: list<string>, totalDcCount: int>
# operationId: addsServices_getForestSummary
export def "adds-services-get-forest-summary" [
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
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/forestsummary"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the service related metrics information.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/metricmetadata
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<displayName: string, groupings: list, isDefault: bool, isDevOps: bool, isPerfCounter: bool, kind: string, maxValue: int, metricName: string, metricsProcessorClassName: string, minValue: int, valueKind: string>>
# operationId: addsServices_listMetricMetadata
export def "adds-services-list-metric-metadata" [
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
  --filter: string # The metric metadata property filter to apply.
  --perf-counter: oneof<nothing, bool> # Indicates if only performance counter metrics are requested.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/metricmetadata"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: "$filter", var: filter}, {name: perfCounter, var: perf_counter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, filter: $filter, perf_counter: $perf_counter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the service related metric information.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/metricmetadata/{metricName}
# Returns: record<displayName: string, groupings: table<displayName: string, invisibleForUi: bool, key: string>, isDefault: bool, isDevOps: bool, isPerfCounter: bool, kind: string, maxValue: int, metricName: string, metricsProcessorClassName: string, minValue: int, valueKind: string>
# operationId: addsServices_getMetricMetadata
export def "adds-services-get-metric-metadata" [
  service_name: string
  metric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/metricmetadata/{metricName}"
    path_params: [{name: serviceName, var: service_name}, {name: metricName, var: metric_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, metric_name: $metric_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the service related metrics for a given metric and group combination.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/metricmetadata/{metricName}/groups/{groupName}
# Returns: record<sets: table<setName: string, values: list>, timeStamps: list<string>>
# operationId: addsServices_getMetricMetadataForGroup
export def "adds-services-get-metric-metadata-for-group" [
  service_name: string
  metric_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-key: string # The group key
  --from-date: string # The start date. (format: date-time)
  --to-date: string # The end date. (format: date-time)
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/metricmetadata/{metricName}/groups/{groupName}"
    path_params: [{name: serviceName, var: service_name}, {name: metricName, var: metric_name}, {name: groupName, var: group_name}]
    query: [{name: groupKey, var: group_key}, {name: fromDate, var: from_date}, {name: toDate, var: to_date}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, metric_name: $metric_name, group_name: $group_name, group_key: $group_key, from_date: $from_date, to_date: $to_date, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the server related metrics for a given metric and group combination.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/metrics/{metricName}/groups/{groupName}
# Returns: record<sets: table<setName: string, values: list>, timeStamps: list<string>>
# operationId: addsService_getMetrics
export def "adds-service-get-metrics" [
  service_name: string
  metric_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-key: string # The group key
  --from-date: string # The start date. (format: date-time)
  --to-date: string # The end date. (format: date-time)
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/metrics/{metricName}/groups/{groupName}"
    path_params: [{name: serviceName, var: service_name}, {name: metricName, var: metric_name}, {name: groupName, var: group_name}]
    query: [{name: groupKey, var: group_key}, {name: fromDate, var: from_date}, {name: toDate, var: to_date}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, metric_name: $metric_name, group_name: $group_name, group_key: $group_key, from_date: $from_date, to_date: $to_date, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the average of the metric values for a given metric and group combination.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/metrics/{metricName}/groups/{groupName}/average
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<key: string, value: string>>
# operationId: addsServices_listMetricsAverage
export def "adds-services-list-metrics-average" [
  service_name: string
  metric_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/metrics/{metricName}/groups/{groupName}/average"
    path_params: [{name: serviceName, var: service_name}, {name: metricName, var: metric_name}, {name: groupName, var: group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, metric_name: $metric_name, group_name: $group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the sum of the metric values for a given metric and group combination.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/metrics/{metricName}/groups/{groupName}/sum
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<key: string, value: string>>
# operationId: addsServices_listMetricsSum
export def "adds-services-list-metrics-sum" [
  service_name: string
  metric_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/metrics/{metricName}/groups/{groupName}/sum"
    path_params: [{name: serviceName, var: service_name}, {name: metricName, var: metric_name}, {name: groupName, var: group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, metric_name: $metric_name, group_name: $group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets complete domain controller list along with replication details for a given Active Directory Domain Service, that is onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/replicationdetails
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<domain: string, inboundNeighborCollection: list, lastAttemptedSync: string, lastSuccessfulSync: string, site: string, status: int, targetServer: string>>
# operationId: addsServices_listReplicationDetails
export def "adds-services-list-replication-details" [
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
  --filter: string # The server property filter to apply.
  --with-details: oneof<nothing, bool> # Indicates if InboundReplicationNeighbor details are required or not.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/replicationdetails"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: "$filter", var: filter}, {name: withDetails, var: with_details}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, filter: $filter, with_details: $with_details, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets Replication status for a given Active Directory Domain Service, that is onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/replicationstatus
# Returns: record<errorDcCount: int, forestName: string, totalDcCount: int>
# operationId: addsServicesReplicationStatus_get
export def "adds-services-replication-status-get" [
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
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/replicationstatus"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets complete domain controller list along with replication details for a given Active Directory Domain Service, that is onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/replicationsummary
# Returns: record<value: table<domain: string, inboundNeighborCollection: list, lastAttemptedSync: string, lastSuccessfulSync: string, site: string, status: int, targetServer: string>>
# operationId: addsServices_listReplicationSummary
export def "adds-services-list-replication-summary" [
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
  --filter: string # The server property filter to apply.
  --is-groupby-site: oneof<nothing, bool> # Indicates if the result should be grouped by site or not. (required)
  --query: string # The custom query. (required)
  --next-partition-key: string@next-partition-key-completer # The next partition key to query for. (required)
  --next-row-key: string@next-row-key-completer # The next row key to query for. (required)
  --take-count: int # The take count , which specifies the number of elements that can be returned from a sequence.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/replicationsummary"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: "$filter", var: filter}, {name: isGroupbySite, var: is_groupby_site, required: true}, {name: query, var: query, required: true}, {name: nextPartitionKey, var: next_partition_key, required: true, default: " "}, {name: nextRowKey, var: next_row_key, required: true, default: " "}, {name: takeCount, var: take_count}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, filter: $filter, is_groupby_site: $is_groupby_site, query: $query, next_partition_key: $next_partition_key, next_row_key: $next_row_key, take_count: $take_count, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of the servers, for a given Active Directory Domain Controller service, that are onboarded to Azure Active Directory Connect Health Service.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/servicemembers
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, createdDate: string, dimensions: record, disabled: bool, disabledReason: int, installedQfes: record, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, osName: string, osVersion: string, properties: record, recommendedQfes: record, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, status: string, tenantId: string>>
# operationId: addsServicesServiceMembers_list
export def "adds-services-service-members-list" [
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
  --filter: string # The server property filter to apply.
  --dimension-type: string # The server specific dimension.
  --dimension-signature: string # The value of the dimension.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/servicemembers"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: "$filter", var: filter}, {name: dimensionType, var: dimension_type}, {name: dimensionSignature, var: dimension_signature}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, filter: $filter, dimension_type: $dimension_type, dimension_signature: $dimension_signature, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Onboards a server, for a given Active Directory Domain Controller service, to Azure Active Directory Connect Health Service.
#
# POST /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/servicemembers
# Returns: record<activeAlerts: int, additionalInformation: string, createdDate: string, dimensions: record, disabled: bool, disabledReason: int, installedQfes: record, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, osName: string, osVersion: string, properties: record, recommendedQfes: record, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, status: string, tenantId: string>
# operationId: addsServicesServiceMembers_add
export def "adds-services-service-members-add" [
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
  --api-version: string # The version of the API to be used with the client request. (required)
  --active-alerts: int # The total number of alerts that are currently active for the server.
  --additional-information: string # The additional information, if any, for the server.
  --created-date: string # The date time , in UTC, when the server was onboarded to Azure Active Directory Connect Health. (format: date-time)
  --dimensions: record # The server specific configuration related dimensions.
  --disabled: oneof<nothing, bool> # Indicates if the server is disabled or not.
  --disabled-reason: int # The reason for disabling the server.
  --installed-qfes: record # The list of installed QFEs for the server.
  --last-disabled: string # The date and time , in UTC, when the server was last disabled. (format: date-time)
  --last-reboot: string # The date and time, in UTC, when the server was last rebooted. (format: date-time)
  --last-server-reported-monitoring-level-change: string # The date and time, in UTC, when the server's data monitoring configuration was last changed. (format: date-time)
  --last-updated: string # The date and time, in UTC, when the server properties were last updated. (format: date-time)
  --machine-id: string # The id of the machine.
  --machine-name: string # The name of the server.
  --monitoring-configurations-computed: record # The monitoring configuration of the server which determines what activities are monitored by Azure Active Directory Connect Health.
  --monitoring-configurations-customized: record # The customized monitoring configuration of the server which determines what activities are monitored by Azure Active Directory Connect Health.
  --os-name: string # The name of the operating system installed in the machine.
  --os-version: string # The version of the operating system installed in the machine.
  --properties: record # Server specific properties.
  --recommended-qfes: record # The list of recommended hotfixes for the server.
  --resolved-alerts: int # The total count of alerts that are resolved for this server.
  --role: string # The service role that is being monitored in the server.
  --server-reported-monitoring-level: string@server-reported-monitoring-level-completer # The monitoring level reported by the server.
  --service-id: string # The service id to whom this server belongs.
  --service-member-id: string # The id of the server.
  --status: string # The health status of the server.
  --tenant-id: string # The tenant id to whom this server belongs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/servicemembers"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: activeAlerts, var: active_alerts}, {name: additionalInformation, var: additional_information}, {name: createdDate, var: created_date}, {name: dimensions, var: dimensions}, {name: disabled, var: disabled}, {name: disabledReason, var: disabled_reason}, {name: installedQfes, var: installed_qfes}, {name: lastDisabled, var: last_disabled}, {name: lastReboot, var: last_reboot}, {name: lastServerReportedMonitoringLevelChange, var: last_server_reported_monitoring_level_change}, {name: lastUpdated, var: last_updated}, {name: machineId, var: machine_id}, {name: machineName, var: machine_name}, {name: monitoringConfigurationsComputed, var: monitoring_configurations_computed}, {name: monitoringConfigurationsCustomized, var: monitoring_configurations_customized}, {name: osName, var: os_name}, {name: osVersion, var: os_version}, {name: properties, var: properties}, {name: recommendedQfes, var: recommended_qfes}, {name: resolvedAlerts, var: resolved_alerts}, {name: role, var: role}, {name: serverReportedMonitoringLevel, var: server_reported_monitoring_level}, {name: serviceId, var: service_id}, {name: serviceMemberId, var: service_member_id}, {name: status, var: status}, {name: tenantId, var: tenant_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, api_version: $api_version, active_alerts: $active_alerts, additional_information: $additional_information, created_date: $created_date, dimensions: $dimensions, disabled: $disabled, disabled_reason: $disabled_reason, installed_qfes: $installed_qfes, last_disabled: $last_disabled, last_reboot: $last_reboot, last_server_reported_monitoring_level_change: $last_server_reported_monitoring_level_change, last_updated: $last_updated, machine_id: $machine_id, machine_name: $machine_name, monitoring_configurations_computed: $monitoring_configurations_computed, monitoring_configurations_customized: $monitoring_configurations_customized, os_name: $os_name, os_version: $os_version, properties: $properties, recommended_qfes: $recommended_qfes, resolved_alerts: $resolved_alerts, role: $role, server_reported_monitoring_level: $server_reported_monitoring_level, service_id: $service_id, service_member_id: $service_member_id, status: $status, tenant_id: $tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Active Directory Domain Controller server that has been onboarded to Azure Active Directory Connect Health Service.
#
# DELETE /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/servicemembers/{serviceMemberId}
# operationId: addsServiceMembers_delete
export def "adds-service-members-delete" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --confirm: oneof<nothing, bool> # Indicates if the server will be permanently deleted or disabled. True indicates that the server will be permanently deleted and False indicates that the server will be marked disabled and then deleted after 30 days, if it is not re-registered.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/servicemembers/{serviceMemberId}"
    path_params: [{name: serviceName, var: service_name}, {name: serviceMemberId, var: service_member_id}]
    query: [{name: confirm, var: confirm}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, service_member_id: $service_member_id, confirm: $confirm, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of a server, for a given Active Directory Domain Controller service, that are onboarded to Azure Active Directory Connect Health Service.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/servicemembers/{serviceMemberId}
# Returns: record<activeAlerts: int, additionalInformation: string, createdDate: string, dimensions: record, disabled: bool, disabledReason: int, installedQfes: record, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, osName: string, osVersion: string, properties: record, recommendedQfes: record, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, status: string, tenantId: string>
# operationId: addsServiceMembers_get
export def "adds-service-members-get" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/servicemembers/{serviceMemberId}"
    path_params: [{name: serviceName, var: service_name}, {name: serviceMemberId, var: service_member_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, service_member_id: $service_member_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of an alert for a given Active Directory Domain Controller service and server combination.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/servicemembers/{serviceMemberId}/alerts
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlertProperties: list, additionalInformation: list, alertId: string, createdDate: string, description: string, displayName: string, lastUpdated: string, level: string, monitorRoleType: string, relatedLinks: list, remediation: string, resolvedAlertProperties: list, resolvedDate: string, scope: string, serviceId: string, serviceMemberId: string, shortName: string, state: string, tenantId: string>>
# operationId: addsServices_listServerAlerts
export def "adds-services-list-server-alerts" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The alert property filter to apply.
  --state: string # The alert state to query for.
  --from: string # The start date to query for. (format: date-time)
  --to: string # The end date till when to query for. (format: date-time)
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/servicemembers/{serviceMemberId}/alerts"
    path_params: [{name: serviceName, var: service_name}, {name: serviceMemberId, var: service_member_id}]
    query: [{name: "$filter", var: filter}, {name: state, var: state}, {name: from, var: from}, {name: to, var: to}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, service_member_id: $service_member_id, filter: $filter, state: $state, from: $from, to: $to, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the credentials of the server which is needed by the agent to connect to Azure Active Directory Connect Health Service.
#
# GET /providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/servicemembers/{serviceMemberId}/credentials
# Returns: record<value: table<credentialData: list, identifier: string, type: string>>
# operationId: addsServiceMembers_listCredentials
export def "adds-service-members-list-credentials" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The property filter to apply.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/addsservices/{serviceName}/servicemembers/{serviceMemberId}/credentials"
    path_params: [{name: serviceName, var: service_name}, {name: serviceMemberId, var: service_member_id}]
    query: [{name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, service_member_id: $service_member_id, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of a tenant onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/configuration
# Returns: record<aadLicense: string, aadPremium: bool, agentAutoUpdate: bool, alertSuppressionTimeInMins: int, consentedToMicrosoftDevOps: bool, countryLetterCode: string, createdDate: string, devOpsTtl: string, disabled: bool, disabledReason: int, globalAdminsEmail: list<string>, initialDomain: string, lastDisabled: string, lastVerified: string, onboarded: bool, onboardingAllowed: bool, pksCertificate: record, privatePreviewTenant: bool, tenantId: string, tenantInQuarantine: bool, tenantName: string>
# operationId: configuration_get
export def "configuration-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/configuration"
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates tenant properties for tenants onboarded to Azure Active Directory Connect Health.
#
# PATCH /providers/Microsoft.ADHybridHealthService/configuration
# Returns: record<aadLicense: string, aadPremium: bool, agentAutoUpdate: bool, alertSuppressionTimeInMins: int, consentedToMicrosoftDevOps: bool, countryLetterCode: string, createdDate: string, devOpsTtl: string, disabled: bool, disabledReason: int, globalAdminsEmail: list<string>, initialDomain: string, lastDisabled: string, lastVerified: string, onboarded: bool, onboardingAllowed: bool, pksCertificate: record, privatePreviewTenant: bool, tenantId: string, tenantInQuarantine: bool, tenantName: string>
# operationId: configuration_update
export def "configuration-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
  --aad-license: string # The Azure Active Directory license of the tenant.
  --aad-premium: oneof<nothing, bool> # Indicate if the tenant has Azure Active Directory Premium license or not.
  --agent-auto-update: oneof<nothing, bool> # Indicates if the tenant is configured to automatically receive updates for Azure Active Directory Connect Health client side features.
  --alert-suppression-time-in-mins: int # The time in minutes after which an alert will be auto-suppressed.
  --consented-to-microsoft-dev-ops: oneof<nothing, bool> # Indicates if the tenant data can be seen by Microsoft through Azure portal.
  --country-letter-code: string # The country letter code of the tenant.
  --created-date: string # The date, in UTC, when the tenant was onboarded to Azure Active Directory Connect Health. (format: date-time)
  --dev-ops-ttl: string # The date and time, in UTC, till when the tenant data can be seen by Microsoft through Azure portal. (format: date-time)
  --disabled: oneof<nothing, bool> # Indicates if the tenant is disabled in Azure Active Directory Connect Health.
  --disabled-reason: int # The reason due to which the tenant was disabled in Azure Active Directory Connect Health.
  --global-admins-email: list<string> # The list of global administrators for the tenant.
  --initial-domain: string # The initial domain of the tenant.
  --last-disabled: string # The date and time, in UTC, when the tenant was last disabled in Azure Active Directory Connect Health. (format: date-time)
  --last-verified: string # The date and time, in UTC, when the tenant onboarding status in Azure Active Directory Connect Health was last verified. (format: date-time)
  --onboarded: oneof<nothing, bool> # Indicates if the tenant is already onboarded to Azure Active Directory Connect Health.
  --onboarding-allowed: oneof<nothing, bool> # Indicates if the tenant is allowed to onboard to Azure Active Directory Connect Health.
  --pks-certificate: record # The certificate associated with the tenant to onboard data to Azure Active Directory Connect Health.
  --private-preview-tenant: oneof<nothing, bool> # Indicates if the tenant has signed up for private preview of Azure Active Directory Connect Health features.
  --tenant-id: string # The Id of the tenant.
  --tenant-in-quarantine: oneof<nothing, bool> # Indicates if data collection for this tenant is disabled or not.
  --tenant-name: string # The name of the tenant.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/providers/Microsoft.ADHybridHealthService/configuration"
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: aadLicense, var: aad_license}, {name: aadPremium, var: aad_premium}, {name: agentAutoUpdate, var: agent_auto_update}, {name: alertSuppressionTimeInMins, var: alert_suppression_time_in_mins}, {name: consentedToMicrosoftDevOps, var: consented_to_microsoft_dev_ops}, {name: countryLetterCode, var: country_letter_code}, {name: createdDate, var: created_date}, {name: devOpsTtl, var: dev_ops_ttl}, {name: disabled, var: disabled}, {name: disabledReason, var: disabled_reason}, {name: globalAdminsEmail, var: global_admins_email}, {name: initialDomain, var: initial_domain}, {name: lastDisabled, var: last_disabled}, {name: lastVerified, var: last_verified}, {name: onboarded, var: onboarded}, {name: onboardingAllowed, var: onboarding_allowed}, {name: pksCertificate, var: pks_certificate}, {name: privatePreviewTenant, var: private_preview_tenant}, {name: tenantId, var: tenant_id}, {name: tenantInQuarantine, var: tenant_in_quarantine}, {name: tenantName, var: tenant_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, aad_license: $aad_license, aad_premium: $aad_premium, agent_auto_update: $agent_auto_update, alert_suppression_time_in_mins: $alert_suppression_time_in_mins, consented_to_microsoft_dev_ops: $consented_to_microsoft_dev_ops, country_letter_code: $country_letter_code, created_date: $created_date, dev_ops_ttl: $dev_ops_ttl, disabled: $disabled, disabled_reason: $disabled_reason, global_admins_email: $global_admins_email, initial_domain: $initial_domain, last_disabled: $last_disabled, last_verified: $last_verified, onboarded: $onboarded, onboarding_allowed: $onboarding_allowed, pks_certificate: $pks_certificate, private_preview_tenant: $private_preview_tenant, tenant_id: $tenant_id, tenant_in_quarantine: $tenant_in_quarantine, tenant_name: $tenant_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Onboards a tenant in Azure Active Directory Connect Health.
#
# POST /providers/Microsoft.ADHybridHealthService/configuration
# Returns: record<aadLicense: string, aadPremium: bool, agentAutoUpdate: bool, alertSuppressionTimeInMins: int, consentedToMicrosoftDevOps: bool, countryLetterCode: string, createdDate: string, devOpsTtl: string, disabled: bool, disabledReason: int, globalAdminsEmail: list<string>, initialDomain: string, lastDisabled: string, lastVerified: string, onboarded: bool, onboardingAllowed: bool, pksCertificate: record, privatePreviewTenant: bool, tenantId: string, tenantInQuarantine: bool, tenantName: string>
# operationId: configuration_add
export def "configuration-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/providers/Microsoft.ADHybridHealthService/configuration"
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the available Azure Data Factory API operations.
#
# GET /providers/Microsoft.ADHybridHealthService/operations
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<display: record, name: string>>
# operationId: operations_list
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
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/operations"
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks if the user is enabled for Dev Ops access.
#
# GET /providers/Microsoft.ADHybridHealthService/reports/DevOps/IsDevOps
# Returns: record<value: bool>
# operationId: reports_getDevOps
export def "reports-get-dev-ops" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/reports/DevOps/IsDevOps"
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the connector details for a service.
#
# GET /providers/Microsoft.ADHybridHealthService/service/{serviceName}/servicemembers/{serviceMemberId}/connectors
# Returns: record<value: table<attributesIncluded: list, classesIncluded: list, connectorId: string, description: string, id: string, name: string, partitions: list, passwordHashSyncConfiguration: record, passwordManagementSettings: record, runProfiles: list, schemaXml: string, timeCreated: string, timeLastModified: string, type: string, version: int>>
# operationId: serviceMembers_listConnectors
export def "service-members-list-connectors" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/service/{serviceName}/servicemembers/{serviceMemberId}/connectors"
    path_params: [{name: serviceName, var: service_name}, {name: serviceMemberId, var: service_member_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, service_member_id: $service_member_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of services, for a tenant, that are onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/services
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>>
# operationId: services_list
export def "services-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The service property filter to apply.
  --service-type: string # The service type for the services onboarded to Azure Active Directory Connect Health. Depending on whether the service is monitoring, ADFS, Sync or ADDS roles, the service type can either be AdFederationService or AadSyncService or AdDomainService.
  --skip-count: int # The skip count, which specifies the number of elements that can be bypassed from a sequence and then return the remaining elements.
  --take-count: int # The take count , which specifies the number of elements that can be returned from a sequence.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services"
    query: [{name: "$filter", var: filter}, {name: serviceType, var: service_type}, {name: skipCount, var: skip_count}, {name: takeCount, var: take_count}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, service_type: $service_type, skip_count: $skip_count, take_count: $take_count, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Onboards a service for a given tenant in Azure Active Directory Connect Health.
#
# POST /providers/Microsoft.ADHybridHealthService/services
# Returns: record<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list<string>, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list<string>, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>
# operationId: services_add
export def "services-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
  --active-alerts: int # The count of alerts that are currently active for the service.
  --additional-information: string # The additional information related to the service.
  --created-date: string # The date and time, in UTC, when the service was onboarded to Azure Active Directory Connect Health. (format: date-time)
  --custom-notification-emails: list<string> # The list of additional emails that are configured to receive notifications about the service.
  --disabled: oneof<nothing, bool> # Indicates if the service is disabled or not.
  --display-name: string # The display name of the service.
  --health: string # The health of the service.
  --id: string # The id of the service.
  --last-disabled: string # The date and time, in UTC, when the service was last disabled. (format: date-time)
  --last-updated: string # The date or time , in UTC, when the service properties were last updated. (format: date-time)
  --monitoring-configurations-computed: record # The monitoring configuration of the service which determines what activities are monitored by Azure Active Directory Connect Health.
  --monitoring-configurations-customized: record # The customized monitoring configuration of the service which determines what activities are monitored by Azure Active Directory Connect Health.
  --notification-email-enabled: oneof<nothing, bool> # Indicates if email notification is enabled or not.
  --notification-email-enabled-for-global-admins: oneof<nothing, bool> # Indicates if email notification is enabled for global administrators of the tenant.
  --notification-emails: list<string> # The list of emails to whom service notifications will be sent.
  --notification-emails-enabled-for-global-admins: oneof<nothing, bool> # Indicates if email notification is enabled for global administrators of the tenant.
  --original-disabled-state: oneof<nothing, bool> # Gets the original disable state.
  --resolved-alerts: int # The total count of alerts that has been resolved for the service.
  --service-id: string # The id of the service.
  --service-name: string # The name of the service.
  --signature: string # The signature of the service.
  --simple-properties: record # List of service specific configuration properties.
  --tenant-id: string # The id of the tenant to which the service is registered to.
  --type: string # The service type for the services onboarded to Azure Active Directory Connect Health. Depending on whether the service is monitoring, ADFS, Sync or ADDS roles, the service type can either be AdFederationService or AadSyncService or AdDomainService.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.ADHybridHealthService/services"
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: activeAlerts, var: active_alerts}, {name: additionalInformation, var: additional_information}, {name: createdDate, var: created_date}, {name: customNotificationEmails, var: custom_notification_emails}, {name: disabled, var: disabled}, {name: displayName, var: display_name}, {name: health, var: health}, {name: id, var: id}, {name: lastDisabled, var: last_disabled}, {name: lastUpdated, var: last_updated}, {name: monitoringConfigurationsComputed, var: monitoring_configurations_computed}, {name: monitoringConfigurationsCustomized, var: monitoring_configurations_customized}, {name: notificationEmailEnabled, var: notification_email_enabled}, {name: notificationEmailEnabledForGlobalAdmins, var: notification_email_enabled_for_global_admins}, {name: notificationEmails, var: notification_emails}, {name: notificationEmailsEnabledForGlobalAdmins, var: notification_emails_enabled_for_global_admins}, {name: originalDisabledState, var: original_disabled_state}, {name: resolvedAlerts, var: resolved_alerts}, {name: serviceId, var: service_id}, {name: serviceName, var: service_name}, {name: signature, var: signature}, {name: simpleProperties, var: simple_properties}, {name: tenantId, var: tenant_id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, active_alerts: $active_alerts, additional_information: $additional_information, created_date: $created_date, custom_notification_emails: $custom_notification_emails, disabled: $disabled, display_name: $display_name, health: $health, id: $id, last_disabled: $last_disabled, last_updated: $last_updated, monitoring_configurations_computed: $monitoring_configurations_computed, monitoring_configurations_customized: $monitoring_configurations_customized, notification_email_enabled: $notification_email_enabled, notification_email_enabled_for_global_admins: $notification_email_enabled_for_global_admins, notification_emails: $notification_emails, notification_emails_enabled_for_global_admins: $notification_emails_enabled_for_global_admins, original_disabled_state: $original_disabled_state, resolved_alerts: $resolved_alerts, service_id: $service_id, service_name: $service_name, signature: $signature, simple_properties: $simple_properties, tenant_id: $tenant_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of services for a tenant having Azure AD Premium license and is onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/services/premiumCheck
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>>
# operationId: services_listPremium
export def "services-list-premium" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The service property filter to apply.
  --service-type: string # The service type for the services onboarded to Azure Active Directory Connect Health. Depending on whether the service is monitoring, ADFS, Sync or ADDS roles, the service type can either be AdFederationService or AadSyncService or AdDomainService.
  --skip-count: int # The skip count, which specifies the number of elements that can be bypassed from a sequence and then return the remaining elements.
  --take-count: int # The take count , which specifies the number of elements that can be returned from a sequence.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/premiumCheck"
    query: [{name: "$filter", var: filter}, {name: serviceType, var: service_type}, {name: skipCount, var: skip_count}, {name: takeCount, var: take_count}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, service_type: $service_type, skip_count: $skip_count, take_count: $take_count, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a service which is onboarded to Azure Active Directory Connect Health.
#
# DELETE /providers/Microsoft.ADHybridHealthService/services/{serviceName}
# operationId: services_delete
export def "services-delete" [
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
  --confirm: oneof<nothing, bool> # Indicates if the service will be permanently deleted or disabled. True indicates that the service will be permanently deleted and False indicates that the service will be marked disabled and then deleted after 30 days, if it is not re-registered.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: confirm, var: confirm}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    service_name: $service_name, confirm: $confirm, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of a service for a tenant having Azure AD Premium license and is onboarded to Azure Active Directory Connect Health.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}
# Returns: record<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list<string>, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list<string>, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>
# operationId: services_get
export def "services-get" [
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
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the service properties of an onboarded service.
#
# PATCH /providers/Microsoft.ADHybridHealthService/services/{serviceName}
# Returns: record<activeAlerts: int, additionalInformation: string, createdDate: string, customNotificationEmails: list<string>, disabled: bool, displayName: string, health: string, id: string, lastDisabled: string, lastUpdated: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, notificationEmailEnabled: bool, notificationEmailEnabledForGlobalAdmins: bool, notificationEmails: list<string>, notificationEmailsEnabledForGlobalAdmins: bool, originalDisabledState: bool, resolvedAlerts: int, serviceId: string, serviceName: string, signature: string, simpleProperties: record, tenantId: string, type: string>
# operationId: services_update
export def "services-update" [
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
  --api-version: string # The version of the API to be used with the client request. (required)
  --active-alerts: int # The count of alerts that are currently active for the service.
  --additional-information: string # The additional information related to the service.
  --created-date: string # The date and time, in UTC, when the service was onboarded to Azure Active Directory Connect Health. (format: date-time)
  --custom-notification-emails: list<string> # The list of additional emails that are configured to receive notifications about the service.
  --disabled: oneof<nothing, bool> # Indicates if the service is disabled or not.
  --display-name: string # The display name of the service.
  --health: string # The health of the service.
  --id: string # The id of the service.
  --last-disabled: string # The date and time, in UTC, when the service was last disabled. (format: date-time)
  --last-updated: string # The date or time , in UTC, when the service properties were last updated. (format: date-time)
  --monitoring-configurations-computed: record # The monitoring configuration of the service which determines what activities are monitored by Azure Active Directory Connect Health.
  --monitoring-configurations-customized: record # The customized monitoring configuration of the service which determines what activities are monitored by Azure Active Directory Connect Health.
  --notification-email-enabled: oneof<nothing, bool> # Indicates if email notification is enabled or not.
  --notification-email-enabled-for-global-admins: oneof<nothing, bool> # Indicates if email notification is enabled for global administrators of the tenant.
  --notification-emails: list<string> # The list of emails to whom service notifications will be sent.
  --notification-emails-enabled-for-global-admins: oneof<nothing, bool> # Indicates if email notification is enabled for global administrators of the tenant.
  --original-disabled-state: oneof<nothing, bool> # Gets the original disable state.
  --resolved-alerts: int # The total count of alerts that has been resolved for the service.
  --service-id: string # The id of the service.
  --body-service-name: string # The name of the service. (spec name: serviceName)
  --signature: string # The signature of the service.
  --simple-properties: record # List of service specific configuration properties.
  --tenant-id: string # The id of the tenant to which the service is registered to.
  --type: string # The service type for the services onboarded to Azure Active Directory Connect Health. Depending on whether the service is monitoring, ADFS, Sync or ADDS roles, the service type can either be AdFederationService or AadSyncService or AdDomainService.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: activeAlerts, var: active_alerts}, {name: additionalInformation, var: additional_information}, {name: createdDate, var: created_date}, {name: customNotificationEmails, var: custom_notification_emails}, {name: disabled, var: disabled}, {name: displayName, var: display_name}, {name: health, var: health}, {name: id, var: id}, {name: lastDisabled, var: last_disabled}, {name: lastUpdated, var: last_updated}, {name: monitoringConfigurationsComputed, var: monitoring_configurations_computed}, {name: monitoringConfigurationsCustomized, var: monitoring_configurations_customized}, {name: notificationEmailEnabled, var: notification_email_enabled}, {name: notificationEmailEnabledForGlobalAdmins, var: notification_email_enabled_for_global_admins}, {name: notificationEmails, var: notification_emails}, {name: notificationEmailsEnabledForGlobalAdmins, var: notification_emails_enabled_for_global_admins}, {name: originalDisabledState, var: original_disabled_state}, {name: resolvedAlerts, var: resolved_alerts}, {name: serviceId, var: service_id}, {name: serviceName, var: body_service_name}, {name: signature, var: signature}, {name: simpleProperties, var: simple_properties}, {name: tenantId, var: tenant_id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, api_version: $api_version, active_alerts: $active_alerts, additional_information: $additional_information, created_date: $created_date, custom_notification_emails: $custom_notification_emails, disabled: $disabled, display_name: $display_name, health: $health, id: $id, last_disabled: $last_disabled, last_updated: $last_updated, monitoring_configurations_computed: $monitoring_configurations_computed, monitoring_configurations_customized: $monitoring_configurations_customized, notification_email_enabled: $notification_email_enabled, notification_email_enabled_for_global_admins: $notification_email_enabled_for_global_admins, notification_emails: $notification_emails, notification_emails_enabled_for_global_admins: $notification_emails_enabled_for_global_admins, original_disabled_state: $original_disabled_state, resolved_alerts: $resolved_alerts, service_id: $service_id, body_service_name: $body_service_name, signature: $signature, simple_properties: $simple_properties, tenant_id: $tenant_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks if the tenant, to which a service is registered, is whitelisted to use a feature.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/TenantWhitelisting/{featureName}
# Returns: record<value: bool>
# operationId: services_getTenantWhitelisting
export def "services-get-tenant-whitelisting" [
  service_name: string
  feature_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/TenantWhitelisting/{featureName}"
    path_params: [{name: serviceName, var: service_name}, {name: featureName, var: feature_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, feature_name: $feature_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the alerts for a given service.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/alerts
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlertProperties: list, additionalInformation: list, alertId: string, createdDate: string, description: string, displayName: string, lastUpdated: string, level: string, monitorRoleType: string, relatedLinks: list, remediation: string, resolvedAlertProperties: list, resolvedDate: string, scope: string, serviceId: string, serviceMemberId: string, shortName: string, state: string, tenantId: string>>
# operationId: services_listAlerts
export def "services-list-alerts" [
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
  --filter: string # The alert property filter to apply.
  --state: string # The alert state to query for.
  --from: string # The start date to query for. (format: date-time)
  --to: string # The end date till when to query for. (format: date-time)
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/alerts"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: "$filter", var: filter}, {name: state, var: state}, {name: from, var: from}, {name: to, var: to}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, filter: $filter, state: $state, from: $from, to: $to, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks if the service has all the pre-requisites met to use a feature.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/checkServiceFeatureAvailibility/{featureName}
# Returns: record<value: bool>
# operationId: services_getFeatureAvailibility
export def "services-get-feature-availibility" [
  service_name: string
  feature_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/checkServiceFeatureAvailibility/{featureName}"
    path_params: [{name: serviceName, var: service_name}, {name: featureName, var: feature_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, feature_name: $feature_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the count of latest AAD export errors.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/exporterrors/counts
# Returns: record<value: table<count: int, errorBucket: string, truncated: bool>>
# operationId: services_listExportErrors
export def "services-list-export-errors" [
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
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/exporterrors/counts"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the categorized export errors.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/exporterrors/listV2
# Returns: record<value: table<attributeName: string, attributeValue: string, createdDate: string, csObjectId: string, dn: string, existingObject: record, exportErrorStatus: int, id: string, incomingObject: record, incomingObjectDisplayName: string, incomingObjectType: string, mergedEntityId: string, modifiedOrRemovedAttributeValue: string, runStepResultId: string, samAccountName: string, serverErrorDetail: string, serviceId: string, serviceMemberId: string, timeFirstOccurred: string, timeOccurred: string, type: string, userPrincipalName: string>>
# operationId: services_listExportErrorsV2
export def "services-list-export-errors-v2" [
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
  --error-bucket: string # The error category to query for. (required)
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/exporterrors/listV2"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: errorBucket, var: error_bucket, required: true}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, error_bucket: $error_bucket, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the export status.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/exportstatus
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<endTime: string, runStepResultId: string, serviceId: string, serviceMemberId: string>>
# operationId: services_listExportStatus
export def "services-list-export-status" [
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
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/exportstatus"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds an alert feedback submitted by customer.
#
# POST /providers/Microsoft.ADHybridHealthService/services/{serviceName}/feedbacktype/alerts/feedback
# Returns: record<comment: string, consentedToShare: bool, createdDate: string, feedback: string, level: string, serviceMemberId: string, shortName: string, state: string>
# operationId: services_addAlertFeedback
export def "services-add-alert-feedback" [
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
  --api-version: string # The version of the API to be used with the client request. (required)
  --comment: string # Additional comments related to the alert.
  --consented-to-share: oneof<nothing, bool> # Indicates if the alert feedback can be shared from product team.
  --created-date: string # The date and time,in UTC,when the alert was created. (format: date-time)
  --feedback: string # The feedback for the alert which indicates if the customer likes or dislikes the alert.
  --level: string # The alert level which indicates the severity of the alert.
  --service-member-id: string # The server Id of the alert.
  --short-name: string # The alert short name.
  --state: string # The alert state which can be either active or resolved with multiple resolution types.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/feedbacktype/alerts/feedback"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: consentedToShare, var: consented_to_share}, {name: createdDate, var: created_date}, {name: feedback, var: feedback}, {name: level, var: level}, {name: serviceMemberId, var: service_member_id}, {name: shortName, var: short_name}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, api_version: $api_version, comment: $comment, consented_to_share: $consented_to_share, created_date: $created_date, feedback: $feedback, level: $level, service_member_id: $service_member_id, short_name: $short_name, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of all alert feedback for a given tenant and alert type.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/feedbacktype/alerts/{shortName}/alertfeedback
# Returns: record<value: table<comment: string, consentedToShare: bool, createdDate: string, feedback: string, level: string, serviceMemberId: string, shortName: string, state: string>>
# operationId: services_listAlertFeedback
export def "services-list-alert-feedback" [
  service_name: string
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/feedbacktype/alerts/{shortName}/alertfeedback"
    path_params: [{name: serviceName, var: service_name}, {name: shortName, var: short_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, short_name: $short_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the service related metrics information.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/metricmetadata
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<displayName: string, groupings: list, isDefault: bool, isDevOps: bool, isPerfCounter: bool, kind: string, maxValue: int, metricName: string, metricsProcessorClassName: string, minValue: int, valueKind: string>>
# operationId: services_listMetricMetadata
export def "services-list-metric-metadata" [
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
  --filter: string # The metric metadata property filter to apply.
  --perf-counter: oneof<nothing, bool> # Indicates if only performance counter metrics are requested.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/metricmetadata"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: "$filter", var: filter}, {name: perfCounter, var: perf_counter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, filter: $filter, perf_counter: $perf_counter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the service related metrics information.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/metricmetadata/{metricName}
# Returns: record<displayName: string, groupings: table<displayName: string, invisibleForUi: bool, key: string>, isDefault: bool, isDevOps: bool, isPerfCounter: bool, kind: string, maxValue: int, metricName: string, metricsProcessorClassName: string, minValue: int, valueKind: string>
# operationId: services_getMetricMetadata
export def "services-get-metric-metadata" [
  service_name: string
  metric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/metricmetadata/{metricName}"
    path_params: [{name: serviceName, var: service_name}, {name: metricName, var: metric_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, metric_name: $metric_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the service related metrics for a given metric and group combination.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/metricmetadata/{metricName}/groups/{groupName}
# Returns: record<sets: table<setName: string, values: list>, timeStamps: list<string>>
# operationId: services_getMetricMetadataForGroup
export def "services-get-metric-metadata-for-group" [
  service_name: string
  metric_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-key: string # The group key
  --from-date: string # The start date. (format: date-time)
  --to-date: string # The end date. (format: date-time)
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/metricmetadata/{metricName}/groups/{groupName}"
    path_params: [{name: serviceName, var: service_name}, {name: metricName, var: metric_name}, {name: groupName, var: group_name}]
    query: [{name: groupKey, var: group_key}, {name: fromDate, var: from_date}, {name: toDate, var: to_date}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, metric_name: $metric_name, group_name: $group_name, group_key: $group_key, from_date: $from_date, to_date: $to_date, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the server related metrics for a given metric and group combination.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/metrics/{metricName}/groups/{groupName}
# Returns: record<sets: table<setName: string, values: list>, timeStamps: list<string>>
# operationId: service_getMetrics
export def "service-get-metrics" [
  service_name: string
  metric_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-key: string # The group key
  --from-date: string # The start date. (format: date-time)
  --to-date: string # The end date. (format: date-time)
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/metrics/{metricName}/groups/{groupName}"
    path_params: [{name: serviceName, var: service_name}, {name: metricName, var: metric_name}, {name: groupName, var: group_name}]
    query: [{name: groupKey, var: group_key}, {name: fromDate, var: from_date}, {name: toDate, var: to_date}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, metric_name: $metric_name, group_name: $group_name, group_key: $group_key, from_date: $from_date, to_date: $to_date, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the average of the metric values for a given metric and group combination.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/metrics/{metricName}/groups/{groupName}/average
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<key: string, value: string>>
# operationId: services_listMetricsAverage
export def "services-list-metrics-average" [
  service_name: string
  metric_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/metrics/{metricName}/groups/{groupName}/average"
    path_params: [{name: serviceName, var: service_name}, {name: metricName, var: metric_name}, {name: groupName, var: group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, metric_name: $metric_name, group_name: $group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the sum of the metric values for a given metric and group combination.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/metrics/{metricName}/groups/{groupName}/sum
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<key: string, value: string>>
# operationId: services_listMetricsSum
export def "services-list-metrics-sum" [
  service_name: string
  metric_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/metrics/{metricName}/groups/{groupName}/sum"
    path_params: [{name: serviceName, var: service_name}, {name: metricName, var: metric_name}, {name: groupName, var: group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, metric_name: $metric_name, group_name: $group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the service level monitoring configuration.
#
# PATCH /providers/Microsoft.ADHybridHealthService/services/{serviceName}/monitoringconfiguration
# operationId: services_updateMonitoringConfiguration
export def "services-update-monitoring-configuration" [
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
  --api-version: string # The version of the API to be used with the client request. (required)
  --key: string # The key for the property.
  --value: string # The value for the key.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/monitoringconfiguration"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, api_version: $api_version, key: $key, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the service level monitoring configurations.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/monitoringconfigurations
# Returns: record<value: table<key: string, value: string>>
# operationId: services_listMonitoringConfigurations
export def "services-list-monitoring-configurations" [
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
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/monitoringconfigurations"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the bad password login attempt report for an user
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/reports/badpassword/details/user
# Returns: record<value: table<ipAddress: string, lastUpdated: string, totalErrorAttempts: int, uniqueIpAddresses: string, userId: string>>
# operationId: services_listUserBadPasswordReport
export def "services-list-user-bad-password-report" [
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
  --data-source: string # The source of data, if its test data or customer data.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/reports/badpassword/details/user"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: dataSource, var: data_source}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, data_source: $data_source, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all Risky IP report URIs for the last 7 days.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/reports/riskyIp/blobUris
# Returns: record<value: table<blobCreateDateTime: string, jobCompletionTime: string, resultSasUri: string, serviceId: string, status: string, tenantId: string>>
# operationId: services_listAllRiskyIpDownloadReport
export def "services-list-all-risky-ip-download-report" [
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
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/reports/riskyIp/blobUris"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiate the generation of a new Risky IP report. Returns the URI for the new one.
#
# POST /providers/Microsoft.ADHybridHealthService/services/{serviceName}/reports/riskyIp/generateBlobUri
# Returns: record<value: table<blobCreateDateTime: string, jobCompletionTime: string, resultSasUri: string, serviceId: string, status: string, tenantId: string>>
# operationId: services_listCurrentRiskyIpDownloadReport
export def "services-list-current-risky-ip-download-report" [
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
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/reports/riskyIp/generateBlobUri"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of the servers, for a given service, that are onboarded to Azure Active Directory Connect Health Service.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlerts: int, additionalInformation: string, createdDate: string, dimensions: record, disabled: bool, disabledReason: int, installedQfes: record, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, osName: string, osVersion: string, properties: record, recommendedQfes: record, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, status: string, tenantId: string>>
# operationId: serviceMembers_list
export def "service-members-list" [
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
  --filter: string # The server property filter to apply.
  --dimension-type: string # The server specific dimension.
  --dimension-signature: string # The value of the dimension.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: "$filter", var: filter}, {name: dimensionType, var: dimension_type}, {name: dimensionSignature, var: dimension_signature}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, filter: $filter, dimension_type: $dimension_type, dimension_signature: $dimension_signature, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Onboards a server, for a given service, to Azure Active Directory Connect Health Service.
#
# POST /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers
# Returns: record<activeAlerts: int, additionalInformation: string, createdDate: string, dimensions: record, disabled: bool, disabledReason: int, installedQfes: record, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, osName: string, osVersion: string, properties: record, recommendedQfes: record, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, status: string, tenantId: string>
# operationId: serviceMembers_add
export def "service-members-add" [
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
  --api-version: string # The version of the API to be used with the client request. (required)
  --active-alerts: int # The total number of alerts that are currently active for the server.
  --additional-information: string # The additional information, if any, for the server.
  --created-date: string # The date time , in UTC, when the server was onboarded to Azure Active Directory Connect Health. (format: date-time)
  --dimensions: record # The server specific configuration related dimensions.
  --disabled: oneof<nothing, bool> # Indicates if the server is disabled or not.
  --disabled-reason: int # The reason for disabling the server.
  --installed-qfes: record # The list of installed QFEs for the server.
  --last-disabled: string # The date and time , in UTC, when the server was last disabled. (format: date-time)
  --last-reboot: string # The date and time, in UTC, when the server was last rebooted. (format: date-time)
  --last-server-reported-monitoring-level-change: string # The date and time, in UTC, when the server's data monitoring configuration was last changed. (format: date-time)
  --last-updated: string # The date and time, in UTC, when the server properties were last updated. (format: date-time)
  --machine-id: string # The id of the machine.
  --machine-name: string # The name of the server.
  --monitoring-configurations-computed: record # The monitoring configuration of the server which determines what activities are monitored by Azure Active Directory Connect Health.
  --monitoring-configurations-customized: record # The customized monitoring configuration of the server which determines what activities are monitored by Azure Active Directory Connect Health.
  --os-name: string # The name of the operating system installed in the machine.
  --os-version: string # The version of the operating system installed in the machine.
  --properties: record # Server specific properties.
  --recommended-qfes: record # The list of recommended hotfixes for the server.
  --resolved-alerts: int # The total count of alerts that are resolved for this server.
  --role: string # The service role that is being monitored in the server.
  --server-reported-monitoring-level: string@server-reported-monitoring-level-completer # The monitoring level reported by the server.
  --service-id: string # The service id to whom this server belongs.
  --service-member-id: string # The id of the server.
  --status: string # The health status of the server.
  --tenant-id: string # The tenant id to whom this server belongs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers"
    path_params: [{name: serviceName, var: service_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: activeAlerts, var: active_alerts}, {name: additionalInformation, var: additional_information}, {name: createdDate, var: created_date}, {name: dimensions, var: dimensions}, {name: disabled, var: disabled}, {name: disabledReason, var: disabled_reason}, {name: installedQfes, var: installed_qfes}, {name: lastDisabled, var: last_disabled}, {name: lastReboot, var: last_reboot}, {name: lastServerReportedMonitoringLevelChange, var: last_server_reported_monitoring_level_change}, {name: lastUpdated, var: last_updated}, {name: machineId, var: machine_id}, {name: machineName, var: machine_name}, {name: monitoringConfigurationsComputed, var: monitoring_configurations_computed}, {name: monitoringConfigurationsCustomized, var: monitoring_configurations_customized}, {name: osName, var: os_name}, {name: osVersion, var: os_version}, {name: properties, var: properties}, {name: recommendedQfes, var: recommended_qfes}, {name: resolvedAlerts, var: resolved_alerts}, {name: role, var: role}, {name: serverReportedMonitoringLevel, var: server_reported_monitoring_level}, {name: serviceId, var: service_id}, {name: serviceMemberId, var: service_member_id}, {name: status, var: status}, {name: tenantId, var: tenant_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, api_version: $api_version, active_alerts: $active_alerts, additional_information: $additional_information, created_date: $created_date, dimensions: $dimensions, disabled: $disabled, disabled_reason: $disabled_reason, installed_qfes: $installed_qfes, last_disabled: $last_disabled, last_reboot: $last_reboot, last_server_reported_monitoring_level_change: $last_server_reported_monitoring_level_change, last_updated: $last_updated, machine_id: $machine_id, machine_name: $machine_name, monitoring_configurations_computed: $monitoring_configurations_computed, monitoring_configurations_customized: $monitoring_configurations_customized, os_name: $os_name, os_version: $os_version, properties: $properties, recommended_qfes: $recommended_qfes, resolved_alerts: $resolved_alerts, role: $role, server_reported_monitoring_level: $server_reported_monitoring_level, service_id: $service_id, service_member_id: $service_member_id, status: $status, tenant_id: $tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a server that has been onboarded to Azure Active Directory Connect Health Service.
#
# DELETE /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}
# operationId: serviceMembers_delete
export def "service-members-delete" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --confirm: oneof<nothing, bool> # Indicates if the server will be permanently deleted or disabled. True indicates that the server will be permanently deleted and False indicates that the server will be marked disabled and then deleted after 30 days, if it is not re-registered.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}"
    path_params: [{name: serviceName, var: service_name}, {name: serviceMemberId, var: service_member_id}]
    query: [{name: confirm, var: confirm}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, service_member_id: $service_member_id, confirm: $confirm, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of a server, for a given service, that are onboarded to Azure Active Directory Connect Health Service.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}
# Returns: record<activeAlerts: int, additionalInformation: string, createdDate: string, dimensions: record, disabled: bool, disabledReason: int, installedQfes: record, lastDisabled: string, lastReboot: string, lastServerReportedMonitoringLevelChange: string, lastUpdated: string, machineId: string, machineName: string, monitoringConfigurationsComputed: record, monitoringConfigurationsCustomized: record, osName: string, osVersion: string, properties: record, recommendedQfes: record, resolvedAlerts: int, role: string, serverReportedMonitoringLevel: string, serviceId: string, serviceMemberId: string, status: string, tenantId: string>
# operationId: serviceMembers_get
export def "service-members-get" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}"
    path_params: [{name: serviceName, var: service_name}, {name: serviceMemberId, var: service_member_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, service_member_id: $service_member_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details of an alert for a given service and server combination.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/alerts
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<activeAlertProperties: list, additionalInformation: list, alertId: string, createdDate: string, description: string, displayName: string, lastUpdated: string, level: string, monitorRoleType: string, relatedLinks: list, remediation: string, resolvedAlertProperties: list, resolvedDate: string, scope: string, serviceId: string, serviceMemberId: string, shortName: string, state: string, tenantId: string>>
# operationId: serviceMembers_listAlerts
export def "service-members-list-alerts" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The alert property filter to apply.
  --state: string # The alert state to query for.
  --from: string # The start date to query for. (format: date-time)
  --to: string # The end date till when to query for. (format: date-time)
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/alerts"
    path_params: [{name: serviceName, var: service_name}, {name: serviceMemberId, var: service_member_id}]
    query: [{name: "$filter", var: filter}, {name: state, var: state}, {name: from, var: from}, {name: to, var: to}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, service_member_id: $service_member_id, filter: $filter, state: $state, from: $from, to: $to, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the credentials of the server which is needed by the agent to connect to Azure Active Directory Connect Health Service.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/credentials
# Returns: record<value: table<credentialData: list, identifier: string, type: string>>
# operationId: serviceMembers_listCredentials
export def "service-members-list-credentials" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The property filter to apply.
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/credentials"
    path_params: [{name: serviceName, var: service_name}, {name: serviceMemberId, var: service_member_id}]
    query: [{name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, service_member_id: $service_member_id, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the data uploaded by the server to Azure Active Directory Connect Health Service.
#
# DELETE /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/data
# operationId: serviceMembers_deleteData
export def "service-members-delete-data" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/data"
    path_params: [{name: serviceName, var: service_name}, {name: serviceMemberId, var: service_member_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, service_member_id: $service_member_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the last time when the server uploaded data to Azure Active Directory Connect Health Service.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/datafreshness
# Returns: record<value: table<key: string, value: string>>
# operationId: serviceMembers_listDataFreshness
export def "service-members-list-data-freshness" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/datafreshness"
    path_params: [{name: serviceName, var: service_name}, {name: serviceMemberId, var: service_member_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, service_member_id: $service_member_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the export status.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/exportstatus
# Returns: record<continuationToken: string, nextLink: string, totalCount: int, value: table<endTime: string, runStepResultId: string, serviceId: string, serviceMemberId: string>>
# operationId: serviceMembers_listExportStatus
export def "service-members-list-export-status" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/exportstatus"
    path_params: [{name: serviceName, var: service_name}, {name: serviceMemberId, var: service_member_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, service_member_id: $service_member_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the global configuration.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/globalconfiguration
# Returns: record<value: table<featureSet: list, numSavedPwdEvent: int, passwordSyncEnabled: bool, schemaXml: string, version: int>>
# operationId: serviceMembers_listGlobalConfiguration
export def "service-members-list-global-configuration" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/globalconfiguration"
    path_params: [{name: serviceName, var: service_name}, {name: serviceMemberId, var: service_member_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, service_member_id: $service_member_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the list of connectors and run profile names.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/metrics/{metricName}
# Returns: record<connectors: table<connectorDisplayName: string, connectorId: string>, runProfileNames: list<string>>
# operationId: serviceMembers_getConnectorMetadata
export def "service-members-get-connector-metadata" [
  service_name: string
  service_member_id: string
  metric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/metrics/{metricName}"
    path_params: [{name: serviceName, var: service_name}, {name: serviceMemberId, var: service_member_id}, {name: metricName, var: metric_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, service_member_id: $service_member_id, metric_name: $metric_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the server related metrics for a given metric and group combination.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/metrics/{metricName}/groups/{groupName}
# Returns: record<sets: table<setName: string, values: list>, timeStamps: list<string>>
# operationId: serviceMembers_getMetrics
export def "service-members-get-metrics" [
  service_name: string
  service_member_id: string
  metric_name: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-key: string # The group key
  --from-date: string # The start date. (format: date-time)
  --to-date: string # The end date. (format: date-time)
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/metrics/{metricName}/groups/{groupName}"
    path_params: [{name: serviceName, var: service_name}, {name: serviceMemberId, var: service_member_id}, {name: metricName, var: metric_name}, {name: groupName, var: group_name}]
    query: [{name: groupKey, var: group_key}, {name: fromDate, var: from_date}, {name: toDate, var: to_date}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, service_member_id: $service_member_id, metric_name: $metric_name, group_name: $group_name, group_key: $group_key, from_date: $from_date, to_date: $to_date, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the service configuration.
#
# GET /providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/serviceconfiguration
# Returns: record<serviceAccount: string, serviceType: int, sqlDatabaseName: string, sqlDatabaseSize: int, sqlEdition: string, sqlInstance: string, sqlServer: string, sqlVersion: string, version: string>
# operationId: serviceMembers_getServiceConfiguration
export def "service-members-get-service-configuration" [
  service_name: string
  service_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the API to be used with the client request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.ADHybridHealthService/services/{serviceName}/servicemembers/{serviceMemberId}/serviceconfiguration"
    path_params: [{name: serviceName, var: service_name}, {name: serviceMemberId, var: service_member_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_name: $service_name, service_member_id: $service_member_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
